# 内部子程序接口 / Internal Reference

`IAS.cmd` 是单文件批处理，内部靠标签（label）划分。批处理没有函数签名，参数靠全局变量传递、
返回值靠退出码和全局变量——所以**每个标签的输入、副作用和返回约定只能靠文档记录**。本文就是这份记录。

> `tools/check-docs.ps1` 会在 CI 中断言：`IAS.cmd` 里的每一个标签在本文中都有条目，本文也不会记录不存在的标签。
> 新增或删除标签时，本文必须同步，否则 CI 直接失败。

## 怎么读这份文档

- **控制流标签**：靠 `goto` 进入，不返回调用点，最终落到 `:done` 或 `:done2`。
- **子程序标签**：靠 `call` 进入，以 `exit /b` 返回。批处理的 `call` 没有参数命名，本文列出它实际读取的全局变量。
- 行号会随改动漂移，因此本文按**标签名**索引，不写行号。`IAS.cmd` 头部的「代码导航」注释块给的是粗略区间，
  以本文为准。

## 全局状态变量

这些变量在参数解析和环境探测阶段设定，之后被几乎所有标签读取。

| 变量 | 含义 |
| --- | --- |
| `iasver` | 脚本自身版本号。CI 断言它与 `CHANGELOG.md` 顶部版本一致 |
| `idmsupport` | 最后一次真机验证过的 IDM 版本，主菜单据此显示「已适配 IDM x.xx」 |
| `_activate` / `_freeze` / `_reset` / `_noupd` / `_reupd` | 动作开关，由参数或头部硬编码置 1 |
| `_silent` / `_unattended` | 静默与无人值守标志。`_silent=1` 必然 `_unattended=1` |
| `_log` / `_log_enabled` / `log_file` / `_logpath` / `log_dir` | 日志开关与落点 |
| `exit_code` | 最终退出码，只由 `:set_exit` 写入，且只记录第一个非零值 |
| `_sid` | 当前用户 SID，用于拼 `HKU\<SID>\...` 路径 |
| `HKCUsync` | `HKCU` 与 `HKU\<SID>` 是否指向同一份数据。为 `1` 表示同步，跳过 `HKU` 侧的重复操作 |
| `arch` | `x86` 或 `x64`，决定走不走 `Wow6432Node` |
| `CLSID` / `CLSID2` | 两条 CLSID 分支路径（`HKCU` 侧与 `HKU\<SID>` 侧） |
| `HKLM` | IDM 的 HKLM 键路径，随 `arch` 变化 |
| `IDMan` | `IDMan.exe` 的完整路径 |
| `frz` | 在 `:_activate` 中区分冻结（`1`）与激活（`0`） |
| `_NCS` | 控制台是否支持 ANSI 转义序列。`1` = 支持（默认），`0` = 不支持，走无颜色回退分支 |
| `psc` | PowerShell 调用前缀，固定为 `powershell.exe -NoProfile -Command` |
| `terminal` / `quedit` | 是否跳过 `mode` 调窗口大小 / 是否跳过 conhost 重入 |
| `_batp` | 本脚本自身路径，单引号已转义，供内嵌 PowerShell 自读文件用 |

## 控制流标签

### `:qeLegacy` / `:skipQE`

QuickEdit 处理分支。Windows 10 1809（build 17763）以下走 `:qeLegacy`（直接重入并退出当前进程），
以上先尝试 `start conhost.exe`，失败则打印警告并 `goto :skipQE` 在当前窗口继续。

**不要用 `if (...)` 包住 `start conhost.exe` 那一行**——`%d1%`…`%d4%` 展开后含大量括号，会把代码块提前截断。

### `:MainMenu`

渲染主菜单并用 `choice /C:12345670 /N` 取输入。`errorlevel` 到菜单项的映射是**按 `/C` 字符串位置**，不是按数字：

| errorlevel | 按键 | 去向 |
| --- | --- | --- |
| `1` | `1` | `:_activate`（`frz=1`，冻结） |
| `2` | `2` | `:_activate`（`frz=0`，激活） |
| `3` | `3` | `:_reset` |
| `4` | `4` | `:_noupdate` |
| `5` | `5` | `:_restoreupd` |
| `6` | `6` | 浏览器打开 IDM 官方下载页，返回菜单 |
| `7` | `7` | 浏览器打开本项目主页，返回菜单 |
| `8` | `0` | `exit /b`（退出） |

改动 `/C` 字符串就会整体错位，改菜单时两处必须一起改。

### `:_reset`

重置流程。顺序：`:kill_idm` → 导出 CLSID 备份 → `:delete_queue` → 内嵌 PowerShell（`$deleteKey=1`，删除 CLSID 键）→ `:add_key` → `:done`。

### `:_noupdate` / `:_restoreupd` / `:_updapply`

更新检查开关。前两个只负责设定 `_updval`（`0` / `1`）与 `_updact`（「禁用」/「恢复」）两个变量，然后落到共用的 `:_updapply`。
`:_updapply` 会先确认 IDM 已安装（否则 `set_exit 1`），打印变更前的值，关闭正在运行的 IDM，再通过 `:_updset` 写入。

**这条分支不联网、不碰 CLSID、不写序列号**，与激活状态互不影响。

### `:_activate`

冻结与激活的共用主流程，由 `frz` 区分。顺序见 [关键模块与核心逻辑](../modules.md#冻结--激活流程)。

### `:done`

正常收尾。打印本次注册表备份的文件名模式与日志路径，然后：无人值守下 `exit /b %exit_code%`，
交互下等待按键并 `goto MainMenu` 回到菜单。

### `:done2`

早退收尾。用于环境检查阶段就失败的场景——此时还没有备份、也没有菜单可回，直接 `exit /b %exit_code%`。

## 子程序标签

### `:delete_queue`

**读取**：`HKLM`、`_sid`、`HKCUsync`
**副作用**：遍历删除队列，每一项先 `reg query` 确认存在，命中才 `call :del`
**返回**：`exit /b`（失败由 `:del` 记入 `exit_code`）

队列包含 `HKCU\Software\DownloadManager` 下的十个值，以及**整个 `%HKLM%` 键**。
`HKCUsync` 不为 `1` 时，对 `HKU\<SID>` 侧再走一遍同样的十个值。完整清单见 [注册表副作用](registry.md)。

### `:del`

**读取**：`reg`（要删除的目标，含引号）
**副作用**：`reg delete %reg% /f`；成功打印并记日志，失败着红色并 `call :set_exit 1`

### `:_updset`

**读取**：`reg`（含 `/v` `/t` `/d` 的完整 `reg add` 参数串）
**副作用**：`reg add %reg% /f`；失败 `call :set_exit 1`

### `:_rcont`

**读取**：`reg`
**副作用**：`reg add %reg%`，随后 `call :add` 统一处理成功 / 失败输出。

`:register_IDM` 用它逐条写入注册信息。

### `:register_IDM`

**读取**：`_sid`、`HKCUsync`
**副作用**：生成随机姓名、邮箱与序列号并写入注册表

生成规则：`FName` 与 `LName` 各取 `%random% %% 9999 + 1000` 的四位数；`Email` 拼成 `<FName>.<LName>@tonec.com`；
`Serial` 由 PowerShell 从 `A-Z0-9` 随机取 20 个字符，按 `5-5-5-5` 分组。

**只在 `frz=0`（激活）时调用**。冻结路径跳过它，这正是冻结不会触发 IDM「假序列号」判定的原因。

### `:download_files` / `:download` / `:check_file`

**读取**：`IDMan`
**副作用**：调用 IDM 依次下载 IDM 官网的三张小图片到 `%SystemRoot%\Temp\temp.png`，用完删除
**返回**：只要任意一张下成功就置 `_fileexist=1`

`:download` 用 `start "" /B "%IDMan%" /n /d <url> /p <目录> /f temp.png` 发起下载，
`:check_file` 每秒轮询一次、最多 20 次。三个链接串行尝试。

这一步的目的是**验证 IDM 在改完注册表后仍能正常下载**。全部失败会 `set_exit 1` 并终止流程。
它也是 `/frz` 与 `/act` 需要联网的原因之一。

### `:add_key` / `:add`

**读取**：`HKLM`
**副作用**：把 `%HKLM%\AdvIntDriverEnabled2` 写成 `REG_DWORD 1`

`:delete_queue` 会把整个 `%HKLM%` 键删掉，`:add_key` 负责把浏览器集成总开关写回去。
`:add` 是共用的结果处理，同时被 `:_rcont` 使用——所以它读的是调用前 `reg add` 留下的 `errorlevel`。

### `:regscan`

这不是 cmd 执行的标签，而是一对**文本标记**。`IAS.cmd` 用
`[io.file]::ReadAllText(<自身路径>, [Text.Encoding]::GetEncoding(936))` 把自己读出来，
按 `:regscan\:.*` 正则切成三段，把中间那段交给 `iex` 执行。

**输入**（由 cmd 拼进 PowerShell 命令行）：

| 变量 | 含义 |
| --- | --- |
| `$sid` | 当前用户 SID |
| `$HKCUsync` | 非 `$null` 时跳过 `HKEY_USERS` 侧，避免重复处理 |
| `$lockKey` | 非 `$null` 时取所有权并加 Deny ACL 锁定 |
| `$deleteKey` | 非 `$null` 时直接删除 |
| `$toggle` | 非 `$null` 时启用「候选键超过 20 个就改为删除」的保护 |

三处调用点的组合：重置用 `$deleteKey=1`；激活/冻结第一次锁定用 `$lockKey=1, $toggle=1`；收尾再锁一次用 `$lockKey=1`（不带 `toggle`）。

**两个必须守住的约束**（CI 各有一条断言）：

1. 读取自身时必须显式传 `[Text.Encoding]::GetEncoding(936)`。`ReadAllText` 的单参数重载在无 BOM 时按 UTF-8 解码，
   而本脚本是无 BOM 的 GBK——那样这一段里的中文会全部变成替换字符，用户看到一屏乱码。
2. 分割正则是 `:regscan\:.*`，**任何地方**（包括注释）出现这个标记字面量都会多切一刀，
   `$f[1]` 就不再是 PowerShell 代码，`iex` 直接失败。

识别逻辑与锁定手法见 [关键模块与核心逻辑](../modules.md#clsid-扫描与锁定)。

### `:PowerShellTest:`（同类标记，不是标签）

和 `:regscan:` 一样是一对文本标记，但用途不同：它夹住的是一行 PowerShell 表达式
（`$ExecutionContext.SessionState.LanguageMode`），脚本用同样的「自读文件 + 按标记切开 + `iex`」
手法执行它，来判断 PowerShell 是否处于 `FullLanguage` 模式。不是 `FullLanguage` 就以退出码 `2` 退出。

它写在 `REM` 行里、不在行首，所以不是批处理标签；同样必须显式带 `GetEncoding(936)` 读取自身。

### `:kill_idm`

**副作用**：`taskkill /f /im idman.exe`，输出全部重定向进日志
**返回**：**固定 `exit /b 0`**

固定返回 0 是有意的。`taskkill` 对每个同名进程各输出一行，无权限的实例（其它用户会话、更高完整性级别）
会在 stderr 打印「拒绝访问。」。关闭 IDM 失败并不影响激活结果，但那句系统报错会被用户当成激活失败，
所以这里统一收口：输出只进日志，退出码不污染调用方。

### `:flush_input`

**副作用**：`$Host.UI.RawUI.FlushInputBuffer()`，清空键盘缓冲区
**返回**：固定 `exit /b 0`

激活流程包含下载与等待，用户中途随手敲的键会留在缓冲区，等跑到 `pause` 时被立刻消费掉——
表现为「没按任何键却自己跳回去了」。只在 `pause` 路径调用；`choice` 只接受指定按键，不受影响。
stdin 被重定向时（管道调用 / CI）`RawUI` 会报错，用 `try-catch` 吃掉。

### `:set_exit`

**参数**：`%1` = 退出码，`%2` = 可选的日志消息
**副作用**：`exit_code` 为 `0` 时才写入；`%2` 非空则 `call :log`

「只记录第一个非零码」是刻意的：拿到的是最早的失败原因，而不是被后续清理动作覆盖掉的结果。

### `:extract_logpath`

**读取**：`_args`
**副作用**：解析出 `/log=` 后面的路径写入 `_logpath`，并置 `_log=1`

不能靠参数解析主循环拿这个值：`for %%A in (...)` 的集合解析把 `=` 也当分隔符，
`/log=C:\x.log` 在那里已经被拆成两个 token。所以直接从完整参数串里按 `=` 再按空格切两次。
取到的值若以 `/` 开头（例如用户写了 `/log= /silent`），视为空路径忽略。

### `:init_log` / `:init_logpath` / `:init_log_default`

**副作用**：确定 `log_file`

`:init_log` 先试 `:init_logpath`（用户指定路径：建父目录 → 试写一行 → 成功才采用），
失败则打印警告并落到 `:init_log_default`（`%SystemRoot%\Temp\IAS-<时间戳>.log`）。

**这段逻辑必须留在子程序里。** 若搬回 `if (...)` 代码块内，`%_logstamp%` 会在整块解析时一次性展开、
取不到上一行刚写入的值，文件名会退化成字面量 `IAS-%_logstamp%.log`，所有静默运行都追加进同一个文件。
CI 里有对应的回归断言。

### `:log`

**参数**：`%*` = 日志正文
**副作用**：`_log_enabled=1` 时向 `log_file` 追加一行 `[<日期> <时间>] <正文>`；否则直接返回

### `:_color` / `:_color2`

**参数位在两种控制台模式下不同，这不是笔误。**

颜色变量有两套定义：

- `_NCS=1`（支持 ANSI）时是**单个** token，例如 `Red="41;97m"`
- `_NCS=0`（不支持 ANSI）时是**两个** token，例如 `Red="Red" "white"`（背景色 + 前景色）

于是同一处 `call :_color %Red% "文案"`，文案在前者落在 `%2`、在后者落在 `%3`；`:_color2` 同理是 `%2%4` 与 `%3%6`。

把回退分支「顺手对齐」成 ANSI 分支的参数位，会让文案变成空 `echo`（打印 `ECHO is on.`）或裸颜色名（打印 `GrayBlack`）。
这类改动只在不支持 ANSI 的控制台上暴露——Windows 7/8/8.1（`winbuild < 10586`），或用户关掉了 `HKCU\Console\ForceV2`——
而 CI runner 永远走 ANSI 分支。所以 CI 里专门有一步把 `ForceV2` 置 0，真正跑一遍回退分支再断言。

`_NCS` 的取值：默认 `1`；`winbuild < 10586` 或 `HKCU\Console\ForceV2` 为 `0x0` 时置 `0`。
代码里 `if %_NCS% EQU 1` 走 ANSI 分支——**`1` = 支持 ANSI，`0` = 回退**。

## 相关文档

- [命令行接口契约](cli.md) — 对外的参数与退出码
- [注册表与文件系统副作用](registry.md) — 每一个被读写的键与文件
- [关键模块与核心逻辑](../modules.md) — 这些标签串起来的完整执行链路
