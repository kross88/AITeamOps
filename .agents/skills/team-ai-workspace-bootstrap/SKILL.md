---
name: team-ai-workspace-bootstrap
description: 初始化和统一团队 AI 协作开发环境。当用户提到「初始化 AI 协作环境」「统一团队 AGENTS.md」「配置 Codex/Claude/Cursor/ChatGPT 规则」「搭建 skills 目录」「建 docs 协作文档」「新项目接入 AI 开发规范」，或在一个新仓库/新模块里想让团队的 AI 工具行为一致时，都应使用本 Skill。本 Skill 负责生成目录骨架、AGENTS.md、docs 模板，不用于编写业务代码。
---

# Team AI Workspace Bootstrap

本 Skill 用于帮团队统一 AI 编程协作环境：让 Codex、Claude、Cursor、ChatGPT 等工具在同一个项目里遵循一致的规则、复用同一套 Skills、读同一份业务事实。

## 核心原则

```text
AGENTS.md  管「规则」和「路由」——告诉 AI 在哪个目录该遵守什么约束、该读哪个 Skill。
Skills     管「执行流程」——把可复用的操作步骤沉淀成可触发的流程。
docs       管「业务事实」和「验收依据」——业务流程、交接记录、验收清单。
```

三者职责不重叠：规则不写进 Skill，业务事实不写进 AGENTS.md。

## 推荐项目结构

```text
project-root/
├── AGENTS.md                  # 项目级总规则 + 目录路由
├── service/                   # 后端（示例命名，按实际调整）
│   └── AGENTS.md              # 后端目录级规则
├── backweb/                   # 前端（示例命名，按实际调整）
│   └── AGENTS.md              # 前端目录级规则
├── .agents/
│   └── skills/                # 项目共享 Skills
└── docs/
    ├── 系统业务流程.html
    ├── AI开发交接记录.md
    └── 模块验收清单.md
```

## 执行步骤

### 第 1 步：确认项目信息

动手前先和用户确认，不要假设：

```text
1. 后端目录叫什么（service / server / backend / api …）
2. 前端目录叫什么（backweb / web / frontend / admin …）
3. 技术栈（如 Java SpringBoot + Vue Admin）
4. 是单体还是多模块 / 多服务
5. 团队主要用哪些 AI 工具
```

### 第 2 步：生成根目录 AGENTS.md

根 AGENTS.md 至少包含四块：项目概述、目录路由、全局红线、文档约定。模板：

```markdown
# AGENTS.md

## 项目概述
（一句话说明这是什么系统、给谁用）

## 目录路由
- `service/`：后端，进入时先读 `service/AGENTS.md`
- `backweb/`：前端，进入时先读 `backweb/AGENTS.md`
- `.agents/skills/`：项目共享 Skills，操作前先看是否有对应 Skill
- `docs/`：业务事实与验收依据，改业务逻辑前先读

## 全局红线
- 不读 `docs/` 不动业务逻辑
- 改库 / 改表结构必须先出 SQL 给人审，不自动执行
- 涉及数据库只读排查，使用 `mysql-readonly-probe-via-java` Skill

## 文档约定
- 业务变更同步更新 `docs/AI开发交接记录.md`
- 新模块完成后更新 `docs/模块验收清单.md`
```

### 第 3 步：生成目录级 AGENTS.md

前端、后端各自的 AGENTS.md 写本目录专属约束（技术栈规范、命名约定、该目录适用的 Skill），不重复根目录内容。

### 第 4 步：创建 docs 模板

```text
docs/系统业务流程.html     # 业务全景，给 AI 和新人快速建立上下文
docs/AI开发交接记录.md     # 每次重要变更追加一条，谁改了什么、为什么
docs/模块验收清单.md       # 每个模块的验收标准，作为「完成」的客观依据
```

### 第 5 步：建立 .agents/skills 目录并接入 Skill

```text
.agents/skills/
```

按需放入团队共享 Skill。

## 配套 Skills

已实现，可直接引用：

```text
.agents/skills/mysql-readonly-probe-via-java/SKILL.md    # MySQL 只读探测（无客户端 / Java JDBC）
.agents/skills/git-commit-guard/SKILL.md                 # 提交前检查关卡，全绿才 commit，push 需确认
```

规划中（尚未实现，使用本 Skill 时若引用请标注「规划中」，不要假定已存在）：

```text
business-closed-loop-review     # 业务闭环走查
java-springboot-review          # SpringBoot 代码走查
vue-admin-review                # Vue Admin 前端走查
sql-migration-safety            # SQL 变更安全检查
ai-handoff-doc-update           # AI 交接文档更新
```

## 本 Skill 不做什么

- 不编写业务代码。
- 不替用户决定目录命名，必须先确认。
- 不生成空指针 Skill 引用——只引用真实存在的 Skill，规划中的明确标注。
