# 贡献指南 / Contributing

> **English** — Contributions are welcome, especially new Skills. A Skill is a folder under `.agents/skills/<kebab-case-name>/` containing a `SKILL.md` (YAML frontmatter + Markdown body). The `description` decides *when* the Skill triggers; the body decides *what* it does and where the AI must stop and hand back to a human. Keep workflows minimal, boundaries explicit, and never auto-perform irreversible/high-risk actions (push, DB writes, business-logic changes). Steps below are in Chinese; open an Issue if anything is unclear.

欢迎贡献，尤其欢迎新增 **Skill**。本仓库聚焦「AI 协作的可触发流程」，请遵循下面的约定。

## 提交一个 Skill

1. **建目录**：在 `.agents/skills/` 下新建一个 **kebab-case** 命名的文件夹，文件夹名即 Skill 的 `name`。
2. **写 `SKILL.md`**：结构为「YAML frontmatter + Markdown 正文」。
   ```markdown
   ---
   name: your-skill-name
   description: 当用户说「…」「…」时使用。本 Skill 会……。不适用于……。
   ---

   # 标题

   正文：认知边界 / 红线 / 分步流程 / 反馈格式 / 常见坑
   ```
   - **`name`**：与文件夹同名，kebab-case，唯一。
   - **`description`**：决定「何时触发」，是 AI 选用 Skill 的**唯一依据**。要写清适用与不适用场景，并带上用户的口语化触发句。
   - **正文**：决定「触发后怎么做」。建议含：认知边界、红线、分步流程、反馈格式、常见坑。
3. **登记**：在 [README.md](README.md) 的「包含的 Skills」表格里加一行。
4. **跨平台命令**：如果正文给了 shell 命令，Windows 与 Linux/macOS 尽量都给（本仓库主力在 Windows，注意 PowerShell 5.1 的中文需 UTF-8 BOM）。
5. **提交**：按 `git-commit-guard` 的思路——先自检 diff（含未跟踪文件）、再 commit、**push 前确认**。

## 三层分工（别越界）

- **AGENTS.md** 管规则与路由，**Skills** 管执行流程，**docs** 管业务事实。
- 规则不写进 Skill，业务事实不写进 AGENTS.md，任务流水不堆进 AGENTS.md。

## 必须遵守的原则

- **最小流程**：只固化真正可复用的步骤。
- **明确边界**：写清不适用场景，避免误触发。
- **红线优先**：把「何时必须停下来交回给人」写进红线——**push、写库、改业务逻辑、删数据**等不可逆或高风险动作，默认不自动做，交回给人决策。
- **不臆造**：只引用真实存在的 Skill；规划中的标注「规划中」（清单见 [ROADMAP.md](ROADMAP.md)）。

## 编码约定

- 文件统一 **UTF-8**；含中文的 PowerShell 脚本需 **UTF-8 with BOM**（否则 PS 5.1 按 GBK 解析会乱码/报错）。
- 注释与文档用中文，面向国际读者的入口（README 顶部）保留英文摘要。

## Issue / PR

- 有想要的 Skill 或发现问题，欢迎提 Issue。
- PR 请说明：解决什么场景、触发条件是什么、红线在哪。小步提交，提交信息用规范前缀（`feat/fix/refactor/docs/chore/test:`）。
