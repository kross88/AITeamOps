---
name: team-ai-workspace-bootstrap
description: 初始化项目的 AI 协作环境——先认真分析项目再生成有真实内容的规则与记忆，不是只建空目录。当用户说「初始化下项目」「初始化一下这个项目」「初始化 AI 协作环境」「统一团队 AGENTS.md」「新项目接入 AI 开发规范」「搭建 skills/docs 骨架」时使用。做法：自动探测项目结构/技术栈/模块划分/数据库（只读），探测结论给用户确认后，生成含真实内容的 AGENTS.md（含 AI 行动边界）并预填 docs/ai-memory/overview.md 项目心智模型初稿，让读写闭环从第一天就有内容可读。不编写业务代码。
---

# Team AI Workspace Bootstrap

本 Skill 用于帮团队统一 AI 编程协作环境：让 Codex、Claude、Cursor、ChatGPT 等工具在同一个项目里遵循一致的规则、复用同一套 Skills、读同一份业务事实。

**初始化 = 分析 + 预填，不是 mkdir。** 用户说「初始化下项目」时，要做的是一次「项目入学考试」：自己把项目读懂（目录、技术栈、模块、数据库），把结论写成**有真实内容**的 AGENTS.md 和 `overview.md` 初稿——而不是问用户一堆 AI 自己能查清的问题，然后建一堆空文件。空的 `overview.md` 意味着下一次 `project-context-sync` 开工加载进来的是空气。

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
├── AGENTS.md                  # 项目级总规则 + 目录路由（唯一真源；★ 初始化只建这一份）
├── CLAUDE.md / GEMINI.md …    # 各工具入口（指针，由 multi-tool-entrypoint-sync 生成，按需）
├── service/                   # 后端（示例命名，按实际调整）
│   └── AGENTS.md              # 目录级规则——【按需后加】初始化不建，某目录攒够专属约束再补
├── backweb/                   # 前端（示例命名，按实际调整）
│   └── AGENTS.md              # 目录级规则——【按需后加】初始化不建
├── .agents/
│   └── skills/                # 项目共享 Skills
└── docs/
    ├── 系统业务流程.html       # 业务全景
    ├── 模块验收清单.md         # 验收依据
    ├── requirements/          # 需求说明归档（按 templates/需求说明模板.md 写，随代码进 git）
    └── ai-memory/             # 项目记忆（开工 project-context-sync 读，收尾 ai-handoff-doc-update 写）
        ├── overview.md        # 心智模型快照 + 风险要点（core，开工必读，保持精简）
        ├── details.md         # 全部明细：模块/表/接口一实体一个 ## 小节（working，按需查节）
        └── task-log.md        # 任务流水 + 写库台账 DBW 条目（只追加）
```

> docs 结构与 `ai-handoff-doc-update` 的路由表、`scripts/install-windows.ps1` 完全对齐，三处保持同一套，避免「两套并存」。
> 多工具入口（`CLAUDE.md`/`.cursor/rules/…`/`GEMINI.md` 等）以 `AGENTS.md` 为唯一真源，由 `multi-tool-entrypoint-sync` 生成，团队用几个工具就生成几个。

## 红线

1. **分析阶段只读。** 探测目录/构建文件/配置只是读；数据库探测走 `mysql-readonly-probe-via-java`，绝不写库。
2. **生成文件前，清单先给用户过目。** 要新建/修改哪些文件一次性列出，确认后落盘。
3. **不覆盖已有内容。** 项目已有 AGENTS.md / docs / ai-memory 的部分跳过或增量补充，绝不重写。
4. **不动业务代码。** 初始化只产出规则与记忆文档。
5. **探测结论如实标注把握度。** 从代码读出的写「已核实」，推断的标「待确认」，不把猜测写成事实。

## 执行步骤

### 第 1 步：自动探测项目（先分析，不先提问）

这些信息 AI 读代码就能查清，**不要拿去问用户**：

```text
探测项                  怎么探
目录结构与前后端划分     ls 根目录；找 pom.xml / build.gradle / package.json 的位置
技术栈与版本            pom.xml（Spring Boot/JDK 版本）、package.json（Vue/React 版本）
单体还是多模块          pom 的 <modules>、monorepo 布局
数据库类型与连接        application*.yml 的 datasource（注意激活 profile）；
                        能连库时用 mysql-readonly-probe-via-java 探真实版本/核心表（只读）
既有约定                SQL 增量文件的写法、菜单/字典表结构、代码分层风格（Controller/Service/Mapper）、
                        逻辑删除字段、ID 类型、日期处理惯例
已有 AI 协作痕迹        AGENTS.md / CLAUDE.md / docs/ai-memory 是否已存在（存在则增量，不重建）
```

### 第 2 步：探测结论给用户确认（只问探测不到的）

把第 1 步结论摘要给用户过目（各项标注「已核实 / 待确认」），**只问真探测不到的**：

```text
1. 团队主要用哪些 AI 工具（决定 multi-tool-entrypoint-sync 生成哪些入口）
2. AI 行动边界的口径（允许 compile 吗？允许跑测试吗？连库只读还是可授权写？）
3. 有歧义的取舍（如两个疑似前端目录，哪个是主工程）
```

### 第 3 步：生成【根】AGENTS.md（只建这一份，填真实内容，不留占位符）

**初始化只生成项目级（根）AGENTS.md，不建各模块的目录级 AGENTS.md。** 目录级留到某个目录真攒够了「本目录专属、且跟根不同」的约束时，再按需单独补——初始化时一次性给每个模块铺一份，多半是空话或重复根内容，属于过度脚手架。

根 AGENTS.md 五块：项目概述、目录路由、**AI 行动边界**、全局红线、文档约定。**用第 1 步探测到的真实目录名、真实技术栈填写**，不交付「（一句话说明…）」这种占位模板。示例：

```markdown
# AGENTS.md

## 项目概述
（用探测结论写实：如"就业服务平台，Spring Boot 2.7 + Vue3 前后端分离，MySQL 5.7"）

## 目录路由
- `service/`：后端（Maven 多模块）；如该目录有 `AGENTS.md` 则进入时先读（默认无，按需后加）
- `backweb/`：前端（Vue3 + Vite）；同上
- `.agents/skills/`：项目共享 Skills，操作前先看是否有对应 Skill
- `docs/`：业务事实与验收依据，改业务逻辑前先读；需求说明归档在 `docs/requirements/`

## AI 行动边界（本项目口径，第 2 步与用户确认后写死，所有 AI 工具统一遵守）
- 构建：允许 compile（不 package、不启动服务）/ 或按确认结果填
- 测试：禁止自动执行 / 或允许单测
- 数据库：只读探测随时可做；写库需本次会话明确授权（mysql-guarded-write）
- SQL：一律增量文件，不改已执行过的旧 SQL；执行权在人

## 全局红线
- **首次浏览/探索代码前，必须先用 `project-context-sync` 同步远程并加载 `docs/ai-memory`**（无 git 仓库则跳过同步）
- 不读 `docs/` 不动业务逻辑
- 改库 / 改表结构必须先出 SQL 给人审，不自动执行
- 涉及数据库只读排查，使用 `mysql-readonly-probe-via-java` Skill

## 文档约定
- 开工先读 `docs/ai-memory/overview.md`（项目心智模型）；业务变更与任务记录由 `ai-handoff-doc-update` 沉淀回 `docs/ai-memory/`
- 新需求先按 `templates/需求说明模板.md`（AITeamOps 仓库内）写需求说明，归档到 `docs/requirements/`
- 新模块完成后更新 `docs/模块验收清单.md`
- 多工具入口以本 `AGENTS.md` 为唯一真源，由 `multi-tool-entrypoint-sync` 生成，不在入口文件里复制规则正文
```

> **「AI 行动边界」是给团队的关键交付**：允许 compile 吗、能跑测试吗、连库口径是什么——写进项目 AGENTS.md 后，每个成员的每个 AI 工具读到的都是同一套权限口径，不用每次需求里重复交代，也避免不同人给自己的 AI 开不同的口子。

> **目录级 AGENTS.md 初始化不建。** 把探测到的分层风格、命名约定、逻辑删除字段、日期处理惯例先写进**根** AGENTS.md 或 `docs/ai-memory/overview.md` 即可。等某个目录（如后端某模块）确实积累了「只在本目录成立、且和根不同」的约束，再单独给它加一份目录级 AGENTS.md，写实、不重复根内容。**先根后枝，按需生长**。

### 第 4 步：建 docs 骨架并【预填初始记忆】（本 Skill 的核心价值）

```text
docs/系统业务流程.html            # 业务全景，给 AI 和新人快速建立上下文
docs/模块验收清单.md              # 每个模块的验收标准，作为「完成」的客观依据
docs/requirements/               # 需求说明归档（按 templates/需求说明模板.md 编写）
docs/ai-memory/overview.md       # ★ 心智模型 + 风险要点，用第 1 步分析结果写【初稿】，不许留空
docs/ai-memory/details.md        # ★ 明细：模块/表/接口一实体一个 ## 小节；初始化列出探测到的模块标题，能连库就预填核心表小节
docs/ai-memory/task-log.md       # 任务流水 + 写库台账 DBW 条目（首条记录：本次初始化）
```

`overview.md` 初稿至少包含（全部来自第 1 步探测，标注「已核实/待确认」）：

```text
架构一句话（技术栈+版本+部署形态）｜模块清单（每模块一行职责）｜
数据库（类型/版本/核心表一览）｜关键约定（ID 类型、逻辑删除、日期格式、
SQL 增量文件写法、菜单权限机制）｜已知风险点
```

> 模块与表名用 `[[名称]]` 标注互链（`[[实体]]`→`details.md` 对应小节（模块/表/接口统一），约定见 `ai-handoff-doc-update` 的「关系链接」），让 overview 从第一天就是记忆网的关系中枢。

> 空骨架是上一版的坑：`overview.md` 为空时，下次 `project-context-sync` 加载进来的是空气，读写闭环名存实亡。**预填初稿让闭环从第一天就有内容。**

### 第 5 步：接入 Skills 与多工具入口

- 建 `.agents/skills/`，按需放入团队共享 Skill。
- 团队用多个 AI 工具时，用 `multi-tool-entrypoint-sync` 生成各工具入口（指回 AGENTS.md）。

## 配套 Skills

已实现，可直接引用：

```text
.agents/skills/onboard-aiteamops/SKILL.md                # 自举：教新工具/模型学会并永久记住本框架
.agents/skills/project-context-sync/SKILL.md             # 开工先同步远程+加载记忆，对齐团队理解（读侧）
.agents/skills/requirement-delivery-flow/SKILL.md        # 干活阶段执行纪律：想清楚→最多确认一次→一口气做完→自检，治空转
.agents/skills/ai-handoff-doc-update/SKILL.md            # 任务后文档沉淀，按类别路由到 docs/ai-memory（写侧）
.agents/skills/ai-deliverable-review/SKILL.md            # 复核 AI/他人交付的模块（验收级，不信总结只信代码）
.agents/skills/cross-project-experience/SKILL.md         # 跨项目通用经验沉淀到全局指令文件（全局累积）
.agents/skills/multi-tool-entrypoint-sync/SKILL.md       # 以 AGENTS.md 为真源，生成各 AI 工具入口文件
.agents/skills/git-commit-guard/SKILL.md                 # 提交前检查关卡，全绿才 commit，push 需确认
.agents/skills/mysql-readonly-probe-via-java/SKILL.md    # MySQL 只读探测（无客户端 / Java JDBC）
.agents/skills/mysql-guarded-write/SKILL.md              # 用户明确授权下的受控写库（白名单/预检/可回滚）
```

规划中（尚未实现）：清单与目标以仓库根的 **`ROADMAP.md`** 为唯一来源。使用本 Skill 时若引用任何规划中 Skill，必须标注「规划中」，不要假定已存在。

## 本 Skill 不做什么

- 不编写业务代码。
- 不把 AI 能自己探测的信息拿去问用户（那是偷懒）；也不把探测不到的事替用户拍板（工具选择、行动边界口径必须确认）。
- 不交付空骨架——`overview.md`、`details.md` 必须有初稿内容。
- 不生成空指针 Skill 引用——只引用真实存在的 Skill，规划中的明确标注。
