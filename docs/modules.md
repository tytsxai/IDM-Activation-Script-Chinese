# 关键模块与核心逻辑 / Core Logic

本文解释 `IAS.cmd` 与 `开始激活.cmd` 到底怎么工作：执行链路、各阶段职责、以及那些「看起来可以简化、实际不能动」的地方。

- 想知道**能传什么参数、返回什么码** → [命令行接口契约](reference/cli.md)
- 想知道**某个标签的输入输出** → [内部子程序接口](reference/internals.md)
- 想知道**改了哪些注册表键** → [注册表与文件系统副作用](reference/registry.md)
- 想知道**仓库怎么组织、CI 怎么守** → [ARCHITECTURE.md](../ARCHITECTURE.md)

## 两个文件的分工

```
用户双击
    │
    ▼
开始激活.cmd  ── 只做三件事 ──┬─ 自动提权（UAC）
（219 行，可选入口）           ├─ 9 项环境自检，把问题翻译成人话
                              └─ call IAS.cmd %*  参数原样透传
    │
    ▼
IAS.cmd  ── 全部实际功能 ──┬─ 参数解析 / 日志 / 架构重入
（1268 行，核心引擎）       ├─ 环境探测（PowerShell / WMI / SID / CLSID 可写性）
                            ├─ 主菜单
                            ├─ 冻结·激活 / 重置 / 更新开关 三条业务分支
                            └─ 收尾（备份路径、日志路径、退出码）
```

`开始激活.cmd` **不是必需的**。以管理员身份直接跑 `IAS.cmd` 功能完全一样，只是没有那 9 项自检和中文提示。
自动化调用应当直接用 `IAS.cmd`——`开始激活.cmd` 在需要提权时会另开进程，原窗口拿不到退出码。

## `开始激活.cmd`：提权与自检

### 提权

`fltmc` 是判断管理员权限的经典手法（它需要管理员权限才能成功执行）。失败就走 `:elevate`：

```
powershell -NoProfile -Command "Start-Process -FilePath '<自身路径>' -ArgumentList '<参数>' -Verb RunAs"
```

两个细节必须一起处理，否则提权后的行为和「直接以管理员运行」不一致：

1. **路径用单引号包裹，且把路径里的单引号转义成两个**。不这么做，含 `(x86)` 的目录会报「此时不应有 \Internet」，
   含 `'` 的目录（如 `D:\Tom's Tools\`）会让 `Start-Process` 语法出错。
2. **必须传 `-ArgumentList`**。早期版本漏了它，命令行参数被静默丢掉——用户以为在跑 `/frz /silent`，
   提权后的窗口却弹出了交互菜单。参数拼进命令串前还要先剥掉双引号，否则 `/log="C:\x.log"` 里的引号会提前截断外层的 `-Command "..."`。

### 9 项环境自检

按顺序执行，每项打印 `[√]` / `[×]` / `[i]`。失败只累加 `issues` 并记下第一条 `firstFail`，**不直接终止**——
最后统一让用户决定是否继续。

| # | 检查项 | 判定方式 | 失败指向 |
| --- | --- | --- | --- |
| 1 | 管理员权限 | 走到这里即已获得（`fltmc` 通过或提权后重入） | — |
| 2 | `IAS.cmd` 就位 | 同目录下文件存在 | 没有「全部解压」 |
| 3 | PowerShell 可用性与语言模式 | `where powershell.exe` + `$ExecutionContext.SessionState.LanguageMode` 必须是 `FullLanguage` | README Q6 |
| 4 | Null 服务 | `sc query Null` 含 `RUNNING` | `sc start Null` |
| 5 | 网络连通性 | `ping -4 -n 1` → 失败则 `Test-NetConnection -Port 80` | README Q5 |
| 6 | 控制台代码页 | `chcp` 输出含 `936` | README Q4 |
| 7 | WMI / CIM | `Get-CimInstance Win32_OperatingSystem` → 失败则 `wmic` 兜底 | 检查 WMI 服务 |
| 8 | IDM 安装路径 | `HKLM InstallFolder` → `HKLM\WOW6432Node InstallFolder` → `HKCU ExePath` → 默认安装路径，四级回退 | README Q2 |
| 9 | 脚本目录可写 | 写一个 `.__ias_write_test.tmp` 再删掉 | 移出 `Program Files` |

第 8 项通过后会额外打印两条**纯只读**的诊断信息，不计入问题数：

- **IDM 版本号**：读 `IDMan.exe` 的 `ProductVersion`（取不到则 `FileVersion`）。提 Issue 时贴这个最有用。
- **浏览器集成开关**：读 `AdvIntDriverEnabled2`。这是 IDM 浏览器集成与本脚本**唯一的交集**——
  扩展图标变灰时先看它，就能判断问题在脚本这一侧还是 IDM 那一侧（见 README Q16）。

## `IAS.cmd`：启动阶段

从进程启动到主菜单，中间有一长串「不满足就退出」的关卡。理解它们的顺序，就能一眼看出日志停在哪一步。

```
1. chcp 936                      控制台切到 GBK，中文才不乱码
2. PATH 归一 + 架构重入          x86 进程在 x64/ARM64 上重入到 Sysnative（标记 r1）
                                 x64 进程在 ARM64 上重入到 SysArm32（标记 r2）
3. 参数解析                      剥引号 → 按空格切 → 匹配开关；/log= 单独提取
4. 日志初始化                    /silent 自动开日志
5. 静默模式校验                  静默但没有动作参数 → 退出码 2
6. Null 服务检查                 仅告警，不终止
7. LF 换行自检                   findstr /v "$" 命中 → 退出码 2
8. 控制台能力探测                _NCS / 颜色变量 / esc
9. 系统版本与 PowerShell 存在性  winbuild < 7600 或缺 powershell.exe → 退出码 2
10. 临时目录拦截                 从压缩包里直接运行 → 退出码 2
11. PowerShell 语言模式自检      非 FullLanguage → 退出码 2
12. 提权                         fltmc 失败 → Start-Process runas（带 -el 防循环）
13. QuickEdit / conhost 重入     见下文
14. 初始化探测                   WMI/CIM → 用户 SID → HKCU/HKU 同步判定 → 架构 → CLSID 可写性
15. IDM 版本探测                 读 IDMan.exe 文件版本，只读
16. 分派                         有动作参数 → 直接跳分支；否则渲染主菜单
```

三个值得单独说的：

### 架构重入（第 2 步）

批处理里的 `reg.exe` 在 32 位进程中会被重定向到 `Wow6432Node`，导致读写错分支。
脚本的做法是**换进程**而不是改路径：检测到自己跑在 32 位进程里，就用 `%SystemRoot%\Sysnative\cmd.exe`
重新拉起自己并附加 `r1` 标记（防止无限重入）。ARM64 上还有一次 `SysArm32` 的重入（标记 `r2`）。

### LF 换行自检（第 7 步）

`findstr /v "$"` 用于找出不以 CRLF 结尾的行。批处理对 LF 换行的行为在不同 Windows 版本上不一致，
所以脚本宁可直接拒绝运行也不冒险。**这也是仓库强制 `.cmd` 为 CRLF 的原因**（`.gitattributes` + `tools/validate.ps1` 双重把关）。

一个副作用：脚本末尾**必须留一个空行**，否则这条自检会误报。`IAS.cmd` 最后一行的注释就是提醒这件事的。

### QuickEdit / conhost 重入（第 13 步）

控制台的 QuickEdit 模式下，用户随手一点就会暂停整个脚本，看起来像卡死。脚本的处理是关掉它：
Windows 10 1809（build 17763）及以上用 `start conhost.exe` 另开一个控制台重新运行自己，
低版本直接用 PowerShell 调 `SetConsoleMode`。

`start` 被安全软件或组策略拦截时，cmd 只会打印一句系统文案「拒绝访问。」然后窗口关掉——
脚本本身没有这句话，用户完全无从判断。所以这里加了回退：`start` 失败就打印中文警告、
在当前窗口继续跑（见 README Q17）。

**不要用 `if (...)` 包住那行 `start conhost.exe`**：`%d1%`…`%d4%` 展开后含大量括号，会把代码块提前截断。

## 三条业务分支

### 冻结 / 激活流程

`[1]` 冻结与 `[2]` 激活走同一段代码，由 `frz` 变量区分（`1` = 冻结，`0` = 激活）。

```
 1. 激活模式且交互运行 → 弹「建议改用冻结」的二次确认（choice [1]返回 [9]继续）
 2. 确认 IDMan.exe 存在                        ── 不存在 → 退出码 1，不动任何注册表
 3. 网络预检：ping → 失败则 TCP 80             ── 不通   → 退出码 1，不动任何注册表
 4. 打印系统 / 架构 / IDM 版本，写日志
 5. 关闭正在运行的 IDM
 6. 导出 CLSID 分支到 %SystemRoot%\Temp\_Backup_*.reg
 7. :delete_queue   删注册信息、试用计数，以及整个 %HKLM% 键
 8. :add_key        把 AdvIntDriverEnabled2 写回 1
 9. CLSID 扫描 ①    $lockKey=1 $toggle=1  → 锁定（候选 > 20 个则改为删除）
10. frz=0 时 :register_IDM  写入随机姓名 / 邮箱 / 序列号
11. :download_files 用 IDM 下载三张官网图片   ── 全失败 → 退出码 1
12. CLSID 扫描 ②    $lockKey=1              → 再锁一次
13. :done           打印备份路径与日志路径
```

几个关键点：

- **第 2、3 步在任何写操作之前**。这就是为什么在没装 IDM 的 CI runner 上跑 `/act` `/frz` 是安全的——
  它们走到「未检测到 IDM 安装」就退出了，一个注册表键都不会碰。
- **第 10 步是冻结与激活的唯一区别**。冻结不写序列号，因此不会触发 IDM 的联网序列号校验，
  也就不会被判「假序列号」。这是文档统一推荐 `[1]` 的技术原因。
- **第 12 步为什么要再锁一次**：第 11 步让 IDM 真的跑了一次，IDM 在运行过程中可能重新创建被删掉的 CLSID 键。
  第二次扫描把新冒出来的键一并锁上。
- **第 9 步的 20 个阈值**：正常情况下 IDM 的试用跟踪键只有个位数。识别出几十个通常意味着规则误伤，
  此时锁定（加 Deny ACL）的破坏性远大于删除——锁住的键连注册表编辑器都动不了。所以超过 20 个就退化成删除。

### 重置流程

```
1. 关闭正在运行的 IDM
2. 导出 CLSID 分支备份
3. :delete_queue
4. CLSID 扫描  $deleteKey=1  → 删除（而非锁定）
5. :add_key    把 AdvIntDriverEnabled2 写回 1
6. :done
```

与冻结/激活相比：**不检查网络、不做下载验证、CLSID 键删除而不是锁定、不写注册信息**。
所以它可以完全离线执行，也是「激活出问题了先重置」这条建议的基础。

### 更新开关

```
1. 确认 IDMan.exe 存在        ── 不存在 → 退出码 1
2. 读并打印变更前的 CheckUpdtVM
3. 关闭正在运行的 IDM
4. 写 CheckUpdtVM = 0（禁用）或 1（恢复）
5. :done
```

最短的一条分支：只改一个 DWORD，不联网、不碰 CLSID、不写序列号，与激活状态完全独立。

## CLSID 扫描与锁定

这是整个项目技术上最特别的一段，也是唯一一段不由 cmd 执行的代码。

### 它怎么被执行

PowerShell 代码以纯文本形式**嵌在 `IAS.cmd` 自己的文件里**，夹在一对 `:regscan:` 标记之间。
运行时 cmd 调 PowerShell，让它把 `IAS.cmd` 读回来、按标记切开、把中间那段交给 `iex`：

```
[io.file]::ReadAllText('<自身路径>', [Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*'
```

这么绕的原因是批处理没法优雅地内联多行 PowerShell——转义、括号、`%` 全都会打架。

**两个真实踩过的坑**（CI 各有一条断言守着，细节见 [内部子程序接口](reference/internals.md#regscan)）：

1. `ReadAllText` 的单参数重载在文件无 BOM 时按 UTF-8 解码，而 `IAS.cmd` 是无 BOM 的 GBK →
   这一段里的中文全变成替换字符，用户看到一屏乱码。**必须显式传 `GetEncoding(936)`**。
2. 分割正则是 `:regscan\:.*`，**任何地方**（包括注释）出现这个标记字面量都会多切一刀，
   `$f[1]` 就不再是 PowerShell 代码。

### 它怎么识别 IDM 的键

IDM 把试用状态藏在 `CLSID` 下的随机 GUID 键里，没有固定名字，只能靠特征识别。
五条识别规则与一条排除规则见 [注册表副作用](reference/registry.md#clsid-键锁定或删除)。

思路是：**真正的 COM 组件注册一定有 `InProcServer32` 之类的子键**，而 IDM 藏数据用的键要么是空的、
要么只放了一个数字或一段 base64 样式的字符串。所以「长得不像 COM 组件的 GUID 键」就是嫌疑对象。

因权限不足枚举失败的键会被**直接计入候选**（输出「由于锁定被跳过」）。这不是错误处理，
而是刻意设计：上一次运行锁住的键这次会枚举失败，必须能被找回来，否则重置就解不开锁。

### 锁定手法

```
1. RtlAdjustPrivilege(9, 17, 18)      拿 SeTakeOwnership / SeBackup / SeRestore 特权
2. SetOwner(S-1-5-32-544)             把所有者改成 Administrators
3. ResetAccessRule(Everyone, Allow)   先给自己完全控制，才能改下一步
4. SetOwner(S-1-0-0)                  所有者改成 NULL SID —— 没有任何账户能重新取得所有权
5. ResetAccessRule(Everyone, Deny)    对所有人拒绝一切访问
6. 试着 Remove-Item                   删得掉说明没锁成功（打印「失败」）；删不掉才是成功（打印「已锁定」）
```

第 6 步的**成功判定是反的**——这不是笔误。锁定的定义就是「连脚本自己也删不掉」，
所以删除抛异常才代表锁成功了。

第 4 步把所有者设成 NULL SID 是关键：仅仅加 Deny ACL 的话，管理员随时能取回所有权改回来，IDM 也一样。
所有者是 NULL SID 之后，这个键在正常路径下就彻底动不了了——**也包括用户自己**。
这是运行本脚本最不可逆的一步，还原方式只有菜单 `[3]` 重置或导入 `.reg` 备份。

## 日志与错误记账

两个小模块，但它们决定了出问题时有没有线索。

### 退出码只记第一个

`:set_exit` 在 `exit_code` 已非零时不再覆盖。因为失败之后往往还会继续跑清理动作，
后面的操作码会把真正的失败原因盖掉。拿到的应该是**最早的**失败原因。

### 日志文件名必须在子程序里拼

```cmd
set "_logstamp=%date%_%time%"
set "_logstamp=%_logstamp::=%"
...
set "log_file=%log_dir%\IAS-%_logstamp%.log"
```

这几行**必须留在 `:init_log_default` 子程序里**。如果搬回 `if (...)` 代码块内，
批处理会在解析整块时一次性展开 `%_logstamp%`，取不到上一行刚写入的值，
文件名退化成字面量 `IAS-%_logstamp%.log`——所有静默运行都追加进同一个文件，日志彻底没法用。

CI 里有一条专门的断言守这件事（`Assert default log file name carries a real timestamp`）。

## 那些「看起来能简化、实际不能动」的地方

改动前请先读这一节。每一条都对应一次真实的回归。

| 位置 | 看起来可以 | 实际会怎样 |
| --- | --- | --- |
| `%psc%` 变量 | 直接写 `powershell.exe "..."` 更短 | 裸调用在真实控制台下进入交互模式，永久挂死（[#4](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/4)）。也不要在调用点再手写 `-NoProfile -Command`，会重复 |
| `:_color` / `:_color2` 的回退分支 | 两个分支的参数位应该对齐 | 颜色变量在两种模式下 token 数不同，对齐后非 ANSI 控制台会打印空 `echo` 或裸颜色名 |
| `:init_log_default` | 内联回 `if` 块里更直观 | `%_logstamp%` 提前展开，日志文件名退化成字面量 |
| `start conhost.exe` 那一行 | 用 `if (...)` 包起来更整齐 | `%d1%`…`%d4%` 含大量括号，会截断代码块 |
| 内嵌 PowerShell 的 `ReadAllText` | 单参数重载更短 | 无 BOM 的 GBK 被当 UTF-8 解码，整段中文变乱码 |
| `:regscan:` 标记 | 在注释里提一下这个标记名 | 分割正则会多切一刀，`iex` 拿到的不是代码 |
| `:kill_idm` 的返回码 | 应该透传 `taskkill` 的结果 | 跨会话实例必然「拒绝访问」，会被误判成激活失败 |
| `IAS.cmd` 末尾的空行 | 多余，删掉 | LF 自检误报，脚本直接以退出码 `2` 拒绝运行 |

## 相关文档

- [ARCHITECTURE.md](../ARCHITECTURE.md) — 仓库结构、CI 数据流、发布包守卫
- [配置说明](configuration.md) — 所有可调项
- [运维与排错指南](operations.md) — 出问题时怎么定位和回滚
