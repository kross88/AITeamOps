---
name: git-commit-guard
description: 当用户说「帮我提交代码」「commit 一下」「把这次改动提交了」「提交并推送」时使用。本 Skill 会先检查本次改动、再构建并测试项目，全部通过后才生成并执行 git commit；push 默认需要用户显式确认。适用于前后端多模块项目（Maven/Gradle + npm/pnpm）。本 Skill 不替用户判断业务逻辑是否正确，只保证「检查关卡全绿才提交」。
---

# Git Commit Guard

帮用户安全地提交代码：提交前自动跑一遍检查关卡（diff 审查 → 构建 → 测试），全绿才 commit，把"随手提交"变成"过闸提交"。

## 最重要的认知边界

- **构建/测试通过 ≠ 没有 bug。** 它只能证明能编译、能跑、已有测试没挂，证明不了业务逻辑对。反馈给用户时不要说"已确认无 bug"，要说"检查关卡已通过"。
- **本 Skill 不替用户判断业务正确性。** 涉及业务逻辑的失败，停下来交给用户，不自行猜测意图改代码。
- **push 是不可逆的对外动作。** 默认只 commit，不自动 push；push 必须用户显式确认。

---

## 红线

1. **不自动 push。** 除非用户在本次对话里明确说"推送"/"push"/"确认推送"，否则只 commit 到本地。
2. **检查不过不提交。** 构建失败、测试失败、或发现疑似敏感信息，一律中止，不得 `--no-verify` 强提交。
3. **自动修复有封顶。** 最多 2 轮，且只修机械错误（见第 4 节）。超限或属于业务逻辑错误，停下来报给用户。
4. **不提交可疑文件。** 提交前扫描 diff，发现疑似密钥/密码/`.env`/大二进制文件，中止并提示用户。

---

## 执行流程

### 第 1 步：确认有改动可提交

```bash
git status --porcelain
git diff --stat
```

- 无改动 → 告诉用户"没有可提交的改动"，结束。
- 有改动 → 继续。

### 第 2 步：审查本次 diff（提交前自检）

> ⚠️ **关键：先暂存再扫描。** 必须先 `git add -A` 把**所有改动（含新建的未跟踪文件）**纳入暂存，再用 `git diff --staged` 审查。否则新建文件（`.env`、`credentials.json`、`id_rsa`、`application-prod.yml` 等最易夹带密钥的文件）既不在 `git diff` 里，也不在尚未暂存的 `git diff --staged` 里，会**完全绕过本次扫描**却被第 6 步的 `git add -A` 提交进去。暂存是可逆的，扫描出问题随时能 `git reset`。

```bash
git add -A          # 先全量暂存：新建/修改/删除都纳入，扫描才不漏未跟踪文件
git diff --staged   # 审查全部待提交改动（已含新建文件内容）
```

```powershell
# Windows PowerShell
git add -A
git diff --staged
```

逐项检查，发现以下任一情况 **中止并报告用户**：

```text
- 疑似密钥/令牌：AKIA、password=、secret、token、-----BEGIN ... PRIVATE KEY-----
- 配置文件：.env、application-prod.yml 里的明文密码、数据库连接串
- 调试残留：console.log 大量堆积、System.out.println 临时打印、TODO/FIXME 标记的未完成代码
- 大文件 / 二进制：误加的 jar、zip、图片、node_modules、target、dist
- 与本次功能无关的大范围改动
```

敏感信息扫描参考命令（在 `git add -A` 之后执行，确保覆盖新建文件）：

```bash
git diff --staged | grep -nEi '(password|secret|api[_-]?key|token|AKIA|BEGIN .*PRIVATE KEY)' || echo "未发现明显敏感串"
```

```powershell
# Windows PowerShell（无 grep 时用 Select-String）
git diff --staged | Select-String -Pattern 'password|secret|api[_-]?key|token|AKIA|BEGIN .*PRIVATE KEY'
```

> 若扫描命中，先 `git reset` 撤销暂存，处理掉敏感内容（删除文件 / 移入 `.gitignore` / 改用环境变量）后再重来，**不要带着可疑内容继续**。

### 第 3 步：探测项目结构

多模块项目要逐个找构建入口：

```bash
# 后端
find . -maxdepth 3 -name "pom.xml" -not -path "*/target/*"
find . -maxdepth 3 -name "build.gradle*" -not -path "*/build/*"
# 前端
find . -maxdepth 3 -name "package.json" -not -path "*/node_modules/*"
```

```powershell
# Windows PowerShell（无 find 时用 Get-ChildItem）
# 后端
Get-ChildItem -Recurse -Depth 3 -Filter pom.xml          | Where-Object FullName -notmatch '\\target\\'
Get-ChildItem -Recurse -Depth 3 -Filter build.gradle*    | Where-Object FullName -notmatch '\\build\\'
# 前端
Get-ChildItem -Recurse -Depth 3 -Filter package.json     | Where-Object FullName -notmatch '\\node_modules\\'
```

按找到的入口决定下一步跑哪些构建命令。

### 第 4 步：构建 + 测试（核心关卡）

对每个模块跑「构建 + 测试」，**任意一个不过 → 整体不过**。

**后端 Maven：**

```bash
mvn -q -B clean test    # 编译 + 单测
# 或只验证可构建（无测试或测试慢时）：mvn -q -B clean compile
```

**后端 Gradle：**

```bash
./gradlew test --console=plain
# 或：./gradlew build -x test  （仅构建，跳过测试）
```

**前端 npm / pnpm：**

```bash
# 先看 package.json 里有哪些 script
npm run build --if-present
npm test --if-present -- --watchAll=false   # CI 模式，跑完即退
# pnpm 同理：pnpm build / pnpm test
```

> 注意：前端测试默认可能进入 watch 模式卡住，必须用 CI/单次模式（如 `--watchAll=false`、`CI=true`）。

记录每个模块的结果（通过 / 失败 + 关键错误行）。

### 第 5 步：处理失败（自动修复，封顶 2 轮）

失败时按这个判断：

```text
是不是机械错误？（缺 import、未用变量、格式、明显的编译期类型不匹配、漏分号、依赖未引入）
├─ 是 → 自动修复一处，回到第 4 步重跑。已修复轮数 +1。
│        若已达 2 轮仍不过 → 停止，把错误原文 + 已尝试的修复报给用户。
└─ 否（涉及业务逻辑、测试断言失败、行为不符预期）
         → 立即停止，不要猜业务意图去改。把失败的测试/错误报给用户，请用户决策。
```

**绝不**为了让构建通过而删除/注释失败的测试、跳过测试、改断言来迁就实现。

### 第 6 步：生成并执行 commit

检查全绿后，生成符合规范的提交信息再执行。第 2 步已 `git add -A` 暂存过，这里再 `git add -A` 一次，是为了把第 5 步自动修复期间产生的改动一并纳入：

```bash
git add -A          # 补入第 5 步自动修复的改动（第 2 步已扫描过的内容不会引入新风险）
git commit -m "<type>: <本次功能简述>"
```

提交信息规范（type 取其一）：

```text
feat:     新功能
fix:      修复 bug
refactor: 重构（不改外部行为）
docs:     文档
chore:    构建/依赖/杂项
test:     测试
```

`<本次功能简述>` 根据实际 diff 概括，用中文，一句话说清这次做了什么。例如：

```bash
git commit -m "feat: 新增拼单客户物流分段展示"
git commit -m "fix: 修复入库单登记重复提交问题"
```

> 不要用空泛的 "update code" / "修改若干"。提交信息要能让人一眼看懂这次改了什么。

### 第 7 步：push（需用户显式确认）

**默认到第 6 步为止。** 只有用户在对话里明确表达了推送意图（"推送"/"push"/"提交并推送"/"确认推送"），才执行：

```bash
git rev-parse --abbrev-ref HEAD     # 确认当前分支
git push origin <当前分支>
```

push 前再确认一次当前分支对不对，避免推错分支。

---

## 最终反馈格式

完成后按此格式反馈用户：

```text
## 提交检查结果

### 1. 本次改动
- 文件数：
- 关键改动：

### 2. diff 自检
- 敏感信息扫描：通过 / 发现 xxx（已中止）
- 可疑文件：无 / xxx

### 3. 构建测试
- 后端（模块名）：通过 / 失败（错误摘要）
- 前端（模块名）：通过 / 失败（错误摘要）
- 自动修复轮数：0 / 1 / 2

### 4. 提交
- 是否已 commit：是 / 否（原因）
- 提交信息：
- commit hash：

### 5. 推送
- 是否已 push：是 / 否（默认不 push，需确认）
- 目标分支：

### 6. 说明
- 检查关卡已通过，但这不等于业务逻辑无 bug，请自行验收。
```

---

## 常见坑

### 坑 1：前端测试卡在 watch 模式
`npm test` 默认进入交互式 watch，会挂住。必须用 CI 模式：`CI=true npm test` 或 `-- --watchAll=false`。

### 坑 2：把"构建通过"当成"没 bug"
构建只覆盖编译期和已有测试。逻辑 bug、缺测试覆盖的路径，构建照样绿。反馈务必如实。

### 坑 3：为了过测试而改测试
失败的测试是信号，不是障碍。删测试/改断言来"修复"是自欺，红线禁止。

### 坑 4：自动修复死循环
不封顶会越改越乱。机械错误最多 2 轮，业务错误 0 轮（直接交人）。

### 坑 5：推错分支
多人协作时容易在错误分支上 commit/push。push 前必查当前分支。

### 坑 6：误提交敏感信息
一旦 push 到公网，密钥即使删除也已泄露（要走轮换流程）。所以第 2 步的扫描在 commit 前做，push 又加一道人工确认。

### 坑 7：扫描漏掉新建的未跟踪文件
最隐蔽的一种。`git diff` 只看已跟踪文件，新建的 `.env`/密钥文件不在其中；若扫描在 `git add` 之前做，等于没扫到它们，却会被第 6 步 `git add -A` 提交。所以第 2 步必须**先 `git add -A` 再扫 `git diff --staged`**，让新建文件进入扫描范围。
