# Onboarding —— 让你的 AI 学会并永久记住这套规则

> 这份文件是给 **AI 工具/模型** 看的冷启动入口。想让你的 AI 采用 AITeamOps，把这句话发给它即可：
>
> **"读 AITeamOps 仓库的 `.agents/skills/onboard-aiteamops/SKILL.md` 并照着执行，把这套规则接入你的永久记忆。"**
>
> **English** — To make your AI adopt AITeamOps, tell it: *"Read this repo's `.agents/skills/onboard-aiteamops/SKILL.md` and follow it to install AITeamOps into your permanent memory."*

---

## 先讲清楚一件事（重要，别被误导）

**模型本身没有"永久记忆"。** 一个模型读完这个仓库，会话结束就忘了——除非它把规则**写进它所在工具每次会话都会加载的文件**：

| 工具 | "永久记忆"文件 |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | 全局 `AGENTS.md`（如 `~/.codex/AGENTS.md`） |
| Cursor / 其它 | 各自的全局规则文件 |

所以"让你的模型学习这个仓库" **不等于** 它会自动永久记住。真正生效需要一次**安装动作**：把一段精炼的"治理块"写进上面那个文件。`onboard-aiteamops` Skill 就是来做这件事的——而且**写之前会先给你看、等你确认**。

## AI 会做什么（onboard-aiteamops 的流程）

1. **读懂框架**：README → AGENTS.md → 各 SKILL.md。
2. **判定你在用什么工具**、它的永久记忆文件在哪（拿不准会问你）。
3. **拟一段治理块**（三层记忆与记忆纪律 + 首次先 pull + 提交安全 + 固定动作 + 数据库规则 + Skill 触发清单 + 跨项目经验区 + 用户信息区），**给你确认**。
4. **增量写入**那个文件（只加一段，不动你已有规则）。
5. **自检验证**：复述规则、确认 Skill 触发、告诉你写进了哪、怎么回退。

## 手动接入（Windows，可选）

不想让 AI 代劳，也可以自己来：

```powershell
# 1) 安装 Skills 到用户级目录
git clone https://github.com/kross88/AITeamOps.git
cd AITeamOps
.\scripts\install-windows.ps1            # 复制 .agents/skills/* 到 ~/.agents/skills/

# 2) 把仓库根 AGENTS.md 里的「治理块」要点，手动加进你的 ~/.claude/CLAUDE.md（或对应工具的全局文件）
```

## 它实现了什么

接入后，你的 AI 在**所有项目**里都会：
- 首次浏览代码前先同步远程（不在过期代码上瞎改），并输出**开工声明**；
- 把项目事实沉淀到项目 `docs/ai-memory/`、把跨项目通用经验累积到全局文件——**一个微型的、永久累积经验的过程**，任务总结带**收尾沉淀结论**；
- 提交守红线（扫密钥、push 需确认）；交付代码时**声明验证等级**（静态阅读≠编译）；规则冲突时**不沉默选边**；
- 复核另一个 AI 的交付时按**验收级**来（不信总结只信代码，`ai-deliverable-review`）；
- 数据库默认只读，写 SQL 前先探真实表结构，改接口后 SELECT 核验字段格式；写库仅限你明确授权（`mysql-guarded-write`，白名单/预检/可回滚）；
- 团队多人 / 一人多模型时，从同一份共享上下文出发，理解持续收敛。

详见 [README.md](README.md) 与 [ROADMAP.md](ROADMAP.md)。
