#!/usr/bin/env bash
# validate.sh —— 校验 Skills 结构与文档一致性（本地与 CI 通用）。
# 检查项：
#   1) 每个 .agents/skills/*/SKILL.md 含 frontmatter，且有 name: 与 description:
#   2) frontmatter 的 name 与所在文件夹同名（kebab-case 约定）
#   3) 每个 Skill 在 README.md「包含的 Skills」表格里被引用
# 任一不过即以非 0 退出。
set -uo pipefail

# 切到仓库根（脚本位于 <repo>/scripts/ 下）
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
err() { echo "  ✗ $1"; fail=1; }
ok()  { echo "  ✓ $1"; }

echo "== 校验 Skills =="
shopt -s nullglob
found=0
for skill in .agents/skills/*/SKILL.md; do
  found=$((found+1))
  dir="$(basename "$(dirname "$skill")")"

  # 必须以 frontmatter 分隔符开头
  if [ "$(head -n1 "$skill")" != "---" ]; then
    err "$skill 缺少 YAML frontmatter（首行应为 ---）"
    continue
  fi

  # 提取 frontmatter（首个 --- 与第二个 --- 之间）
  fm="$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$skill")"

  name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1)"
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n1)"

  [ -n "$name" ] || err "$skill 缺少 name:"
  [ -n "$desc" ] || err "$skill 缺少 description:"

  if [ -n "$name" ] && [ "$name" != "$dir" ]; then
    err "$skill 的 name ($name) 与文件夹名 ($dir) 不一致"
  fi

  if ! grep -q "$dir/SKILL.md" README.md; then
    err "README.md 未在「包含的 Skills」中引用 $dir"
  fi

  [ "$fail" -eq 0 ] && ok "$dir"
done
shopt -u nullglob

if [ "$found" -eq 0 ]; then
  err "未发现任何 .agents/skills/*/SKILL.md"
fi

echo ""
if [ "$fail" -ne 0 ]; then
  echo "校验未通过。"
  exit 1
fi
echo "校验通过（$found 个 Skill）。"
