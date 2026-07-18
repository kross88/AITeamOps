# sync-tool-entrypoints.ps1
#
# 作用：以项目根 AGENTS.md 为项目级规则真源，只为明确指定的 AI 工具生成薄入口。
#
# 用法：
#   .\sync-tool-entrypoints.ps1 -ProjectRoot "D:\WorkCode\YourProject" -Tools claude,cursor
#   -Tools 必填。可选值：claude cursor copilot gemini windsurf cline
#
# 安全保证：
#   1. 所有工具名、目标路径与手写冲突先整批预检，任一失败时零写入。
#   2. 运行时写入失败会恢复本轮覆盖的原内容，并删除本轮新建文件与空目录。
#   3. 不自动删除以前生成但本次未选择的入口。

param(
    [string]$ProjectRoot = ".",
    [string[]]$Tools
)

$ErrorActionPreference = "Stop"

$MARKER = "AITEAMOPS-GENERATED"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Stop-WithError([string]$message, [int]$code = 1) {
    Write-Error $message
    exit $code
}

function Test-ManagedEntry([string]$tool, [string]$content) {
    $normalized = ($content -replace "`r`n", "`n").Trim()
    if ($tool -eq "claude") {
        return $normalized -eq "@AGENTS.md" -or $content.Contains($MARKER)
    }
    return $content.Contains($MARKER)
}

function Get-MissingDirectories([string]$directory) {
    $missing = New-Object System.Collections.Generic.List[string]
    $current = $directory
    while ($current -and -not (Test-Path -LiteralPath $current)) {
        $missing.Add($current)
        $current = Split-Path -Parent $current
    }
    if ($current -and -not (Test-Path -LiteralPath $current -PathType Container)) {
        throw "父路径不是目录：$current"
    }
    return @($missing)
}

$Root = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Stop-WithError "项目根不是目录：$Root"
}

$Agents = Join-Path $Root "AGENTS.md"
if (-not (Test-Path -LiteralPath $Agents -PathType Leaf)) {
    Stop-WithError "未找到 $Agents。请先用 team-ai-workspace-bootstrap 建好 AGENTS.md 真源。"
}

# 兼容 -Tools claude,cursor 与 -Tools @('claude','cursor') 两种写法。
$requested = New-Object System.Collections.Generic.List[string]
if ($Tools) {
    foreach ($item in $Tools) {
        foreach ($part in ($item -split ",")) {
            $key = $part.Trim().ToLowerInvariant()
            if ($key) { $requested.Add($key) }
        }
    }
}
if ($requested.Count -eq 0) {
    Stop-WithError "-Tools 必填且不能为空。请明确指定实际使用的工具，例如：-Tools claude,cursor"
}

$generic = @"
<!-- $MARKER 由 sync-tool-entrypoints.ps1 生成，请勿手改本文件。 -->
# 本项目 AI 协作规则入口

本项目所有 AI 协作规则、目录路由与红线，以根目录 ``AGENTS.md`` 为项目级唯一真源。
开始前请先完整阅读 ``./AGENTS.md``，并按需使用用户级 ``~/.agents/skills/``；项目存在 ``.agents/skills/`` 时优先使用项目固定版本。
若本文件与 ``AGENTS.md`` 不一致，以 ``AGENTS.md`` 为准。
"@

$claude = "@AGENTS.md`n"

$cursor = @"
---
description: AITeamOps 项目规则入口
alwaysApply: true
---

<!-- $MARKER 请勿手改。 -->
本项目规则以根目录 ``AGENTS.md`` 为项目级唯一真源，请先完整阅读 ``./AGENTS.md`` 再开始，
并按需使用用户级 ``~/.agents/skills/``；项目存在 ``.agents/skills/`` 时优先使用项目固定版本。
"@

$map = @{
    claude   = @{ path = "CLAUDE.md";                       body = $claude }
    cursor   = @{ path = ".cursor/rules/aiteamops.mdc";     body = $cursor }
    copilot  = @{ path = ".github/copilot-instructions.md"; body = $generic }
    gemini   = @{ path = "GEMINI.md";                       body = $generic }
    windsurf = @{ path = ".windsurfrules";                  body = $generic }
    cline    = @{ path = ".clinerules";                     body = $generic }
}

# 去重并在任何写入前一次性验证全部工具名。
$unique = New-Object System.Collections.Generic.List[string]
$seen = @{}
foreach ($key in $requested) {
    if (-not $map.ContainsKey($key)) {
        Stop-WithError "未知工具 '$key'。支持：$($map.Keys -join ', ')。本次未写入任何文件。"
    }
    if (-not $seen.ContainsKey($key)) {
        $seen[$key] = $true
        $unique.Add($key)
    }
}

# 整批预检：目标类型、手写冲突、父目录可创建性。
$planned = New-Object System.Collections.Generic.List[object]
foreach ($key in $unique) {
    $rel = $map[$key].path
    $dest = Join-Path $Root $rel
    if (Test-Path -LiteralPath $dest) {
        if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) {
            Stop-WithError "目标路径不是文件：$rel。本次未写入任何文件。"
        }
        $existing = Get-Content -LiteralPath $dest -Raw -ErrorAction Stop
        if (-not (Test-ManagedEntry $key $existing)) {
            Stop-WithError "已存在手写入口：$rel。为避免覆盖，本次整批停止且未写入任何文件。"
        }
    }

    $parent = Split-Path -Parent $dest
    try {
        $missingDirs = @(Get-MissingDirectories $parent)
    } catch {
        Stop-WithError "$($_.Exception.Message)。本次未写入任何文件。"
    }

    $planned.Add([PSCustomObject]@{
        tool = $key
        rel = $rel
        dest = $dest
        body = $map[$key].body
        missingDirs = $missingDirs
    })
}

$attempted = New-Object System.Collections.Generic.List[object]
$createdDirs = New-Object System.Collections.Generic.List[string]
try {
    foreach ($item in $planned) {
        # 从最上层到最下层创建缺失目录，并记录供失败回滚。
        for ($i = $item.missingDirs.Count - 1; $i -ge 0; $i--) {
            $dir = $item.missingDirs[$i]
            if (-not (Test-Path -LiteralPath $dir)) {
                New-Item -ItemType Directory -Path $dir | Out-Null
                $createdDirs.Add($dir)
            }
        }

        $existed = Test-Path -LiteralPath $item.dest -PathType Leaf
        $bytes = $null
        if ($existed) { $bytes = [System.IO.File]::ReadAllBytes($item.dest) }
        $attempted.Add([PSCustomObject]@{ dest = $item.dest; existed = $existed; bytes = $bytes })
        [System.IO.File]::WriteAllText($item.dest, $item.body, $utf8NoBom)
    }
} catch {
    for ($i = $attempted.Count - 1; $i -ge 0; $i--) {
        $old = $attempted[$i]
        if ($old.existed) {
            [System.IO.File]::WriteAllBytes($old.dest, $old.bytes)
        } elseif (Test-Path -LiteralPath $old.dest) {
            Remove-Item -LiteralPath $old.dest -Force
        }
    }
    for ($i = $createdDirs.Count - 1; $i -ge 0; $i--) {
        $dir = $createdDirs[$i]
        if ((Test-Path -LiteralPath $dir -PathType Container) -and -not (Get-ChildItem -LiteralPath $dir -Force)) {
            Remove-Item -LiteralPath $dir -Force
        }
    }
    Stop-WithError "入口同步失败，已回滚本轮写入：$($_.Exception.Message)"
}

foreach ($item in $planned) {
    Write-Host "  + 已生成 $($item.rel)"
}
Write-Host "多工具入口同步完成（项目级真源：AGENTS.md）。" -ForegroundColor Green
