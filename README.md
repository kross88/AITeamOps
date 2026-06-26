# AITeamOps

> 一套面向团队的 AI 协作开发 Skills 集合，让 Claude、Codex、Cursor、ChatGPT 在同一个项目里行为一致、流程可复用、操作有红线。

AITeamOps 把团队在真实项目里反复用到的 AI 操作沉淀成可触发的 **Skill**：环境初始化、安全提交、数据库只读探测……每个 Skill 都是一份带触发条件的 `SKILL.md`，AI 工具读到匹配场景就自动按既定流程执行，而不是每次现场即兴发挥。

> **English** — AITeamOps is a unified, team-oriented framework for AI-assisted development. It turns the operations a team repeats across real projects — environment bootstrap, guarded commits, post-task memory handoff, read-only database probing — into triggerable **Skills**: each is a `SKILL.md` with a trigger `description` and a body defining the exact workflow and red lines. The goal is consistent, reusable, *safe* behavior across Claude, Codex, Cursor, ChatGPT and future AI coding assistants — they read the matching Skill and follow a fixed procedure instead of improvising. Built on a three-layer split: **AGENTS.md** owns rules & routing, **Skills** own executable workflows, **docs** own business facts. Every Skill encodes where the AI must *stop and hand back to a human* (push, DB writes, business-logic changes). Docs are primarily in Chinese; contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and [ROADMAP.md](ROADMAP.md).

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
| [`project-context-sync`](.agents/skills/project-context-sync/SKILL.md) | 「开始看这个项目」「接手一下仓库」「同步项目上下文」，或首次浏览代码前 | **开工前先同步远程（git pull）+ 加载 docs/ai-memory，把理解对齐到团队基线**（读侧） |
| [`ai-handoff-doc-update`](.agents/skills/ai-handoff-doc-update/SKILL.md) | 任务完成后「沉淀一下」「更新文档/AGENTS.md」「写交接记录」 | 把本次产出按类别路由到 docs/ai-memory，只在稳定索引变化时才精修 AGENTS.md，不堆任务流水（写侧） |
| [`multi-tool-entrypoint-sync`](.agents/skills/multi-tool-entrypoint-sync/SKILL.md) | 「让 Codex/Claude/Cursor 行为一致」「多模型不一致」「配置各工具规则文件」 | 以 AGENTS.md 为唯一真源，为各 AI 工具生成指回它的入口文件，一源多入口 |
| [`git-commit-guard`](.agents/skills/git-commit-guard/SKILL.md) | 「帮我提交代码」「commit 一下」「提交并推送」 | 提交前跑检查关卡（diff 审查 → 构建 → 测试），全绿才 commit，push 需显式确认 |
| [`mysql-readonly-probe-via-java`](.agents/skills/mysql-readonly-probe-via-java/SKILL.md) | 机器无 mysql 客户端、需确认库结构/数据 | 用 JDK + 现成 connector jar 做 MySQL **只读**探测，绝不写库 |

每个 Skill 都内置「红线」与「认知边界」，明确什么动作必须停下来交回给人（push、写库、改业务逻辑等）。

> **读写闭环**：`project-context-sync`（开工读：同步远程 + 加载记忆）→ 干活 →`ai-handoff-doc-update`（收尾写：沉淀回记忆）。一个人用多模型、或一个团队多人协作时，所有 AI 都从同一份共享上下文出发、又写回同一处，理解持续收敛而不漂移。多工具一致性则由 `multi-tool-entrypoint-sync` 把各工具入口统一指向 `AGENTS.md` 解决。

---

## 目录结构

```text
AITeamOps/
├── README.md
├── AGENTS.md                                        # 本仓库自身的 AI 协作规则（框架活样板）
├── CONTRIBUTING.md                                  # 贡献指南：如何提交一个 Skill
├── ROADMAP.md                                       # 路线图（规划中 Skill 的唯一来源）
├── LICENSE                                          # MIT
├── .gitignore
├── .github/
│   └── workflows/validate.yml                       # CI：校验 SKILL.md 结构与 README 一致性
├── scripts/
│   ├── install-windows.ps1                          # Windows 下安装 Skills + 初始化项目协作骨架
│   ├── sync-tool-entrypoints.ps1                    # 从 AGENTS.md 真源生成各 AI 工具入口文件
│   └── validate.sh                                  # 校验脚本（本地/CI 通用）
└── .agents/
    └── skills/
        ├── team-ai-workspace-bootstrap/SKILL.md     # 环境初始化
        ├── project-context-sync/SKILL.md            # 开工前同步远程 + 加载记忆（读侧）
        ├── ai-handoff-doc-update/SKILL.md           # 任务后文档沉淀（写侧）
        ├── multi-tool-entrypoint-sync/SKILL.md      # 多工具入口统一指向 AGENTS.md
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

## 让「任务后文档沉淀」每次都触发

`ai-handoff-doc-update` 的目标是「每次完成任务都沉淀项目记忆」。但要明确一个边界：**Skill 是靠 `description` 匹配的自愿触发，不是 100% 强制。** 想让它稳定执行，有两种做法，**多数团队用规则驱动即可**：

**1. 规则驱动（默认推荐，贴合 AGENTS.md 体系）**

在项目 `AGENTS.md`（或团队全局规则）加一条硬约束，把「触发」从 AI 自觉变成明文规则：

```markdown
## 任务收尾规则
- 完成涉及代码 / SQL / 接口 / 命令的实质改动后，必须调用 `ai-handoff-doc-update` 沉淀文档。
- 沉淀顺序：先更新文档，再用 `git-commit-guard` 提交，让代码与项目记忆进同一个 commit。
```

优点：贴合现有规则体系、可读、零额外配置。局限：仍依赖 AI 遵守规则，非硬性强制。

**2. Hook 强制（harness 执行，硬保证，按需选用）**

在 AI 工具的配置（如 Claude Code 的 `settings.json`）里加一个 `Stop` hook，每次回复结束由 harness 注入提醒，强制 AI 检查是否需要沉淀。

优点：真正「每次都触发」。局限要权衡清楚：

- **较"吵"**：它在每次回复结束都触发一次，无法智能区分「刚完成真任务」和「只是答了个问题」，纯问答也会被拦一下，需要靠 Skill 正文「触发时机」一节来过滤。实测在问答多的会话里会明显拖节奏，多数团队不需要上到这一层。
- **中文 Windows 编码坑**：PowerShell 5.1 默认 stdout 为 GBK，注入的中文会乱码。脚本必须①文件带 UTF-8 BOM（否则 PS 5.1 按 GBK 读源码、中文字符串解析失败），②用 `[Console]::OpenStandardOutput()` 写**原始 UTF-8 字节**而非 `Write-Output`（否则注入文本乱码）。

> 不同工具的 hook 机制不同，且修改配置文件属于环境变更，请按自己工具的文档手动配置，或在明确授权后让 AI 代为修改。若只是想让团队稳定沉淀文档，优先用「规则驱动」，hook 留给确有硬性要求的场景。

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

写 Skill 时遵循同一套原则：**最小流程、明确边界、不替用户做高风险决定。** 完整贡献指南见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 路线图（规划中）

完整路线图见 **[ROADMAP.md](ROADMAP.md)**（含 SpringBoot / Vue Admin 走查、SQL 变更安全检查、AI handoff 记忆模板、多工具兼容示例等）。规划中的 Skill 清单**只以 ROADMAP.md 为唯一来源**，避免多处列表各写一份、日久漂移；新增规划项时只改那一处。

---

## License

[MIT](LICENSE)
