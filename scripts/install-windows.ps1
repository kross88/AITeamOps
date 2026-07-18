# AITeamOps Windows 用户级 Skills 安装脚本
#
# 作用：
#   在用户级目录安装本仓库的团队 Skills（复制到 ~\.agents\skills）。
#
# 用法：
#   .\install-windows.ps1
#
# 项目初始化必须由 AI 使用 team-ai-workspace-bootstrap 分析项目后完成，
# 本脚本不再创建空 AGENTS.md、空 docs 或空目录。

param(
    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

# 向后兼容旧调用方式，但必须在任何写入前明确失败，避免用户误以为项目已初始化。
if ($PSBoundParameters.ContainsKey("ProjectRoot")) {
    Write-Error "-ProjectRoot 已弃用，本脚本只安装用户级 Skills，未执行任何写入。请先不带参数运行本脚本，再让 AI 使用 team-ai-workspace-bootstrap 分析并初始化项目：$ProjectRoot"
    exit 2
}

# 仓库根目录：脚本位于 <repo>\scripts\ 下，向上一级即仓库根
$RepoRoot = Split-Path -Parent $PSScriptRoot

# 安全创建目录：已存在则跳过
function New-DirIfMissing($path) {
    if (Test-Path -LiteralPath $path) {
        Write-Host "  = 已存在 $path（跳过）"
    } else {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        Write-Host "  + 目录 $path"
    }
}

Write-Host "== 安装 AITeamOps Skills 到用户级目录 =="
New-DirIfMissing "$env:USERPROFILE\.agents\skills"

$SkillsSrc = Join-Path $RepoRoot ".agents\skills"
if (Test-Path -LiteralPath $SkillsSrc) {
    # AITeamOps 同名 Skills 由本框架托管，更新时覆盖；用户自定义 Skill 请使用不同名称。
    Copy-Item -Path (Join-Path $SkillsSrc "*") `
              -Destination "$env:USERPROFILE\.agents\skills\" -Recurse -Force
    Write-Host "  已复制 Skills：$SkillsSrc -> $env:USERPROFILE\.agents\skills\"
} else {
    Write-Host "  ! 未找到 $SkillsSrc，跳过 Skills 安装（请确认从仓库目录运行本脚本）" -ForegroundColor Yellow
}

Write-Host "AITeamOps 用户级 Skills 安装完成。项目接入请使用 team-ai-workspace-bootstrap。" -ForegroundColor Green
