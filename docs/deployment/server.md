# 服务器 / 批量部署 / Unattended & Fleet Deployment

这个项目没有服务端，也不是长驻程序——**没有「部署到服务器」这回事**。
与之最接近的场景是「在自己的多台 Windows 机器上免交互执行一次」，脚本为此提供了
`/silent`、`/log=` 和三段式退出码。本文说明怎么正确编排，以及哪些约束绕不过去。

> **适用范围**：你自己拥有或有权管理的设备。
> 企业 / 学校的受管设备请不要用本文的方法——WDAC / AppLocker 会拦截未签名脚本，
> 这是 IT 策略层的限制，正确做法是联系管理员，不是绕过。

## 三条绕不过去的约束

先看这一节。它决定了很多看起来合理的编排方式其实跑不通。

### 1. 目标机器必须有交互登录的用户会话

脚本靠 `Win32_ComputerSystem.UserName` 取**当前交互登录用户**的 SID，再操作 `HKU\<SID>` 分支
（取不到时回退到同会话 `explorer.exe` 的属主 SID）。没有人登录时这个值为空，
脚本会以退出码 `2` 退出并提示「未找到用户帐户 SID」。

**推论**：以 SYSTEM 身份、在无人登录的机器上远程执行，必然失败。这不是缺陷——
IDM 的试用状态本来就存在用户配置单元里，没有目标用户就无从谈起。

### 2. 必须是管理员，且要拿到真实退出码就得直接调 `IAS.cmd`

`开始激活.cmd` 在非管理员时会用 `Start-Process -Verb RunAs` 另开一个进程，
原进程立刻返回 `0`，**拿不到激活流程的真实结果**。

所以自动化调用一律：**以管理员身份直接执行 `IAS.cmd`**。

### 3. 路径不能含空格

参数解析会先剥掉所有引号再按空格切分。`/log=C:\My Logs\ias.log` 会被截断成 `C:\My`。
脚本所在目录同理，选一个无空格的路径，例如 `C:\IAS\`。

## 单机无人值守

```cmd
IAS.cmd /frz /silent /log=C:\IAS\logs\host.log
```

- `/silent` 会**自动开启日志**，`/log=` 只是改落点。不指定时写到 `%SystemRoot%\Temp\IAS-<时间戳>.log`。
- 退出码：`0` 成功，`1` 业务失败（没装 IDM、网络不通、注册表写失败），`2` 环境或参数错误。
  完整对照见 [命令行接口契约](../reference/cli.md#退出码)。
- **不要解析 stdout**。它是 GBK 编码的中文界面，且在支持 / 不支持 ANSI 的控制台上输出并不相同。
  判断结果只用退出码，取证只用日志文件。

### 常见组合

```cmd
:: 冻结试用期（推荐，最稳）
IAS.cmd /frz /silent /log=C:\IAS\logs\frz.log

:: 先重置再冻结，任一步失败就停下
IAS.cmd /res /silent /log=C:\IAS\logs\res.log
if %errorlevel% NEQ 0 exit /b %errorlevel%
IAS.cmd /frz /silent /log=C:\IAS\logs\frz.log
if %errorlevel% NEQ 0 exit /b %errorlevel%

:: 顺手关掉 IDM 的自动更新，避免升级后激活失效
IAS.cmd /noupd /silent /log=C:\IAS\logs\noupd.log
```

`/res` `/noupd` `/reupd` **不需要联网**，离线机器上也能跑；`/frz` `/act` 需要能连通 `internetdownloadmanager.com`。

## 多机批量

### 方式一：计划任务（推荐）

最贴合「必须有交互会话」这条约束的方式。在每台机器上建一个任务：

```powershell
$action  = New-ScheduledTaskAction -Execute 'C:\IAS\IAS.cmd' `
                                   -Argument '/frz /silent /log=C:\IAS\logs\frz.log'
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
                                        -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName 'IAS-Freeze' -Action $action `
                       -Trigger $trigger -Principal $principal
```

关键在 `-LogonType Interactive` + `-RunLevel Highest`：以**目标用户本人**的身份、
带管理员权限、在他登录之后运行。用 `-LogonType S4U` 或 SYSTEM 都会撞上约束 1。

跑完之后再收结果：

```powershell
Get-ScheduledTaskInfo -TaskName 'IAS-Freeze' | Select-Object LastRunTime, LastTaskResult
```

`LastTaskResult` 就是脚本的退出码。

### 方式二：PowerShell Remoting

```powershell
$hosts = 'PC-01', 'PC-02', 'PC-03'

$results = Invoke-Command -ComputerName $hosts -ScriptBlock {
    $p = Start-Process -FilePath 'C:\IAS\IAS.cmd' `
                       -ArgumentList '/frz', '/silent', '/log=C:\IAS\logs\frz.log' `
                       -Wait -PassThru -NoNewWindow
    [pscustomobject]@{ Computer = $env:COMPUTERNAME; ExitCode = $p.ExitCode }
}

$results | Sort-Object ExitCode -Descending | Format-Table -AutoSize
```

**注意**：`Invoke-Command` 默认在网络登录会话里运行，与目标机器上那个交互会话不是同一个。
`/res` `/noupd` `/reupd` 通常没问题（它们操作的是当前账户的 `HKCU`），
但 `/frz` `/act` 依赖对交互用户 SID 的判定，**远程执行前务必先在一台机器上验证一遍**再铺开。
拿不准就用方式一。

### 方式三：PsExec

```cmd
psexec \\PC-01 -h -i 1 -w C:\IAS C:\IAS\IAS.cmd /frz /silent /log=C:\IAS\logs\frz.log
```

`-h` 用最高权限运行，`-i 1` 指定在会话 1（控制台交互会话）里运行——**这个 `-i` 是必需的**，
否则又会掉进约束 1。会话号可以用 `query session` 查。

### 日志集中收集

每台机器的日志都是行式文本，直接抓回来即可：

```powershell
$hosts | ForEach-Object {
    Copy-Item "\\$_\C$\IAS\logs\frz.log" -Destination ".\collected\$_-frz.log" -ErrorAction SilentlyContinue
}
```

日志格式是 `[<日期> <时间>] <消息>`，日期时间来自 `%date%` / `%time%`，
**随各机器的区域设置变化**，不要按固定格式解析。

## 分发脚本本身

发布包是固定文件名的 zip，做成软件分发很直接：

```powershell
# 拉取 + 校验 + 解压到固定目录
$zip = "$env:TEMP\IDM-Activation-Script.zip"
Invoke-WebRequest -Uri 'https://github.com/tytsxai/IDM-Activation-Script-Chinese/raw/main/release/IDM-Activation-Script.zip' -OutFile $zip

$expected = '<把 .sha256 文件里的值填在这里>'
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected) { throw 'SHA256 不匹配，中止。' }

Expand-Archive -Path $zip -DestinationPath 'C:\IAS' -Force
```

**务必校验 SHA256**，值取自仓库里的
[`release/IDM-Activation-Script.zip.sha256`](../../release/IDM-Activation-Script.zip.sha256)。
本仓库目前不使用 GitHub Releases 分发，版本号见 [`CHANGELOG.md`](../../CHANGELOG.md)，
分发约定见 [`release/README.md`](../../release/README.md)。

> `Expand-Archive` 解出来的中文文件名可能显示异常（包内条目名按 GBK 存储，不带 UTF-8 标志位）。
> 这不影响运行——`开始激活.cmd` 靠 `%~dp0` 找同目录的 `IAS.cmd`，不依赖文件名编码。
> 介意的话就直接调 `IAS.cmd`，它是纯 ASCII 文件名。

## 自托管 CI runner

如果想在自己的 Windows 机器上跑本仓库的 CI（例如验证一个 GitHub 托管 runner 上覆盖不到的旧系统），
把 `.github/workflows/ci.yml` 里的 `runs-on: windows-latest` 换成你的 runner 标签即可。

需要满足：PowerShell 7（`pwsh`）、`git`、简体中文语言包或至少可用的代码页 936。
**这台机器上不要装 IDM**——CI 的 `/act` `/frz` 冒烟之所以安全，正是因为 runner 上没有 IDM，
脚本走到「未检测到 IDM 安装」就退出了。装了 IDM 会让这些冒烟真的去改注册表。

## 明确不支持的场景

| 场景 | 为什么 |
| --- | --- |
| Windows Server 上批量部署给多用户 | 试用状态存在每个用户的配置单元里，且需要交互登录会话 |
| 无人登录的机器上远程执行 `/frz` `/act` | 取不到交互用户 SID，退出码 `2` |
| 容器 / 无头环境 | 见 [容器化与隔离环境](container.md) |
| 企业受管设备（WDAC / AppLocker） | IT 策略层拦截，应联系管理员 |
| macOS / Linux | 脚本是 Windows 批处理 |
| 任何需要合法商业授权凭证的生产环境 | 请购买 IDM 正版授权 |

## 相关文档

- [命令行接口契约](../reference/cli.md)
- [本地部署](local.md)
- [容器化与隔离环境](container.md)
- [运维与排错指南](../operations.md)
