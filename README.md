# AITeamOps

> 一套面向团队的 AI 协作开发 Skills 集合，让 Claude、Codex、Cursor、ChatGPT 在同一个项目里行为一致、流程可复用、操作有红线。

AITeamOps 把团队在真实项目里反复用到的 AI 操作沉淀成可触发的 **Skill**：环境初始化、安全提交、数据库只读探测……每个 Skill 都是一份带触发条件的 `SKILL.md`，AI 工具读到匹配场景就自动按既定流程执行，而不是每次现场即兴发挥。

---

## 核心理念

团队协作里，AI 工具最容易出问题的不是「不会写代码」，而是「不知道什么时候该停、该问、该按规矩来」。AITeamOps 用三层分工解决这个问题：

```text
AGENTS.md  →  管「规则」和「路由」：在哪个目录该守什么约束、该读哪个 Skill
Skills     →  管「执行流程」：把可复用的操作步骤固化成可触发的流程
docs       →  管「业务事实」和「验收依据」：业务流程、交接记录、验收清单
```

三者职责不重叠：**规则不写进 Skill，业务事实不写进 AGENTS.md。** 本仓库聚焦中间这一层 —— Skills。

---

## 包含的 Skills

| Skill | 触发场景 | 一句话作用 |
|---|---|---|
| [`team-ai-workspace-bootstrap`](.agents/skills/team-ai-workspace-bootstrap/SKILL.md) | 新项目接入 AI 规范、统一 AGENTS.md、搭 skills/docs 骨架 | 生成目录骨架与 AGENTS.md、docs 模板，统一团队 AI 协作环境 |
| [`git-commit-guard`](.agents/skills/git-commit-guard/SKILL.md) | 「帮我提交代码」「commit 一下」「提交并推送」 | 提交前跑检查关卡（diff 审查 → 构建 → 测试），全绿才 commit，push 需显式确认 |
| [`mysql-readonly-probe-via-java`](.agents/skills/mysql-readonly-probe-via-java/SKILL.md) | 机器无 mysql 客户端、需确认库结构/数据 | 用 JDK + 现成 connector jar 做 MySQL **只读**探测，绝不写库 |

每个 Skill 都内置「红线」与「认知边界」，明确什么动作必须停下来交回给人（push、写库、改业务逻辑等）。

---

## 目录结构

```text
AITeamOps/
├── README.md
├── .gitignore
├── scripts/
│   └── install-windows.ps1                          # Windows 下初始化协作目录骨架
└── .agents/
    └── skills/
        ├── team-ai-workspace-bootstrap/SKILL.md     # 环境初始化
        ├── git-commit-guard/SKILL.md                # 安全提交关卡
        └── mysql-readonly-probe-via-java/SKILL.md   # 数据库只读探测
```

---

## 安装

Skill 的本质是一个放在约定目录下的 `SKILL.md` 文件夹，AI 工具启动时扫描该目录即可加载。把本仓库的 Skill 复制到目标位置即可：

**用户级（对所有项目生效）**

```bash
# Claude Code / 通用 agents 约定目录
git clone https://github.com/kross88/AITeamOps.git
cp -r AITeamOps/.agents/skills/* ~/.agents/skills/
```

```powershell
# Windows PowerShell
git clone https://github.com/kross88/AITeamOps.git
Copy-Item AITeamOps\.agents\skills\* "$env:USERPROFILE\.agents\skills\" -Recurse
```

**项目级（只对当前项目生效，推荐团队共享时用）**

把需要的 Skill 目录放进项目的 `.agents/skills/` 下，随仓库一起提交，团队成员拉代码即获得同一套 Skill。

> 不同工具的 Skill 扫描目录可能不同（如 `~/.claude/skills`、项目 `.agents/skills`）。以你所用工具的文档为准，把对应 `SKILL.md` 文件夹放进去即可。

---

## 怎么触发

Skill 不需要手动调用 —— AI 工具会读取每个 `SKILL.md` 头部的 `description`，当你说的话匹配到触发场景时自动加载并按流程执行。例如：

- 「帮我把这次改动提交了」 → 命中 `git-commit-guard`，先跑检查关卡再 commit
- 「这个新项目接入一下 AI 开发规范」 → 命中 `team-ai-workspace-bootstrap`
- 「线上这台机器没装 mysql，帮我看下这张表结构」 → 命中 `mysql-readonly-probe-via-java`

所以 `description` 写得越准，触发越精确。

---

## SKILL.md 是怎么工作的

每个 Skill 是一个文件夹，至少包含一个 `SKILL.md`，结构为「YAML frontmatter + Markdown 正文」：

```markdown
---
name: git-commit-guard
description: 当用户说「帮我提交代码」「commit 一下」…时使用。本 Skill 会先检查改动、再构建测试，全绿才 commit。
---

# Git Commit Guard

正文：执行流程、红线、常见坑……
```

- **`name`**：Skill 唯一标识，与文件夹同名，kebab-case。
- **`description`**：决定「何时触发」。要写清适用场景和不适用场景，这是 AI 选用 Skill 的唯一依据。
- **正文**：决定「触发后怎么做」。建议包含：认知边界、红线、分步流程、反馈格式、常见坑。

写好一个 Skill 的关键，是把「**什么时候必须停下来交回给人**」写进红线 —— push、写库、改业务逻辑这类不可逆或高风险动作，默认不自动做。

---

## 新增一个 Skill

1. 在 `.agents/skills/` 下建一个 kebab-case 命名的文件夹。
2. 写 `SKILL.md`：先想清楚触发场景（写进 `description`），再写执行流程和红线（写进正文）。
3. 在本 README 的「包含的 Skills」表格里登记一行。
4. 用 `git-commit-guard` 的思路提交：先自检 diff，再 commit，push 前确认。

写 Skill 时遵循同一套原则：**最小流程、明确边界、不替用户做高风险决定。**

---

## 路线图（规划中）

以下 Skill 已在 `team-ai-workspace-bootstrap` 中作为配套规划列出，尚未实现：

```text
business-closed-loop-review     # 业务闭环走查
java-springboot-review          # SpringBoot 代码走查
vue-admin-review                # Vue Admin 前端走查
sql-migration-safety            # SQL 变更安全检查
ai-handoff-doc-update           # AI 交接文档更新
```

---

## License

MIT
