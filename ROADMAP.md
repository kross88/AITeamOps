# Roadmap

> 本文件是 AITeamOps 规划中 Skill 与方向的**唯一权威来源**。README、各 Skill 正文、根 `AGENTS.md` 涉及「规划中」时一律指向这里，不再各写一份，避免清单漂移。
> This is the single source of truth for AITeamOps' roadmap. All other docs link here instead of duplicating the list.

## 已发布 / Released

### v0.2.0（开发中 / unreleased）
聚焦两个核心问题：① 一个人用多个模型写同一项目；② 一个团队多人、各自 AI 对项目理解不一。并引入「三层记忆 + 跨项目经验累积」。
- `project-context-sync` —— 开工/首次浏览代码前**先同步远程（git pull）+ 加载 `docs/ai-memory`**，把理解对齐到团队基线（`ai-handoff-doc-update` 的读侧对偶）
- `cross-project-experience` —— 把**对任何项目都适用**的经验沉淀进全局指令文件（CLAUDE.md/AGENTS.md），一个微型的永久经验累积过程（第 ② 层记忆）
- `onboard-aiteamops` + `ONBOARDING.md` —— 自举层：让一个陌生工具/模型「读懂框架→写进自己的永久记忆文件→自检」，把「让你的 AI 学习并永久记住本框架」变成自助、可验证、跨工具的流程
- `multi-tool-entrypoint-sync` + `scripts/sync-tool-entrypoints.ps1` —— 以 `AGENTS.md` 为唯一真源，为 Codex/Claude/Cursor/Copilot/Gemini 等生成「指回真源」的入口文件
- `docs/ai-memory/overview.md` —— 项目心智模型快照，团队共享理解的单一入口
- `ai-handoff-doc-update` 增补「团队并发与合并约定」（顶部追加 / 原子条目 / 冲突两留）
- `ai-deliverable-review` —— 验收级复核另一个 AI/同事交付的模块：不信总结只信代码、四类越权逐条查、验证等级 L0-L3 必须声明（源自真实场景：Codex 开发 + Claude 复核暴露的 3 个编译错误）
- `mysql-guarded-write` —— 用户明确授权下的受控写库：表白名单过目、逐条预检+报告影响行数、先备份可回滚、DROP/TRUNCATE/无 WHERE 更新绝对禁止（`mysql-readonly-probe` 的写侧姊妹，其只读红线不变）
- **固定动作**（把义务性规则绑定到可见产物，治「巧合合规」与沉默偏离）：开工声明、收尾沉淀结论、冲突外显、验证等级声明——禁止性规则容易守、义务性规则容易漏，可见产物让漏跑一眼可查
- **数据库核验习惯**：写 SQL 前先探真实表结构与方言；写/改接口后 SELECT 采样核验字段类型与存储格式（逗号分隔 vs JSON 等），别靠猜
- `team-ai-workspace-bootstrap` 升级为「**初始化 = 分析 + 预填**」：自动探测项目结构/技术栈/数据库（只问探测不到的），生成含真实内容的 AGENTS.md（新增「**AI 行动边界**」——本项目允许 compile 吗/测试口径/连库口径，全团队所有 AI 工具统一读同一套权限口径）并预填 `overview.md`/`database-map.md` 初稿——空骨架时代结束，读写闭环第一天就有内容
- `templates/需求说明模板.md` —— **输入侧治理**：给 AI 的开发任务书模板（业务闭环/角色口径/默认决策口径/交付物与自测清单/固定回复格式），提炼自真实项目验证有效的写法；需求说明归档到项目 `docs/requirements/` 随代码进 git
- CI（`.github/workflows/validate.yml` + `scripts/validate.sh`）：校验 SKILL.md 结构与 README 一致性

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
| `ai-memory-staleness-check` | 校验 `docs/ai-memory` 是否引用了已不存在的文件/表，标记过期条目 | 让共享记忆可信 |
| `memory-consolidation` | 周期性/文件过大时整理 `docs/ai-memory`：合并重复、SUPERSEDE 过期事实、归档旧 task-log、把高频事实上提到 overview | 借鉴向量插件的 "dreaming" 离线整理，让记忆只增不腐 |
| `multi-tool-compatibility-examples` | 各工具接入与触发的最小可跑示例 | 在 `multi-tool-entrypoint-sync` 基础上补样例 |
| `install.sh`（Linux/macOS） | 把 `install-windows.ps1` 的安装/初始化能力补到类 Unix | 跨平台 |
| 并行开发约定 | 多名成员同时让各自 AI 开发同一项目时的协作协议：模块认领、分支口径、共享文件（字典/错误码/路由表）改动的碰撞预防 | 可先作为 bootstrap 生成的 AGENTS.md 一节，够复杂再独立成 Skill |
| `retrospective-review` | 定期（如月度）让 AI 复盘 task-log/risk-points：重复出现的坑 → 提议升级为规则或 Skill | cross-project-experience 的批处理版，让框架自我进化有节奏 |

## 记忆的成长路径 / Memory scaling path

AITeamOps 的记忆是**零运行时的 markdown**（`docs/ai-memory/*.md`、`MEMORY.md`），人读、git 共享、人工维护——适合几十到几百条规模。当一个团队的记忆涨到上千条、人工翻不动时，不必推倒重来：

- 这些 markdown 文件**本身就是规范真源**；可以在其上**挂一个向量记忆插件**（如 OpenClaw 的 `memory-lancedb-pro`，它的规范文本恰好也存在 `MEMORY.md` / `memory/**/*.md`）来做语义检索、自动召回。
- **分工**：AITeamOps 做「轻量、可读、可审计的真源 + 团队约定」；向量插件做「大规模语义检索」。互补，不竞争。
- 本框架的记忆纪律（L0/L1/L2 分层、case/pattern 双层、值得记/绝不记、去重 7 决策）正是借鉴这类成熟插件、又落进纯 markdown 的产物——所以两者天然兼容。

## 设计原则 / Principles

新增任何 Skill 都遵循同一套原则（详见 [CONTRIBUTING.md](CONTRIBUTING.md)）：

- **最小流程**：只固化真正可复用的步骤，不堆冗余。
- **明确边界**：写清适用与不适用场景（决定触发精度）。
- **红线优先**：把「何时必须停下来交回给人」写进红线——push、写库、改业务逻辑等不可逆或高风险动作默认不自动做。

## 反馈 / Feedback

有想要的 Skill 或方向，欢迎提 Issue 或 PR（见 [CONTRIBUTING.md](CONTRIBUTING.md)）。
