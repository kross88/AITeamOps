# AGENTS.md

> 本文件是 AITeamOps 仓库自身的 AI 协作规则。它既约束在本仓库里工作的 AI 工具，也作为本框架「根 AGENTS.md」的一份活样板——本仓库讲什么，就先在自己身上做到什么。

## 项目概述

AITeamOps 是一套面向团队的 AI 协作开发 **Skills 集合**：把团队反复用到的 AI 操作（环境初始化、安全提交、文档沉淀、数据库只读探测）沉淀成可触发的 `SKILL.md`。本仓库**只交付 Skills 与说明文档，不含业务代码**。

三层分工（本框架的核心理念）：

```text
AGENTS.md  →  规则与路由：在哪个目录守什么约束、读哪个 Skill
Skills     →  执行流程：可复用操作步骤固化成可触发流程
docs       →  业务事实与验收依据
```

## 目录路由

- `.agents/skills/`：全部 Skill 所在地，每个子目录一个 `SKILL.md`。改任何 Skill 前先读它本身。
- `scripts/`：脚本。`install-windows.ps1`（安装 Skills + 初始化项目骨架）、`sync-tool-entrypoints.ps1`（生成各工具入口）、`validate.sh`（CI 校验）。
- `ROADMAP.md` / `CONTRIBUTING.md`：路线图（规划中唯一来源）/ 贡献指南。
- `README.md`：对外说明书，面向人类读者。
- `LICENSE`：MIT。

## 全局红线

- **首次浏览/探索本仓库代码前，先 `git pull --ff-only` 同步远程**（无 git 仓库或无 remote 则跳过；工作区有改动/冲突时停下交人，不强拉）。即 `project-context-sync` 的第 0 步。
- **不在本仓库写入业务代码。** 这里只放 Skill 与文档。
- **改 Skill 的「红线 / 认知边界」前先问人。** 那是各 Skill 的安全承诺，影响所有使用者，不可自行放宽。
- **保持三处 docs 结构一致。** `team-ai-workspace-bootstrap` 的推荐结构、`ai-handoff-doc-update` 的路由表、`scripts/install-windows.ps1` 创建的骨架必须对齐，改一处要同步其余两处。
- **脚本不得破坏用户已有文件。** 初始化脚本对已存在的目录/文件一律跳过，绝不覆盖或清空。
- **README 里写到的能力必须真实存在。** 规划中的 Skill 明确标注「规划中」，不假装已实现。

## 文档约定

- 新增 / 改动 Skill 后，同步更新 `README.md` 的「包含的 Skills」表格。
- 规划中的 Skill 清单以根目录 `ROADMAP.md` 为**唯一来源**，README、各 Skill 正文一律指向它，不重复维护。
- 贡献流程与 Skill 编写规范见 `CONTRIBUTING.md`。
- 提交遵循 `git-commit-guard` 的思路：先自检 diff（含未跟踪文件），再 commit，push 前确认。

## 写 / 改 Skill 的原则

`SKILL.md` = YAML frontmatter（`name` + `description`）+ Markdown 正文。

- `description` 决定何时触发，要写清适用与不适用场景，并带上用户的口语化触发句。
- 正文决定触发后怎么做，建议含：认知边界、红线、分步流程、反馈格式、常见坑。
- 把「**什么时候必须停下来交回给人**」写进红线——push、写库、改业务逻辑等不可逆或高风险动作，默认不自动做。
