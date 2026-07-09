# team-ai-workspace-bootstrap Windows 初始化脚本
#
# 作用：
#   1. 在用户级目录安装本仓库的团队 Skills（复制到 ~\.agents\skills）。
#   2. 为指定项目初始化「AGENTS.md + Skills + docs」协作骨架。
#
# 用法：
#   .\install-windows.ps1 -ProjectRoot "D:\WorkCode\YourProject"
#   不传 -ProjectRoot 时会交互式询问；留空则只安装用户级 Skills，跳过项目初始化。
#
# 安全保证：已存在的目录/文件一律跳过，绝不覆盖或清空已有内容（可反复运行）。

param(
    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

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

# 安全创建空文件：已存在则跳过，绝不覆盖已有内容
function New-FileIfMissing($path) {
    if (Test-Path -LiteralPath $path) {
        Write-Host "  = 已存在 $path（跳过，未改动）"
    } else {
        New-Item -ItemType File -Force -Path $path | Out-Null   # -Force 仅用于自动创建父目录
        Write-Host "  + 文件 $path"
    }
}

# === 1. 安装用户级 Skills ===
Write-Host "== 1/2 安装团队 Skills 到用户级目录 =="
New-DirIfMissing "$env:USERPROFILE\.codex"
New-DirIfMissing "$env:USERPROFILE\.claude"
New-DirIfMissing "$env:USERPROFILE\.agents\skills"

$SkillsSrc = Join-Path $RepoRoot ".agents\skills"
if (Test-Path -LiteralPath $SkillsSrc) {
    Copy-Item -Path (Join-Path $SkillsSrc "*") `
              -Destination "$env:USERPROFILE\.agents\skills\" -Recurse -Force
    Write-Host "  已复制 Skills：$SkillsSrc -> $env:USERPROFILE\.agents\skills\"
} else {
    Write-Host "  ! 未找到 $SkillsSrc，跳过 Skills 安装（请确认从仓库目录运行本脚本）" -ForegroundColor Yellow
}

# === 2. 初始化项目协作骨架 ===
if (-not $ProjectRoot) {
    $ProjectRoot = Read-Host "请输入要初始化的项目根目录（直接回车则跳过项目初始化）"
}

if (-not $ProjectRoot) {
    Write-Host "未指定项目根目录，跳过项目初始化。"
} else {
    Write-Host "== 2/2 初始化项目协作骨架：$ProjectRoot =="

    # 目录路由级 AGENTS.md（service/backweb 为示例命名，按实际项目调整）
    New-FileIfMissing "$ProjectRoot\AGENTS.md"
    New-FileIfMissing "$ProjectRoot\service\AGENTS.md"
    New-FileIfMissing "$ProjectRoot\backweb\AGENTS.md"

    # 项目共享 Skills 目录
    New-DirIfMissing "$ProjectRoot\.agents\skills"

    # docs：业务事实 + 项目记忆（与 ai-handoff-doc-update 的路由表保持一致）
    New-DirIfMissing "$ProjectRoot\docs\ai-memory\modules"
    New-DirIfMissing "$ProjectRoot\docs\requirements"
    New-FileIfMissing "$ProjectRoot\docs\系统业务流程.html"
    New-FileIfMissing "$ProjectRoot\docs\模块验收清单.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\overview.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\task-log.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\interface-map.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\database-map.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\db-write-log.md"
    New-FileIfMissing "$ProjectRoot\docs\ai-memory\risk-points.md"
}

Write-Host "AI 协作目录初始化完成。" -ForegroundColor Green
