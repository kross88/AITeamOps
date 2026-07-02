---
name: mysql-readonly-probe-via-java
description: 在没有 mysql 客户端、Python 也无 MySQL 驱动的机器上，用 JDK + 项目里现成的 mysql-connector-java jar 连接 MySQL 做只读探测。当用户说「这台机器没装 mysql，帮我看下这张表结构」「确认下数据库连的是哪个库」「查一下这张表有没有数据 / 字段是什么」「线上库结构帮我探一下」，或需要在无 mysql/mysqlsh 客户端、不能装依赖的环境里确认连通性、版本、当前库、表结构、字段、少量样例数据时使用。此外：写完/改完涉及数据库字段的接口后、或写 SQL 前，只要能连库，就应主动用本 Skill SELECT 采样核验字段真实类型与数据存储格式（逗号分隔 vs JSON、字典值域、日期格式），别靠猜。仅允许 SELECT/SHOW/DESCRIBE/EXPLAIN 等只读查询，绝不写库、改表、删数据；用户明确授权写库时切换到 mysql-guarded-write。
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
