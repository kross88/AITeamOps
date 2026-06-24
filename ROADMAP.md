# Roadmap

> 本文件是 AITeamOps 规划中 Skill 与方向的**唯一权威来源**。README、各 Skill 正文、根 `AGENTS.md` 涉及「规划中」时一律指向这里，不再各写一份，避免清单漂移。
> This is the single source of truth for AITeamOps' roadmap. All other docs link here instead of duplicating the list.

## 已发布 / Released

### v0.1.0
- `team-ai-workspace-bootstrap` —— 团队 AI 协作环境初始化（AGENTS.md + skills + docs 骨架）
- `git-commit-guard` —— 提交前检查关卡（diff 自检含未跟踪文件 → 构建 → 测试），全绿才 commit，push 需确认
- `ai-handoff-doc-update` —— 任务后把项目记忆按类别沉淀到 `docs/ai-memory/`
- `mysql-readonly-probe-via-java` —— 无客户端时用 Java JDBC 做 MySQL 只读探测，绝不写库
- 工程基建：根 `AGENTS.md`（dogfood 自身）、`LICENSE`(MIT)、`CONTRIBUTING.md`、Windows 安装/初始化脚本

## 规划中 / Planned

> 引用以下任何一项时，必须标注「规划中」，不得假定已实现。
> When referencing any item below, mark it as *planned* — do not assume it exists yet.

| 计划 Skill / 方向 | 一句话目标 | 备注 |
|---|---|---|
| `java-springboot-review` | SpringBoot 后端代码走查（分层、事务、空指针、权限边界、SQL 注入） | code review skill |
| `vue-admin-review` | Vue Admin 前端走查（组件规范、接口字段对齐、权限渲染） | code review skill |
| `sql-migration-safety` | SQL 变更安全检查（DDL/DML 影响面、备份与回滚、锁与大表风险） | migration safety |
| `business-closed-loop-review` | 业务闭环走查：从入口到落库的端到端一致性核对 | 依赖 `docs/` 业务事实 |
| `ai-handoff-memory-template` | 为 `docs/ai-memory/` 提供开箱即用的 task-log / interface-map / database-map / risk-points 模板 | 强化 `ai-handoff-doc-update` |
| `multi-tool-compatibility-examples` | Codex / Claude / Cursor / ChatGPT 的接入与触发示例，验证同一套 Skill 跨工具一致 | 兼容性样例 + 文档 |

## 设计原则 / Principles

新增任何 Skill 都遵循同一套原则（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）：

- **最小流程**：只固化真正可复用的步骤，不堆冗余。
- **明确边界**：写清适用与不适用场景（决定触发精度）。
- **红线优先**：把「何时必须停下来交回给人」写进红线——push、写库、改业务逻辑等不可逆或高风险动作默认不自动做。

## 反馈 / Feedback

有想要的 Skill 或方向，欢迎提 Issue 或 PR（见 [CONTRIBUTING.md](CONTRIBUTING.md)）。
