---
name: multi-tool-entrypoint-sync
description: 让同一个项目在多个 AI 工具（Codex、Claude Code、Cursor、GitHub Copilot、Gemini CLI、Windsurf、Cline 等）下行为一致时使用。当用户说「让 Codex/Claude/Cursor 读同一套规则」「多个模型行为不一致」「配置各工具的规则文件」「同步 AI 入口文件」，或一个人/一个团队在同一项目里用了不止一个 AI 编程工具时，都应使用本 Skill。做法：以根目录 AGENTS.md 为唯一真源，为每个工具生成一个「薄入口文件」，全部指回 AGENTS.md，而不是把规则复制多份。
---

# Multi-Tool Entrypoint Sync（多工具统一入口）

解决「一个人用多个模型、或一个团队用不同工具开发同一项目，结果各模型行为不一致」的根因：**不同工具默认读不同的入口文件，单一一份 AGENTS.md 并不会被所有工具自动读取。**

本 Skill 让 `AGENTS.md` 当**唯一真源**，再为每个工具生成一个**只含指针**的入口文件——指回 AGENTS.md。改规则永远只改 AGENTS.md，重新同步即可，所有工具同时生效。

## 最重要的认知边界

- **各工具的入口文件不同**（见下表），所以要「一源多入口」，不是「一份规则复制 N 遍」。
- **入口文件里不放规则正文，只放指针。** 复制规则正文 = 多份副本，必然漂移。真源永远是 AGENTS.md。
- **`SKILL.md` 不是所有工具都会自动加载。** 默认先通过 onboarding 把 Skills 安装到用户级 `~/.agents/skills/`；项目需要固定版本时才 vendoring 到 `.agents/skills/`。让各工具先读到 AGENTS.md，才能按这条路由找到适用 Skill。

---

## 工具 → 入口文件 映射

| 工具 | 入口文件 | 说明 |
|---|---|---|
| OpenAI Codex | `AGENTS.md` | **真源本身**，无需适配 |
| Claude Code | `CLAUDE.md` | 内容精确为 `@AGENTS.md`，直接导入真源 |
| Cursor | `.cursor/rules/aiteamops.mdc` | MDC 规则，`alwaysApply: true` |
| GitHub Copilot | `.github/copilot-instructions.md` | Copilot Chat 自动注入 |
| Gemini CLI | `GEMINI.md` | 启动读取 |
| Windsurf | `.windsurfrules` | 启动读取 |
| Cline | `.clinerules` | 启动读取 |

> 工具与文件名会随版本变化，以各工具官方文档为准。新增工具只需在本表加一行、按同样模式加一个指针文件。

---

## 红线

1. **AGENTS.md 是唯一真源。** 规则正文只写在 AGENTS.md，入口文件一律只放指针。
2. **不复制规则正文到入口文件。** 否则多份副本漂移，违背本 Skill 初衷。
3. **不覆盖用户手写的入口文件。** Claude 入口仅在内容精确为 `@AGENTS.md` 或带旧版 `AITEAMOPS-GENERATED` 标记时视为托管；其它入口依靠生成标记识别。无法证明是本工具生成的就整批停止，不直接覆盖。
4. **不替用户决定启用哪些工具。** 工具清单必填、非空且全部合法；省略、空列表或含未知工具时，在任何写入前整批失败。
5. **批量生成要么全部成功，要么回滚。** 写入前预检全部目标；任一手写冲突、路径冲突或运行时写入失败时，不留下部分入口。

---

## 执行流程

### 第 1 步：确认真源存在

根目录要有 `AGENTS.md`。没有 → 先用 `team-ai-workspace-bootstrap` 建，再回来。

### 第 2 步：确认要生成哪些工具入口

问用户团队实际在用哪些（Codex / Claude / Cursor / Copilot / Gemini / Windsurf / Cline），只为这些生成，不全量铺开。Codex 直接读取根 `AGENTS.md`，无需额外生成入口。

### 第 3 步：生成各工具入口文件

每个入口文件只含指向 AGENTS.md 的指针；除 Claude 使用精确内容 `@AGENTS.md` 外，其它入口带 `AITEAMOPS-GENERATED` 标记。可用脚本批量生成：

```powershell
# Windows，详见 scripts/sync-tool-entrypoints.ps1
.\scripts\sync-tool-entrypoints.ps1 -ProjectRoot "D:\WorkCode\YourProject" -Tools claude,cursor,copilot,gemini
```

`-Tools` 不可省略。脚本先一次性校验全部工具名、目标路径、手写文件冲突和父目录可创建性，再开始写；预检失败零写入，意外文件系统错误则恢复旧内容并删除本轮新建文件/空目录。本轮不自动删除以前生成但这次未选择的入口，清理旧入口需要用户另行明确确认。

手动生成时用下面的模板。

### 第 4 步：校验

确认：每个入口文件都指向 AGENTS.md；Claude 内容精确为 `@AGENTS.md`，其它入口带生成标记；没有任何规则正文被复制进去。

---

## 入口文件模板（只放指针）

**通用指针正文**（除 Claude/Cursor 有各自格式外，其余直接用这段）：

```markdown
<!-- AITEAMOPS-GENERATED 由 multi-tool-entrypoint-sync 生成，请勿手改本文件。 -->
# 本项目 AI 协作规则入口

本项目所有 AI 协作规则、目录路由与红线，以根目录 `AGENTS.md` 为**项目级唯一真源**。
开始前请先完整阅读 `./AGENTS.md`，并按需使用用户级 `~/.agents/skills/`；项目存在 `.agents/skills/` 时优先使用项目固定版本。
若本文件与 `AGENTS.md` 不一致，以 `AGENTS.md` 为准。
```

**Claude Code（`CLAUDE.md`，用 import 直接导入真源）：**

```markdown
@AGENTS.md
```

**Cursor（`.cursor/rules/aiteamops.mdc`）：**

```markdown
---
description: AITeamOps 项目规则入口
alwaysApply: true
---

<!-- AITEAMOPS-GENERATED 请勿手改。 -->
本项目规则以根目录 `AGENTS.md` 为项目级唯一真源，请先完整阅读 `./AGENTS.md` 再开始，
并按需使用用户级 `~/.agents/skills/`；项目存在 `.agents/skills/` 时优先使用项目固定版本。
```

---

## 兼容矩阵（同步后应达到的状态）

| 工具 | 会自动读到 AGENTS.md？ | 通过 |
|---|---|---|
| Codex | 是（直接读 AGENTS.md） | ✅ |
| Claude Code | 是（CLAUDE.md `@AGENTS.md`） | ✅ |
| Cursor | 是（.mdc `alwaysApply`） | ✅ |
| Copilot | 是（copilot-instructions 注入） | ✅ |
| Gemini / Windsurf / Cline | 是（各自入口指针） | ✅ |

---

## 常见坑

### 坑 1：把规则正文复制进每个入口文件
最常见错误。短期省事，长期 N 份副本各自漂移。入口只放指针。

### 坑 2：覆盖了用户手写的 CLAUDE.md / 规则文件
用户可能已有定制规则。Claude 只把精确 `@AGENTS.md` 或带旧版生成标记的内容视为托管，其它入口检查 `AITEAMOPS-GENERATED` 标记；无法证明归属时整批停止。

### 坑 3：以为放了入口文件 SKILL.md 就跨工具生效
非 Claude 系工具不一定自动加载 SKILL.md。AGENTS.md 必须明确：默认按需使用用户级 `~/.agents/skills/`，项目存在 `.agents/skills/` 时优先使用项目固定版本；两处都没有则先做 onboarding。

### 坑 4：改了规则忘记重新同步
规则只改 AGENTS.md 后，入口文件不用改（都是指针），但要确认各工具确实重新读取了 AGENTS.md（多数每次会话自动读）。

### 坑 5：省略工具列表就生成全部入口
会把未使用工具的配置文件铺满项目。`-Tools` 必须明确提供；脚本对空值或未知工具整批失败，不做部分生成。
