---
name: team-ai-workspace-bootstrap
description: 用于初始化和统一团队 AI 协作开发环境。适用于配置 Codex、Claude、Cursor、ChatGPT 等 AI 编程工具的全局规则；生成项目级 AGENTS.md；生成前端、后端目录级 AGENTS.md；创建 docs 协作文档；创建项目共享 Skills 目录。本 Skill 不用于直接编写业务代码。
---

# Team AI Workspace Bootstrap

本 Skill 用于帮助团队统一 AI 编程协作环境。

## 核心原则

AGENTS.md 管规则和路由；Skills 管执行流程；docs 管业务事实和验收依据。

## 推荐项目结构

```text
project-root/
├── AGENTS.md
├── service/
│   └── AGENTS.md
├── backweb/
│   └── AGENTS.md
├── .agents/
│   └── skills/
└── docs/
    ├── 系统业务流程.html
    ├── AI开发交接记录.md
    └── 模块验收清单.md
```

## 推荐 Skills

```text
.agents/skills/business-closed-loop-review/SKILL.md
.agents/skills/java-springboot-review/SKILL.md
.agents/skills/vue-admin-review/SKILL.md
.agents/skills/sql-migration-safety/SKILL.md
.agents/skills/ai-handoff-doc-update/SKILL.md
.agents/skills/mysql-readonly-probe-via-java/SKILL.md
```
