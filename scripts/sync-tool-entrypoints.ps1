# sync-tool-entrypoints.ps1
#
# 作用：以项目根的 AGENTS.md 为唯一真源，为各 AI 工具生成「薄入口文件」，全部指回 AGENTS.md。
#       配合 multi-tool-entrypoint-sync Skill 使用。
#
# 用法：
#   .\sync-tool-entrypoints.ps1 -ProjectRoot "D:\WorkCode\YourProject" -Tools claude,cursor,copilot,gemini
#   -Tools 省略则生成全部支持的工具入口。可选值：claude cursor copilot gemini windsurf cline
#
# 安全保证：生成的文件带 AITEAMOPS-GENERATED 标记；若同名文件已存在但无该标记
#           （说明是用户手写的），一律跳过并提示，绝不覆盖。

param(
    [string]$ProjectRoot = ".",
    [string[]]$Tools
)

$ErrorActionPreference = "Stop"

$MARKER = "AITEAMOPS-GENERATED"

$Root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$Agents = Join-Path $Root "AGENTS.md"
if (-not (Test-Path -LiteralPath $Agents)) {
    Write-Error "未找到 $Agents。请先用 team-ai-workspace-bootstrap 建好 AGENTS.md 真源。"
    exit 1
}

# 通用指针正文
$generic = @"
<!-- $MARKER 由 sync-tool-entrypoints.ps1 生成，请勿手改本文件。 -->
# 本项目 AI 协作规则入口

本项目所有 AI 协作规则、目录路由与红线，以根目录 ``AGENTS.md`` 为唯一真源。
开始前请先完整阅读 ``./AGENTS.md``，并遵循其中指向的 ``.agents/skills/`` 下的 Skill。
若本文件与 ``AGENTS.md`` 不一致，以 ``AGENTS.md`` 为准。
"@

# Claude Code：用 @import 直接导入真源
$claude = @"
<!-- $MARKER 请勿手改。 -->
本项目规则以 AGENTS.md 为唯一真源：

@AGENTS.md
"@

# Cursor：.mdc 规则，alwaysApply
$cursor = @"
---
description: AITeamOps 项目规则入口
alwaysApply: true
---

<!-- $MARKER 请勿手改。 -->
本项目规则以根目录 ``AGENTS.md`` 为唯一真源，请先完整阅读 ``./AGENTS.md`` 再开始，
并遵循其中指向的 ``.agents/skills/`` 下的 Skill。
"@

# 工具 -> (相对路径, 内容)
$map = @{
    claude   = @{ path = "CLAUDE.md";                          body = $claude }
    cursor   = @{ path = ".cursor/rules/aiteamops.mdc";        body = $cursor }
    copilot  = @{ path = ".github/copilot-instructions.md";    body = $generic }
    gemini   = @{ path = "GEMINI.md";                          body = $generic }
    windsurf = @{ path = ".windsurfrules";                     body = $generic }
    cline    = @{ path = ".clinerules";                        body = $generic }
}

if (-not $Tools -or $Tools.Count -eq 0) { $Tools = $map.Keys }

$utf8Bom = New-Object System.Text.UTF8Encoding($true)

foreach ($t in $Tools) {
    $key = $t.ToLower()
    if (-not $map.ContainsKey($key)) {
        Write-Host "  ! 未知工具 '$t'，跳过（支持：$($map.Keys -join ', ')）" -ForegroundColor Yellow
        continue
    }
    $rel  = $map[$key].path
    $body = $map[$key].body
    $dest = Join-Path $Root $rel

    # 不覆盖用户手写文件：存在且无生成标记 -> 跳过
    if (Test-Path -LiteralPath $dest) {
        $existing = Get-Content -LiteralPath $dest -Raw -ErrorAction SilentlyContinue
        if ($existing -notmatch $MARKER) {
            Write-Host "  ! 已存在且非本工具生成：$rel —— 跳过，未覆盖（如需替换请先手动删除）" -ForegroundColor Yellow
            continue
        }
    }

    $dir = Split-Path -Parent $dest
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [System.IO.File]::WriteAllText($dest, $body, $utf8Bom)
    Write-Host "  + 已生成 $rel"
}

Write-Host "多工具入口同步完成（真源：AGENTS.md）。" -ForegroundColor Green
