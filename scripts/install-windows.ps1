# team-ai-workspace-bootstrap Windows 初始化脚本
$PROJECT_ROOT = "D:\WorkCode\YourProject"

New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills\team-ai-workspace-bootstrap"

New-Item -ItemType File -Force "$PROJECT_ROOT\AGENTS.md"
New-Item -ItemType File -Force "$PROJECT_ROOT\service\AGENTS.md"
New-Item -ItemType File -Force "$PROJECT_ROOT\backweb\AGENTS.md"

New-Item -ItemType Directory -Force "$PROJECT_ROOT\.agents\skills"
New-Item -ItemType Directory -Force "$PROJECT_ROOT\docs\ai-memory\modules"
New-Item -ItemType File -Force "$PROJECT_ROOT\docs\AI开发交接记录.md"
New-Item -ItemType File -Force "$PROJECT_ROOT\docs\模块验收清单.md"

Write-Host "AI 协作目录初始化完成。" -ForegroundColor Green
