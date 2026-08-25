# 注册表与文件系统副作用 / Side-effect Reference

脚本对系统做的每一处改动都列在这里。**这份清单就是「脚本到底动了什么」的完整答案**——
排查「脚本是不是把我系统弄坏了」时，先看这里；这里没写的，脚本没碰。

脚本**不修改**：`hosts` 文件、防火墙规则、系统代理、计划任务、服务、组策略、任何 IDM 程序文件（不做二进制补丁）。

## 路径随架构变化

`arch` 由 `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` 的 `PROCESSOR_ARCHITECTURE` 决定，
非 `x86` 一律按 `x64` 处理（ARM64 也走这一支）。

| 变量 | `x86` | `x64` / ARM64 |
| --- | --- | --- |
| `CLSID` | `HKCU\Software\Classes\CLSID` | `HKCU\Software\Classes\Wow6432Node\CLSID` |
| `CLSID2` | `HKU\<SID>\Software\Classes\CLSID` | `HKU\<SID>\Software\Classes\Wow6432Node\CLSID` |
| `HKLM` | `HKLM\Software\Internet Download Manager` | `HKLM\SOFTWARE\Wow6432Node\Internet Download Manager` |

`HKCUsync` 为 `1` 时（`HKCU` 与 `HKU\<SID>` 指向同一份数据），所有 `HKU\<SID>` 侧的操作都会跳过。

## 只读

这些键只被读取，任何流程都不会修改它们。

| 键 / 值 | 用途 |
| --- | --- |
| `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` → `PROCESSOR_ARCHITECTURE` | 判定架构 |
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` → `ProductName` | 日志与界面上打印的系统名 |
| `HKLM\SOFTWARE\Internet Download Manager` → `InstallFolder` | `开始激活.cmd` 定位 IDM 安装目录（第一顺位） |
| `HKLM\SOFTWARE\WOW6432Node\Internet Download Manager` → `InstallFolder` | 同上（第二顺位） |
| `HKCU\Software\DownloadManager` → `ExePath` | 定位 `IDMan.exe`（第三顺位） |
| `HKU\<SID>\Software\DownloadManager` → `ExePath` | `IAS.cmd` 定位 `IDMan.exe` |
| `HKU\<SID>\Software\DownloadManager` → `idmvers` | 界面与日志上打印的 IDM 版本 |
| `HKCU\Console` → `ForceV2` | 判定控制台是否支持 ANSI 转义（`_NCS`） |
| `HKCU\Console` → `QuickEdit` | Windows 10 1511 以下判定是否需要 conhost 重入 |

`AdvIntDriverEnabled2` 在 `开始激活.cmd` 的自检里也是**只读**（只打印状态），写入发生在 `IAS.cmd` 的 `:add_key`。

## 临时探针（写完立刻删）

用于验证注册表可写性，跑完不留痕迹。**如果脚本被强制中断，可能残留**，可以手动删掉。

| 键 | 何时创建 |
| --- | --- |
| `HKCU\IAS_TEST` | 检测 `HKCU` 与 `HKU\<SID>` 是否同步 |
| `HKU\<SID>\IAS_TEST` | 同上（由上一条的写入是否可见来判断） |
| `<CLSID2>\IAS_TEST` | 检测 CLSID 分支是否可写；不可写则以退出码 `2` 终止 |

## 删除队列

`:delete_queue` 在 `[1]` 冻结、`[2]` 激活、`[3]` 重置**三条流程里都会执行**。
每一项先 `reg query` 确认存在，命中才删。

### `HKCU\Software\DownloadManager` 下的十个值

| 值名 | 类别 |
| --- | --- |
| `FName` `LName` `Email` `Serial` | 注册信息（姓名 / 邮箱 / 序列号） |
| `scansk` `tvfrdt` `radxcnt` `LstCheck` `ptrk_scdt` `LastCheckQU` | 试用计数与校验时间戳 |

`HKCUsync` 不为 `1` 时，对 `HKU\<SID>\Software\DownloadManager` 下同样的十个值再删一遍。

### 整个 `%HKLM%` 键

> **注意：删的是整个键，不是单个值。**

删除队列的最后一项是 `%HKLM%` 本身，即 x64 上的
`HKLM\SOFTWARE\Wow6432Node\Internet Download Manager`。这会连同 `InstallFolder`、`AdvIntDriverEnabled2`
等键下的全部内容一起删掉，随后 `:add_key` 只把 `AdvIntDriverEnabled2` 写回来。

**这解释了一个容易误判的现象**：跑过一次脚本之后，再运行 `开始激活.cmd`，
它的 IDM 路径自检可能不再走 `InstallFolder` 这一顺位，而是回退到 `HKCU` 的 `ExePath` 或默认安装路径。
这是预期行为，不是脚本坏了。重装 IDM 会把这些值写回来。

## 写入

| 键 / 值 | 类型 | 值 | 由谁写 |
| --- | --- | --- | --- |
| `%HKLM%` → `AdvIntDriverEnabled2` | `REG_DWORD` | `1` | `:add_key`（冻结 / 激活 / 重置都会写） |
| `HKCU\SOFTWARE\DownloadManager` → `FName` | `REG_SZ` | 随机四位数 | `:register_IDM`（仅 `[2]` 激活） |
| `HKCU\SOFTWARE\DownloadManager` → `LName` | `REG_SZ` | 随机四位数 | 同上 |
| `HKCU\SOFTWARE\DownloadManager` → `Email` | `REG_SZ` | `<FName>.<LName>@tonec.com` | 同上 |
| `HKCU\SOFTWARE\DownloadManager` → `Serial` | `REG_SZ` | 随机 `XXXXX-XXXXX-XXXXX-XXXXX` | 同上 |
| `HKCU\Software\DownloadManager` → `CheckUpdtVM` | `REG_DWORD` | `0`（`[4]`）/ `1`（`[5]`） | `:_updset` |

`HKCUsync` 不为 `1` 时，注册信息与 `CheckUpdtVM` 都会在 `HKU\<SID>\...` 下再写一份。

## CLSID 键：锁定或删除

这是脚本的核心操作。IDM 把试用期跟踪信息藏在 `CLSID` 分支下的一批 GUID 键里，脚本先扫描识别，再按流程处理：

| 流程 | 处理方式 |
| --- | --- |
| `[1]` 冻结 / `[2]` 激活 | 取得所有权 → 把所有者改成 NULL SID（`S-1-0-0`）→ 对 Everyone 加 **Deny FullControl**，IDM 从此读不到也写不了 |
| `[3]` 重置 | 直接删除（必要时先取所有权再删） |
| 冻结 / 激活时候选键**超过 20 个** | 自动改为删除而不是锁定 |

作用范围：`<CLSID>\{GUID}`，以及 `HKCUsync` 不为 `1` 时的 `<CLSID2>\{GUID}`。

识别规则（命中任意一条即视为 IDM 的试用跟踪键）：

1. 默认值是**纯数字**，且该键没有子键
2. 默认值含 `+` 或 `=`，且该键没有子键
3. `<键>\Version` 的默认值是纯数字，且该键恰好只有 1 个子键
4. 键下存在名字匹配 `MData` / `Model` / `scansk` / `Therad` 的值
5. 键完全为空（0 个值、0 个子键）

排除规则：凡是含有 `LocalServer32`、`InProcServer32`、`InProcHandler32` 子键的，一律跳过——那是真正的 COM 组件注册，不能动。

另外，扫描时因权限不足而枚举失败的键会被直接计入候选（输出「由于锁定被跳过」），
这是为了让**上一次已经锁住的键**在重置时仍能被找回来处理。

### 怎么还原被锁定的键

被 Deny ACL 锁住的键无法用注册表编辑器直接删除。两条路：

1. **推荐**：运行菜单 `[3]` 重置。脚本会重新取得所有权后删除它们。
2. 导入本次运行前自动导出的 `.reg` 备份（见下节）。

## 文件系统

| 路径 | 内容 | 何时产生 | 会不会自动清理 |
| --- | --- | --- | --- |
| `%SystemRoot%\Temp\_Backup_HKCU_CLSID_<时间戳>.reg` | 改动前的 `CLSID` 分支完整导出 | 冻结 / 激活 / 重置，每次运行 | **否** |
| `%SystemRoot%\Temp\_Backup_HKU-<SID>_CLSID_<时间戳>.reg` | `HKU\<SID>` 侧的同类导出 | 同上，且 `HKCUsync` 不为 `1` | **否** |
| `%SystemRoot%\Temp\IAS-<时间戳>.log` | 运行日志 | 带 `/log` 或任何 `/silent` 运行 | **否** |
| `/log=` 指定的路径 | 运行日志 | 指定且可写时 | **否** |
| `%SystemRoot%\Temp\temp.png` | 下载功能验证用的临时图片 | 冻结 / 激活的收尾验证 | 是，用完即删 |
| `<脚本目录>\.__ias_write_test.tmp` | 目录可写性探针 | `开始激活.cmd` 自检 | 是（用户中断时可能残留，已在 `.gitignore` 中） |

时间戳格式：备份用 `yyyyMMdd-HHmmssfff`；默认日志名由 `%date%_%time%` 去掉分隔符拼成，
**随系统区域设置变化**，不要按固定格式解析。

备份与日志**每运行一次就多一份**，CLSID 分支的导出可能有几 MB。确认 IDM 工作正常后可以自行删除：

```powershell
Remove-Item "$env:SystemRoot\Temp\_Backup_*_CLSID_*.reg"
Remove-Item "$env:SystemRoot\Temp\IAS-*.log"
```

## 进程

| 操作 | 何时 |
| --- | --- |
| `taskkill /f /im idman.exe` | 冻结 / 激活 / 重置 / 更新开关，在改注册表前；冻结与激活的下载验证结束后再来一次 |
| `start "" /B "<IDMan.exe>" /n /d <url> /p <目录> /f temp.png` | 下载功能验证，最多三次（三个链接串行尝试） |

**脚本跑完 IDM 是关着的**——这是刻意的，让注册表改动在 IDM 下次启动时生效。
如果之后 IDM 又自己出现，那是它自身的开机启动 / 托盘驻留 / 浏览器集成行为，与本脚本无关。

## 网络

只访问一个域名：`internetdownloadmanager.com`。

| 请求 | 用途 | 哪条流程 |
| --- | --- | --- |
| `ping -n 1 internetdownloadmanager.com` | 连通性预检 | `[1]` 冻结、`[2]` 激活；`开始激活.cmd` 自检 |
| TCP 连接 80 端口 | ping 失败时的兜底探测 | 同上 |
| 下载 `/images/idm_box_min.png` 等三张图片 | 验证 IDM 的下载功能仍正常 | `[1]` 冻结、`[2]` 激活 |

`[3]` 重置与 `[4]` / `[5]` 更新开关**完全离线**，不发起任何网络请求。

## 相关文档

- [命令行接口契约](cli.md)
- [内部子程序接口](internals.md)
- [关键模块与核心逻辑](../modules.md)
- [运维与排错指南](../operations.md) — 出问题时怎么用备份回滚
