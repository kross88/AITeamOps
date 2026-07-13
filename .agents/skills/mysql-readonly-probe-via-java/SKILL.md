---
name: mysql-readonly-probe-via-java
description: 在没有数据库客户端的机器上，用 JDK + 项目里现成的 JDBC 驱动 jar 做只读探测。当用户说「这台机器没装 mysql，帮我看下这张表结构」「确认下数据库连的是哪个库」「线上库结构帮我探一下」，或需在无客户端、不能装依赖的环境确认连通性、版本、表结构、字段、样例数据时使用。写 SQL 前/改完涉及库字段的接口后，能连库就主动 SELECT 采样核验字段真实类型与存储格式（逗号分隔 vs JSON、字典值域、日期格式），别靠猜。不限 MySQL：PG 系/人大金仓 KingbaseES 按正文「方言适配」选驱动与探测 SQL，库类型决定探法。仅允许 SELECT/SHOW/DESCRIBE/EXPLAIN 只读查询，绝不写库；用户明确授权写库时切换到 mysql-guarded-write。
---

# MySQL 只读探测（无客户端 / Java JDBC 方案）

本 Skill 用于在目标机器没有 `mysql` / `mysqlsh` 客户端、Python 也没有 MySQL 驱动，但存在 JDK 和项目 Maven 仓库里的 `mysql-connector-java` jar 时，通过 Java JDBC 做 MySQL 只读探测。

本 Skill 只用于只读排查，不用于写库、改表、初始化数据或生产变更。

---

## 1. 红线（最高优先级）

只允许只读查询：

```sql
SELECT ...
SHOW ...
DESCRIBE ...
DESC ...
EXPLAIN ...
SELECT ... FROM information_schema...
```

绝对禁止执行：

```sql
INSERT ...
UPDATE ...
DELETE ...
CREATE ...
ALTER ...
DROP ...
TRUNCATE ...
GRANT ...
REVOKE ...
REPLACE ...
MERGE ...
CALL ...
LOCK ...
UNLOCK ...
SET GLOBAL ...
SET PERSIST ...
```

即便以 `SELECT` 开头，下列「读语句但有副作用」同样禁止：

```sql
SELECT ... INTO OUTFILE ...      -- 写文件到服务器磁盘
SELECT ... INTO DUMPFILE ...     -- 写文件到服务器磁盘
SELECT ... FOR UPDATE            -- 加行锁
SELECT ... LOCK IN SHARE MODE    -- 加共享锁
select 1; drop table t;          -- 分号堆叠的多语句一律禁止
```

任何可能修改数据、结构、权限、会话外状态或产生副作用的 SQL 都禁止执行。

如果用户需要写库：

1. 不要在本 Skill 内执行——本 Skill 的「绝不写库」没有例外。
2. 默认路径：把 SQL 写给用户，说明风险、备份建议、影响范围和回滚建议，由用户亲自执行。
3. 用户**明确授权代为执行**时：切换到 `mysql-guarded-write`，按它的红线走（表白名单、逐条预检报告、备份可回滚、禁项不碰）。切换是显式的，不是在探测里顺手写一条。

---

## 2. 适用场景

使用本 Skill 的典型场景：

- 服务器没有 `mysql` 命令。
- 服务器没有 `mysqlsh`。
- Python 没有 MySQL 驱动。
- 不能安装新依赖。
- 机器上有 JDK。
- Java 项目或 Maven 仓库里已有 `mysql-connector-java` jar。
- 只需要确认数据库连通性、版本、当前库、表结构、字段、少量样例数据。

**应当主动使用的场景（不等用户开口）**——只要环境能连库：

- **写 SQL 前**：先探测真实表结构、数据库版本方言（如 MySQL 5.7 的语法限制）、菜单/字典等系统表的实际字段，不凭空假设。
- **写完/改完涉及数据库字段的接口后**：SELECT 采样核验代码假设与真实数据一致——
  ```text
  字段真实类型      DO 里的 String/Long 与列类型是否匹配（如用户 ID 是 varchar 还是 bigint）
  数据存储格式      逗号分隔 vs JSON 数组 vs 单值（决定 LIKE 还是 FIND_IN_SET 还是 JSON_CONTAINS）
  字典/枚举值域     代码里的枚举值与库里实际出现的值是否一致
  日期格式          datetime vs date vs varchar 存日期
  空值与默认值      NULL 分布是否会击穿代码里的假设
  ```
  接口"看起来对"但字段格式假设错了，是最常见的隐性 bug 来源。

不要用于：

- 数据修复。
- 表结构变更。
- 批量更新。
- 初始化数据。
- 删除数据。
- 权限变更。
- 生产写操作。

---

## 3. 第 0 步：先确认连的是哪个库

Spring Boot 多 profile 场景必须先确认最终生效的数据源。

注意：

```text
application.yml
application-dev.yml
application-prod.yml
application-test.yml
```

如果激活了 profile，例如：

```yaml
spring:
  profiles:
    active: dev
```

或者启动参数中存在：

```text
--spring.profiles.active=dev
```

则 `application-dev.yml` 会覆盖 `application.yml` 中同名配置。

尤其是两份文件都写了：

```yaml
spring:
  datasource:
    url:
```

以激活 profile 的配置为准。

必须确认：

```text
1. 当前激活 profile
2. 最终 spring.datasource.url
3. 最终 spring.datasource.username
4. 最终 spring.datasource.password
5. 是否有动态数据源、多数据源、环境变量覆盖
```

不能只看 `application.yml` 就断定连接的是哪个库。

---

## 4. 执行步骤

### 4.1 检查网络可达性

Windows PowerShell：

```powershell
Test-NetConnection -ComputerName <host> -Port 3306
```

重点看：

```text
TcpTestSucceeded : True
```

Linux：

```bash
nc -vz <host> 3306
```

如果没有 `nc`，可用：

```bash
timeout 3 bash -c "</dev/tcp/<host>/3306"
```

**连不上时，先判症状再下结论（真实事故教训）：**

```text
秒拒（connection refused / RST）→ 主机可达但端口没开：目标侧问题（服务没起/端口错）
挂死超时（静默无响应几十秒+）  → 路上有东西丢包：首要嫌疑是【自己的运行环境】
                                 （AI 工具的网络沙箱、代理、出口防火墙），不是目标
```

下「网络不可达」结论前，必须做完三步廉价判别：

1. **问用户**：「你本机能连这个库吗？」——零成本，往往一句话解开死结。
2. **对照测试**：同环境试其他主机/端口。「有的通、有的挂死」= 策略性过滤，自己环境嫌疑更大。
3. **排除自身沙箱**：声明原因后关沙箱（或换无沙箱通道）重测同一地址。

三步没做完，**不许下"不可达"结论，更不许基于它转昂贵旁路**（比如让用户上服务器手动跑脚本）。真实案例：工具沙箱对 DB 端口静默丢包，挂死 2 分钟被误诊为"内网防火墙不可达"，差点绕道服务器——用户一句"我本地能连"才回到正轨。

---

### 4.2 找到 mysql-connector-java jar

优先从项目或 Maven 仓库查找。

Windows PowerShell：

```powershell
Get-ChildItem -Path "$env:USERPROFILE\.m2\repository" -Recurse -Filter "mysql-connector*.jar" | Select-Object -First 10 FullName
```

也可以在项目目录查找：

```powershell
Get-ChildItem -Path "." -Recurse -Filter "mysql-connector*.jar" | Select-Object -First 10 FullName
```

Linux / macOS：

```bash
find ~/.m2/repository -name "mysql-connector*.jar" | head
find . -name "mysql-connector*.jar" | head
```

常见 jar：

```text
mysql-connector-java-5.1.x.jar
mysql-connector-j-8.x.x.jar
```

---

### 4.3 判定数据库类型与方言适配（不限 MySQL，类型决定探法）

**先判库型**——三个线索：datasource URL 前缀、依赖里的驱动、业务 SQL 语法特征（`decode/to_char/::numeric/chr()` = PG 系，别当 MySQL 硬套）。库类型决定驱动、URL、探测 SQL、大表估算，全套跟着换：

| | MySQL | KingbaseES（人大金仓，PG 兼容内核） | PostgreSQL |
|---|---|---|---|
| 驱动类 | `com.mysql.cj.jdbc.Driver`（5.1: `com.mysql.jdbc.Driver`） | `com.kingbase8.Driver` | `org.postgresql.Driver` |
| URL | `jdbc:mysql://h:3306/db?...` | `jdbc:kingbase8://h:port/db?currentSchema=xxx` | `jdbc:postgresql://h:5432/db?currentSchema=xxx` |
| 标识符引号 | 反引号 `` `t` `` | 双引号 `"t"`（大小写敏感时必须带） | 双引号 `"t"` |
| 看表结构 | `SHOW CREATE TABLE` / `DESCRIBE` | `information_schema.columns` / `\d` 系 | 同金仓 |
| 大表行数估算 | `information_schema.tables.table_rows` | `pg_class.reltuples` | `pg_class.reltuples` |

- 金仓是 PG 兼容内核：优先用项目 `.m2` 里现成的 `kingbase8` jar；没有时标准 `postgresql` 驱动大概率也能连同一端口。
- PG 系注意 **schema**：URL 带 `currentSchema=`，或表名全限定 `schema."table"`。
- **只读白名单红线对所有方言一视同仁**——换库型不换红线。

**大表探测要点**（千万行级 `count(*)` 会超时甚至断连——真实场景 7000 万行表）：

```text
1. 先估算后精确：MySQL 用 table_rows、PG 系用 reltuples 拿量级；确需精确才 count，
   且尽量数索引列 / 带索引条件。
2. 批量探测多张表：每张表用独立连接（或断连重试），一张大表把连接拖死不至于毁掉整批。
3. JDBC 加 socketTimeout / loginTimeout，别让一条查询挂住全场。
```

---

## 5. Java 探测骨架

### 5.1 MySQL Connector/J 5.1.x

```java
import java.sql.*;

public class DbCheck {
  public static void main(String[] args) throws Exception {
    String url = "jdbc:mysql://HOST:3306/DB?characterEncoding=utf-8&useSSL=false&serverTimezone=GMT%2B8";
    String user = "USER";
    String password = "PWD";

    Class.forName("com.mysql.jdbc.Driver");

    try (Connection c = DriverManager.getConnection(url, user, password);
         Statement s = c.createStatement();
         ResultSet r = s.executeQuery("SELECT VERSION()")) {
      if (r.next()) {
        System.out.println("MySQL 版本：" + r.getString(1));
      }
    }
  }
}
```

### 5.2 MySQL Connector/J 8.x

```java
import java.sql.*;

public class DbCheck {
  public static void main(String[] args) throws Exception {
    String url = "jdbc:mysql://HOST:3306/DB?characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai";
    String user = "USER";
    String password = "PWD";

    Class.forName("com.mysql.cj.jdbc.Driver");

    try (Connection c = DriverManager.getConnection(url, user, password);
         Statement s = c.createStatement();
         ResultSet r = s.executeQuery("SELECT VERSION()")) {
      if (r.next()) {
        System.out.println("MySQL 版本：" + r.getString(1));
      }
    }
  }
}
```

---

## 6. 写入临时 Java 文件

不要把探测源码写进项目目录。

Windows PowerShell：

```powershell
$dir = Join-Path $env:TEMP "dbcheck"
New-Item -ItemType Directory -Force $dir
```

用无 BOM UTF-8 写文件，避免 `javac` 报 `illegal character: '\ufeff'`：

```powershell
$path = Join-Path $dir "DbCheck.java"
[System.IO.File]::WriteAllText($path, $java, New-Object System.Text.UTF8Encoding($false))
```

Linux / macOS：

```bash
dir="/tmp/dbcheck"
mkdir -p "$dir"
```

---

## 7. 编译和运行

Windows PowerShell：

```powershell
$javac = "C:\Program Files\Java\jdk1.8.0_xxx\bin\javac.exe"
$javaExe = "C:\Program Files\Java\jdk1.8.0_xxx\bin\java.exe"
$jar = "C:\Users\Administrator\.m2\repository\mysql\mysql-connector-java\5.1.xx\mysql-connector-java-5.1.xx.jar"
$dir = Join-Path $env:TEMP "dbcheck"

& $javac "$dir\DbCheck.java"
& $javaExe -cp "$jar;$dir" DbCheck
```

Linux / macOS：

```bash
javac /tmp/dbcheck/DbCheck.java
java -cp "/path/to/mysql-connector-java.jar:/tmp/dbcheck" DbCheck
```

注意 classpath 分隔符：

```text
Windows：;
Linux / macOS：:
```

---

## 8. 只读 SQL 白名单示例

允许执行：

```sql
SELECT VERSION();
SELECT DATABASE();
SHOW TABLES;
SHOW FULL TABLES;
DESCRIBE table_name;
SHOW COLUMNS FROM table_name;
SHOW INDEX FROM table_name;
EXPLAIN SELECT * FROM table_name WHERE id = 1;
SELECT COUNT(*) FROM table_name;
SELECT * FROM table_name LIMIT 5;
SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE();
```

查询业务表时必须加限制：

```sql
SELECT * FROM table_name LIMIT 10;
```

不要无条件查询大表全量数据。

---

## 9. 推荐的只读探测代码结构

需要执行多个 SQL 时，必须先做只读白名单检查。

```java
import java.sql.*;
import java.util.*;

public class DbCheck {
  private static final List<String> SQLS = Arrays.asList(
      "SELECT VERSION()",
      "SELECT DATABASE()",
      "SHOW TABLES"
  );

  public static void main(String[] args) throws Exception {
    String url = "jdbc:mysql://HOST:3306/DB?characterEncoding=utf-8&useSSL=false&serverTimezone=GMT%2B8";
    String user = "USER";
    String password = "PWD";

    Class.forName("com.mysql.jdbc.Driver");

    try (Connection c = DriverManager.getConnection(url, user, password);
         Statement s = c.createStatement()) {
      c.setReadOnly(true);

      for (String sql : SQLS) {
        assertReadOnly(sql);
        System.out.println("SQL> " + sql);
        try (ResultSet rs = s.executeQuery(sql)) {
          printResult(rs, 20);
        }
      }
    }
  }

  private static void assertReadOnly(String sql) {
    String x = sql.trim().toLowerCase(Locale.ROOT);

    // 1) 只允许这些只读语句开头。insert/update/delete/drop... 等写操作
    //    只能出现在语句开头，这里直接挡住，无需再对全文做子串匹配
    //    （旧版用 contains("update ") 之类会误伤字符串字面量，如 WHERE note='please update '）。
    boolean okHead = x.startsWith("select") || x.startsWith("show")
        || x.startsWith("describe") || x.startsWith("desc") || x.startsWith("explain");
    if (!okHead) {
      throw new IllegalArgumentException("禁止执行非只读 SQL：" + sql);
    }

    // 2) 禁止堆叠多条语句（如 "select 1; drop table t"）。
    //    去掉末尾可有的一个分号后，正文里不应再出现分号。
    String body = x.endsWith(";") ? x.substring(0, x.length() - 1) : x;
    if (body.contains(";")) {
      throw new IllegalArgumentException("禁止一次执行多条 SQL：" + sql);
    }

    // 3) 即便以 select 开头，也禁止带副作用的子句：写磁盘、加锁。
    String[] bannedFragments = {
        "into outfile", "into dumpfile",   // 写文件到服务器磁盘
        " for update", "lock in share"     // 行锁
    };
    for (String b : bannedFragments) {
      if (x.contains(b)) {
        throw new IllegalArgumentException("禁止执行带副作用的 SQL：" + sql);
      }
    }
  }

  private static void printResult(ResultSet rs, int limit) throws Exception {
    ResultSetMetaData md = rs.getMetaData();
    int cols = md.getColumnCount();

    for (int i = 1; i <= cols; i++) {
      if (i > 1) System.out.print("\t");
      System.out.print(md.getColumnLabel(i));
    }
    System.out.println();

    int count = 0;
    while (rs.next() && count < limit) {
      for (int i = 1; i <= cols; i++) {
        if (i > 1) System.out.print("\t");
        System.out.print(rs.getString(i));
      }
      System.out.println();
      count++;
    }
  }
}
```

---

## 10. 用完清理临时文件

Windows PowerShell：

```powershell
Remove-Item -Recurse -Force "$env:TEMP\dbcheck"
```

Linux / macOS：

```bash
rm -rf /tmp/dbcheck
```

原因：

- Java 源码里可能包含明文数据库地址、用户名、密码。
- `.class` 文件也不应长期保留。
- 临时探测代码不应进入项目 Git 仓库。

**交给用户手动执行的脚本同样适用**：凡生成让用户拿到服务器/别的机器上跑的探测脚本，**脚本末尾必须自带清理命令**（`rm -rf` 临时目录），或至少在交付时显式提醒"跑完删掉"——脚本源码里有明文密码，不能只在自己执行时才记得清理（真实案例：一份服务器探测脚本把密码写进 /tmp 却没带清理段）。

---

## 11. 常见坑

### 坑 1：PowerShell 写 Java 文件带 BOM

现象：

```text
illegal character: '\ufeff'
```

解决：

```powershell
[System.IO.File]::WriteAllText($path, $java, New-Object System.Text.UTF8Encoding($false))
```

### 坑 2：驱动类名不匹配

Connector/J 5.1.x：

```java
Class.forName("com.mysql.jdbc.Driver");
```

Connector/J 8.x：

```java
Class.forName("com.mysql.cj.jdbc.Driver");
```

### 坑 3：Classpath 分隔符错误

Windows：

```text
;
```

Linux / macOS：

```text
:
```

### 坑 4：连错数据库

必须确认 Spring Boot 激活 profile。

不要只看 `application.yml`。

多 profile 时，同名 key 以激活 profile 文件为准。

### 坑 5：SQL 不是只读

即使用户说“帮我执行一下 update”，也不能执行。

只能把 SQL 写给用户，由用户手动执行。

### 坑 6：把「自己沙箱丢包」误诊为「目标不可达」

连接挂死超时 ≠ 目标网络不可达——静默丢包的首要嫌疑是自己工具的网络沙箱/代理。按 4.1 的三步判别（问用户 / 对照测试 / 关沙箱重测）做完再下结论，别急着转服务器旁路。

### 坑 7：对千万行大表直接 count(*)

会超时、甚至拖断整个连接毁掉批量探测。按 4.3 大表要点：先 reltuples/table_rows 估算，批量时每表独立连接。

### 坑 8：Git Bash 下 classpath 被 MSYS 转义毁掉

Windows Git Bash 会把 `-cp` 里的 `;` 和 `/c/...` 路径做 POSIX 转换，报"找不到驱动类"。用 Windows 原生路径 + 禁用转换（`MSYS_NO_PATHCONV=1` / `MSYS2_ARG_CONV_EXCL="*"`），或干脆在 PowerShell/cmd 里跑 java 命令。

---

## 12. 最终反馈格式

使用本 Skill 后，必须反馈：

```text
## MySQL 只读探测结果

### 1. 最终确认的数据源

- host：
- port：
- database：
- profile 来源：
- 配置文件：

### 2. 网络连通性

- 结果：

### 3. 使用的 JDBC jar

- 路径：
- 版本：

### 4. 执行的只读 SQL

- ...

### 5. 查询结果摘要

- ...

### 6. 清理情况

- 临时 Java 文件：
- class 文件：
- 是否已删除：

### 7. 风险说明

- 本次未执行任何写库 SQL。
- 如需写库，已提供 SQL 给用户手动执行。
```
