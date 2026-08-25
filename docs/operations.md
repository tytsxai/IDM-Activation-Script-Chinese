# 运维与排错指南 / Operations & Troubleshooting

面向**需要定位问题的人**：维护者、帮别人排查的人、以及要在多台机器上跑脚本的人。

分工说明：
- 终端用户的具体症状与处理步骤在 [README 的「常见问题」](../README.md#常见问题)（Q1–Q19）。
- 本文讲**怎么定位**：先看什么、日志怎么读、故障树怎么走、出事了怎么回滚。

## 三件事按顺序做

排查任何问题，都从这三步开始，顺序不要换：

### 1. 拿退出码

```cmd
IAS.cmd /frz /silent /log=C:\Temp\ias.log
echo 退出码: %errorlevel%
```

| 退出码 | 说明 | 下一步 |
| --- | --- | --- |
| `0` | 脚本跑完了 | 问题不在脚本执行，看「脚本返回 0 但 IDM 仍不正常」一节 |
| `1` | 进了业务流程但没成 | 看日志最后几行，通常是没装 IDM / 网络不通 / 注册表写失败 |
| `2` | 还没开始干活就被环境挡住 | 走下面的「退出码 2 故障树」 |

**记住一条**：`exit_code` 只记录**第一个**非零码。拿到的是最早的失败原因，
不会被后续清理动作的结果盖掉。

### 2. 拿日志

日志是唯一可靠的证据来源。

```cmd
IAS.cmd /frz /log
```

不带路径时写到 `%SystemRoot%\Temp\IAS-<时间戳>.log`，脚本启动时会把完整路径打印出来。
`/silent` 会自动开日志，不用另加 `/log`。

日志格式固定：

```
[<日期> <时间>] <消息>
```

### 3. 拿环境自检输出

```
双击 开始激活.cmd → 截图或复制那 9 行 [√] / [×] 输出
```

这 9 行能一次性排除掉绝大多数环境类问题，也是提 Issue 时最有价值的信息。
只写「用不了」或贴一个空日志无法定位。

## 日志怎么读

日志里的关键行及其含义：

| 日志行 | 含义 |
| --- | --- |
| `IAS <版本> 启动，参数: ...` | 第一行。确认脚本**真的收到了**你以为传进去的参数 |
| `IDM 版本检测: [x.xx] 脚本已适配 y.yy` | 本机 IDM 与脚本适配版本。两者主版本差得多时优先怀疑兼容性 |
| `检测到信息 - [系统 \| 内部版本 \| 架构 \| IDM: 版本]` | 只在冻结 / 激活流程打印。**这一行出现，说明已通过 IDM 存在性与网络检查** |
| `已备份注册表: _Backup_...reg` | 回滚的锚点。记下文件名 |
| `已删除 - <键>` / `失败 - <键>` | 删除队列的逐项结果 |
| `已添加 - <键>` / `已写入 - <键>` | 写入结果 |
| `下载成功: <url>` / `下载失败: <url>` | IDM 下载功能验证。三条全失败才算失败 |
| `关闭 IDMan.exe 未完全成功` | **不是错误**。跨会话或多实例时必然出现，不影响结果 |
| `流程结束，退出码 N` | 最后一行。没有这一行说明脚本是被强杀或崩掉的 |

**日志停在哪一行，就是卡在哪一步。** 特别是：

- 停在 `IAS ... 启动` 之后没有别的 → 卡在环境探测（WMI / SID / CLSID 权限），见下面的故障树。
- 停在 `正在备份 CLSID 注册表` → CLSID 分支很大，导出需要时间，属正常，等一会儿。
- 停在 `开始下载测试资源` → IDM 起来了但下不动，检查网络与 IDM 自身设置。

## 退出码 2 故障树

`2` 表示环境或参数问题。按脚本的实际检查顺序排查——**先命中的先报**：

```
静默模式缺动作参数      → 只给了 /silent 没给 /frz|/act|/res|/noupd|/reupd
        │
不支持的操作系统版本     → Windows build < 7600
        │
找不到 powershell.exe   → PATH 被破坏，或系统组件缺失
        │
脚本从临时文件夹运行     → 在压缩包查看器里直接双击了，先「全部解压」
        │
检测到 LF 换行符         → 脚本被编辑器改成 LF，或末尾空行被删掉
        │
PowerShell 运行被阻止    → 语言模式不是 FullLanguage（组策略），README Q6
        │
缺少管理员权限           → UAC 被拒或提权失败
        │
WMI 查询失败             → WMI 仓库损坏，见下方专项
        │
未能获取当前用户 SID     → 没有交互登录会话（常见于远程 / SYSTEM 上下文执行）
        │
无法写入 <CLSID2>        → 注册表分支权限异常，或上一次锁定留下了 Deny ACL
```

### WMI 仓库损坏

表现为脚本卡在「正在初始化…」的 `检测系统信息 (WMI/CIM)` 那一步很久不动（README Q12）。

```cmd
:: 管理员 CMD
winmgmt /verifyrepository
:: 报异常时：
net stop winmgmt
winmgmt /salvagerepository
net start winmgmt
```

脚本已经优先用 `Get-CimInstance`（WinRM 通道），失败才回退旧版 `Get-WmiObject`（DCOM/RPC）。
后者在仓库异常或被安全软件挂钩时可能长时间挂起。临时关掉杀软实时防护再试一次，可以确认是不是这个原因。

### 无法写入 CLSID 分支

如果之前跑过 `[1]` / `[2]`，CLSID 键上会有 Deny ACL 且所有者是 NULL SID。
正常情况下脚本的探针写的是 `IAS_TEST` 子键，不受影响；持续失败通常意味着整个
`HKCU\Software\Classes\...\CLSID` 分支的权限被改过。

先试 `[3]` 重置（脚本会重新取得所有权），仍不行就导入备份 `.reg` 还原。

## 退出码 1 故障树

`1` 表示进了业务流程但没成。

| 日志中的原因 | 处理 |
| --- | --- |
| `未检测到 IDM 安装` | `IDMan.exe` 不在预期位置。见下方「IDM 路径找不到」 |
| `无法连接到 internetdownloadmanager.com` | 关 VPN / 代理再试。`/res` `/noupd` `/reupd` 不需要网络，可以先用它们 |
| `删除失败 - <键>` | 该键被占用或权限异常。先关干净 IDM（含托盘），再重试 |
| `写入失败 - <键>` / `添加失败 - <键>` | 同上；`HKLM` 侧写失败通常是权限不足，确认真的是管理员 |
| `IDM 下载测试失败` | IDM 起不来或下不动。手动开一次 IDM 下载点东西验证；也可能是网络只是勉强连通 |

### IDM 路径找不到

四级回退顺序（`开始激活.cmd` 的自检）：

```
HKLM\SOFTWARE\Internet Download Manager\InstallFolder
  → HKLM\SOFTWARE\WOW6432Node\Internet Download Manager\InstallFolder
    → HKCU\Software\DownloadManager\ExePath
      → %ProgramFiles(x86)%\Internet Download Manager\IDMan.exe
        → %ProgramFiles%\Internet Download Manager\IDMan.exe
```

**注意一个容易误判的现象**：`:delete_queue` 会删掉**整个** `HKLM` 侧的 IDM 键
（连同 `InstallFolder`），随后只把 `AdvIntDriverEnabled2` 写回来。
所以**跑过一次脚本之后**，路径探测很可能不再走前两级，而是靠 `ExePath` 或默认路径命中。
这是预期行为，重装 IDM 会把这些值补回来。详见 [注册表副作用](reference/registry.md#整个-hklm-键)。

绿色版 / 便携版 IDM 不写注册表，四级全落空——这种情况脚本不支持，请安装官方版本。

## 脚本返回 0 但 IDM 仍不正常

退出码 `0` 只表示**脚本按预期跑完了自己那一段**，不代表 IDM 一定处于已激活状态。
`/act` 写入的随机序列号是否被 IDM 服务端接受，脚本无从判断。

| 症状 | 定位 |
| --- | --- |
| IDM 仍提示「未注册」 | `[2]` 写的随机序列号被判无效。改用 `[1]` 冻结（不写序列号），README [Q3](../README.md#q3) / [Q13](../README.md#q13) |
| 过一两天又弹「试用已到期」 | IDM 周期性联网校验，或自动更新后覆盖了冻结状态。`[3]` → `[1]` → `[4]`，README [Q18](../README.md#q18) |
| 浏览器扩展图标变灰 | IDM 自身的浏览器集成问题。先看自检里的 `IDM 浏览器集成开关` 那一行，README [Q16](../README.md#q16) |
| 某些网页打不开 | IDM 集成模块接管请求所致，与脚本无关（脚本不改 hosts / 防火墙 / 代理），README [Q14](../README.md#q14) |
| IDM 又自己启动了 | 脚本不驻留后台。是 IDM 的开机启动 / 托盘驻留行为，README [Q11](../README.md#q11) |

## 进不了菜单

两种典型现象，处理方式不同：

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 自检全绿后清屏，一闪而过「拒绝访问。」 | `start conhost.exe` 重入被安全软件 / 策略拦截。这句是 cmd 打的系统文案，脚本本身没有 | `IAS.cmd -qedit` 跳过重入；再查 Windows 安全中心「保护历史记录」。README [Q17](../README.md#q17) |
| 自检全绿后黑屏卡死，`powershell.exe` 不退出 | 旧版本里 `powershell.exe` 的调用缺 `-NoProfile -Command`，在真实控制台下进了交互模式 | 已修复。更新到最新版；临时用 `IAS.cmd -qedit`。README [Q19](../README.md#q19) |

## 回滚

### 首选：菜单 `[3]` 重置

```cmd
IAS.cmd /res /silent /log=C:\Temp\ias-reset.log
```

它会重新取得 CLSID 键的所有权并删除它们、清掉写入的注册信息，把 IDM 打回初始状态。
**离线可用**，不需要网络。

### 备选：导入注册表备份

每次冻结 / 激活 / 重置**在动手之前**都会导出备份：

```
C:\Windows\Temp\_Backup_HKCU_CLSID_<yyyyMMdd-HHmmssfff>.reg
C:\Windows\Temp\_Backup_HKU-<SID>_CLSID_<时间戳>.reg    （HKCU 未与 HKU 同步时才有）
```

脚本每次跑完（含失败退出）都会把本次备份的文件名模式打印在结尾。双击 `.reg` 导入即可。

> **导入 `.reg` 不能删除多出来的键**，只能覆盖已有的值。所以如果问题是「被锁定的键需要清掉」，
> **用 `[3]` 重置，不要指望导入备份**。

### 清理残留

备份与日志不会自动清理，每运行一次就多一份（CLSID 导出可能有几 MB）：

```powershell
Remove-Item "$env:SystemRoot\Temp\_Backup_*_CLSID_*.reg"
Remove-Item "$env:SystemRoot\Temp\IAS-*.log"
```

用户中断自检时可能残留 `<脚本目录>\.__ias_write_test.tmp`，直接删掉即可。

## CI 红了怎么办

`Windows validation` 工作流的失败步骤直接对应原因：

| 失败步骤 | 原因 | 处理 |
| --- | --- | --- |
| `Guard public repository visibility` | 仓库被改成 private | 见 [OPEN_SOURCE_POLICY.md](../OPEN_SOURCE_POLICY.md) |
| `Run encoding and EOL checks` | `.cmd` 编码 / BOM / 行尾被改坏 | 注解里会指出具体文件与行 |
| `Smoke probe — IAS.cmd ...` | 参数解析或流程回归 | 对照期望退出码，本地按 [本地部署](deployment/local.md#在-windows-上完整环境) 复现 |
| `Assert ... non-ANSI fallback` | `:_color` / `:_color2` 的回退分支参数位被改错 | 见 [内部子程序接口](reference/internals.md#_color--_color2) |
| `Assert the embedded PowerShell segment ...` | `ReadAllText` 丢了编码参数，或哪里多写了一次 `:regscan:` 标记 | 见 [内部子程序接口](reference/internals.md#regscan) |
| `Verify documentation matches the scripts` | 文档与脚本不同步 | 见 [文档同步规则](doc-sync.md) |
| `Verify release bundle matches the repository` | **发布包忘了重新打** | 见下 |

### 发布包与仓库不一致

这是最常见的一条：改了 `IAS.cmd` / `开始激活.cmd` / `使用说明.txt`，但 `release/` 里还是旧包。
**用户下载到的会是旧脚本，而其它 CI 步骤全绿**——这个守卫存在的全部意义就是让它别静悄悄地发生。

在 Windows 上：

```powershell
pwsh -NoProfile -File tools/pack-release.ps1
pwsh -NoProfile -File tools/verify-release.ps1
```

手上没有 Windows 时，从 CI 拿现成的（`Rebuild release bundle` 步骤带 `if: always()`，校验失败时也会产出）：

```bash
gh run download <run-id> -R tytsxai/IDM-Activation-Script-Chinese -n release-bundle-rebuilt -D /tmp/bundle
cp /tmp/bundle/IDM-Activation-Script.zip        release/
cp /tmp/bundle/IDM-Activation-Script.zip.sha256 release/
```

> 文档类文件（README / CHANGELOG / SECURITY / LICENSE）不一致只发 `::warning::`，不阻断 CI。
> 只有会被执行的三个文件不一致才是硬失败。

## 提 Issue 时该附什么

按这个清单给，能省掉一轮来回：

1. `开始激活.cmd` 的完整环境检测输出（9 行 `[√]` / `[×]`）
2. 运行日志（`/log` 生成的文件）
3. 退出码
4. Windows 版本与内部版本号（`winver`）
5. IDM 版本（自检里会打印）
6. 实际用的入口和参数（双击 `开始激活.cmd`？还是 `IAS.cmd /xxx`？）
7. 复现步骤

Issue 模板 [`bug_report.yml`](../.github/ISSUE_TEMPLATE/bug_report.yml) 已经把前几项列成必填项。

## 相关文档

- [README 常见问题](../README.md#常见问题) — 终端用户视角的症状与处理
- [命令行接口契约](reference/cli.md) — 退出码语义
- [注册表与文件系统副作用](reference/registry.md) — 脚本到底改了什么
- [关键模块与核心逻辑](modules.md) — 执行链路，用于判断卡在哪一步
- [维护 / 发布检查清单](maintenance-checklist.md)
