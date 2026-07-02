---
name: project-context-sync
description: 开始在一个项目里干活、第一次浏览/探索代码之前使用。先同步远程仓库（git pull），再加载 AGENTS.md 与 docs/ai-memory，把当前 AI 的理解对齐到团队已记录的项目理解，然后才动代码。当用户说「开始看这个项目」「接手一下这个仓库」「我们继续这个项目」「同步一下项目上下文」，或任何一次会话首次进入某项目准备读/改代码时，都应先跑本 Skill。本 Skill 只读不写代码，是 ai-handoff-doc-update（写）的对偶（读）。
---

# Project Context Sync（开工前上下文对齐）

每次开始在一个项目里工作前，先把「远程最新代码 + 团队已记录的项目理解」加载进来，让这一轮 AI 的理解和团队保持同一基线，避免「同一个项目、每个人的 AI 理解不一样」。这是 `ai-handoff-doc-update` 的读侧对偶：那个负责把理解**写回**共享记忆，本 Skill 负责开工前把共享记忆**读进来**。

## 最重要的认知边界

- **先同步，再判断。** 不先拉远程就读代码，很可能是在过期代码上做判断，团队多人协作时尤其危险。
- **记忆是「写入时的事实」，代码才是当下的事实。** `docs/ai-memory` 与当前代码冲突时，以代码为准，并把过期处标注出来（顺手在收尾时让 `ai-handoff-doc-update` 订正）。
- **本 Skill 只读不写代码。** 只做同步与理解对齐。

---

## 红线

1. **首次浏览代码前必须先同步远程。** 是 git 仓库就先 `git pull`；**不是 git 仓库则跳过**，不报错、不强行 init。
2. **不强拉、不丢改动。** 本地有未提交改动或 pull 冲突时，**停下来交给用户**，不 `git reset --hard`、不 `git checkout -- .`、不 `--force`。
3. **不基于过期记忆下断言。** 记忆与代码不一致时以代码为准；拿不准的标「待确认」，不假装理解。
4. **不改业务代码。** 同步与对齐阶段不写代码。

---

## 执行流程

### 第 0 步：同步远程仓库（第一优先级）

进入项目、准备读/改代码前**第一件事**。先判断是不是 git 仓库：

```bash
# 是否在 git 工作区内
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_A_GIT_REPO"
```

```powershell
# Windows PowerShell
git rev-parse --is-inside-work-tree 2>$null; if ($LASTEXITCODE -ne 0) { "NOT_A_GIT_REPO" }
```

- **不是 git 仓库** → 跳过同步，记一句「无远程仓库，跳过同步」，直接进第 1 步。
- **是 git 仓库** → 先看工作区是否干净，再决定怎么拉：

```bash
git status --porcelain          # 有输出=有未提交改动
git rev-parse --abbrev-ref HEAD # 当前分支
```

```text
工作区干净 → git pull --ff-only          # 只快进，不产生意外 merge 提交
工作区有改动 / --ff-only 失败 / 有冲突 →
    停下来报告用户：列出本地改动与落后情况，
    让用户决定（先提交、暂存 git stash、还是 rebase），不替用户强拉。
没有 remote（git remote 为空） → 跳过 pull，提示「本地仓库无远程，跳过」
```

> 拉取只为「站在团队最新代码上」，绝不能因此丢掉本地未提交的工作。任何有风险的同步动作都交回用户。

### 第 1 步：加载规则（AGENTS.md）

从当前目录链路自上而下读 `AGENTS.md`：根目录的总规则 + 当前所在子目录的目录级规则。

```bash
ls AGENTS.md ../AGENTS.md ../../AGENTS.md 2>/dev/null
```

没有 AGENTS.md → 提示「该项目尚未接入 AI 协作规范，建议先用 `team-ai-workspace-bootstrap`」，不擅自创建。

### 第 2 步：加载项目理解（docs/ai-memory）

先读**心智模型快照**，它是团队对项目当前理解的单一入口：

```bash
cat docs/ai-memory/overview.md 2>/dev/null
ls -R docs/ai-memory 2>/dev/null
```

再**按本次任务需要**有选择地读：相关 `modules/<模块>.md`、`interface-map.md`、`database-map.md`、`risk-points.md`、近期 `task-log.md`。不要一次全量读完，按任务相关性取。

（向后兼容：只有 `docs/AI开发交接记录.md` 的老项目，读它当 task-log。）

### 第 3 步：形成「当前理解」并确认偏差

把「记忆里写的」与「刚看到的代码」对照，向用户给出一段简短摘要：本次要碰的部分、已知约束/风险、**记忆与代码疑似不一致的点**（标「待确认」）。确认后再动手。

---

## 最终反馈格式

```text
## 上下文同步结果

### 1. 远程同步
- 是否 git 仓库：是 / 否（跳过）
- 当前分支 / 拉取结果：已快进到 xxx / 工作区有改动已交用户决定 / 无远程跳过

### 2. 已加载规则
- 根 AGENTS.md：是 / 否；目录级 AGENTS.md：xxx / 无

### 3. 已加载记忆
- overview.md：是 / 否
- 另读了：modules/xxx、database-map…… / 无

### 4. 当前理解摘要
- 本次涉及：……
- 已知约束 / 风险：……
- 记忆与代码疑似不一致（待确认）：…… / 无
```

---

## 开工声明（必须可见，缺了 = 没跑流程）

上面的反馈**不是可选项**。每次任务开工的**第一条回复**必须包含一段简短「开工声明」，最简 2-3 行即可：

```text
开工声明：远程同步——已 pull 快进 / 跳过（工作区有待提交改动/无仓库/无 remote）；
记忆加载——docs/ai-memory 存在，已读 overview + xxx / 本项目无 ai-memory 骨架。
```

为什么必须可见：**流程合规和巧合合规的区别，只有靠可见产物才能分辨。** 「查了 git status 但动机是看改动」和「按流程跑了第 0 步」结果可能一样，但前者换个场景就会漏。声明缺失，用户一眼就能发现偏离——这是本 Skill 对使用者的可核查承诺。即使在没有加载本 Skill 全文的降级场景（只有全局摘要），这几行声明也必须输出。

---

## 与 ai-handoff-doc-update 的闭环

```text
开工：project-context-sync（读：同步远程 + 加载记忆 + 对齐理解）
  ↓ 干活
收尾：ai-handoff-doc-update（写：把新理解沉淀回 docs/ai-memory）
  ↓ 提交
git-commit-guard（检查 + commit，push 需确认）
```

读—写闭环合上后，团队每个人的 AI 都从同一份共享理解出发、又把增量写回同一处，理解会持续收敛而不是各自漂移。

---

## 常见坑

### 坑 1：不 pull 就开干
在落后的本地代码上分析、改动，团队协作时会基于过时实现下结论。第 0 步必须先同步。

### 坑 2：为了 pull 干净而丢本地改动
`git reset --hard` / `checkout -- .` 会抹掉未提交工作。红线禁止，遇到 dirty/冲突一律交用户。

### 坑 3：把过期 overview 当圣经
记忆反映写入时的事实。和代码冲突时以代码为准，并标注让收尾时订正。

### 坑 4：一次性把整个 ai-memory 读完
浪费上下文。按本次任务相关性选读，overview 先行，明细按需。

### 坑 5：巧合合规
查了 `git status` 但动机是"看看别人改了什么"，结果碰巧符合"有改动不强拉"的规则——这不是走了流程，是运气。证据是没有输出开工声明、没顺手确认 ai-memory 骨架。换个干净工作区的场景就会漏掉 pull。**流程必须以可见声明落地，不能依赖任务动作顺便覆盖。**
