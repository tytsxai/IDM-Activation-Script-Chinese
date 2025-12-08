# IAS.cmd 执行流程与依赖

## 总览流程

```mermaid
flowchart TD
  A[Start / IAS.cmd:1] --> B[初始化变量 & 代码页936 (5-31)]
  B --> C[PATH重置; 32/64/ARM64 自重启 (37-63)]
  C --> D[Null 服务检查 (70-82)]
  D --> E[LF 换行符检查 (86-97)]
  E --> F[参数解析/无人值守标记 (106-122)]
  F --> G[控制台配色 & 兼容性设置 (125-159)]
  G --> H[系统版本/PowerShell检测 (164-223)]
  H --> I[管理员权限判定与自提权 (229-235)]
  I --> J[QuickEdit 关闭/ConHost 重启 (239-269)]
  J --> K[更新提示 (272-281)]
  K --> L[初始化：WMI + SID + HKCU 同步 + 路径 (292-376)]
  L --> M{参数或菜单 (379-418)}
  M -->|/res 或菜单3| R[_reset 分支]
  M -->|/act 或 /frz 或菜单1/2| A[_activate/冻结 分支]
  M -->|菜单4/5| Web[打开下载/帮助链接]
  M -->|0/退出| X[done/done2 退出]
  R --> X
  A --> X
```

### 主菜单与分支
- `:MainMenu` (IAS.cmd:383)：显示选项 1=激活并冻结、2=激活、3=重置、4=下载 IDM、5=帮助、0=退出。根据选择设置 `frz` 并跳转到 `:_activate` 或 `:_reset`。
- 无人值守：传入 `/act` `/frz` `/res` 或将 `_activate/_freeze/_reset` 置 1（IAS.cmd:22-31, 379-382）时跳过菜单。

### 重置分支 (`:_reset`, IAS.cmd:422)
- 关闭 IDM 进程（433-434），生成时间戳（436-438）。
- 备份 CLSID：`reg export %CLSID%`、`%CLSID2%` 到 `%SystemRoot%\Temp\_Backup_*`（440-444）。
- 删除 IDM 配置：调用 `:delete_queue` 删除 HKCU/HKU `Software\DownloadManager` 的注册字段及 HKLM IDM 配置树（463-492），再对 HKU 分支重复（479-492）。
- 通过 PowerShell `:regscan` 删除并/或锁定 CLSID GUID 项（446-447 调用，PowerShell 体见 733-913）。
- 重新写入 HKLM IDM 项 `AdvIntDriverEnabled2=1`（716-728 via `:add_key`）。
- 显示完成后跳转 `:done`（451-455, 610-624）。

### 激活/冻结分支 (`:_activate`, IAS.cmd:512)
- 若非冻结模式，给出假阳性警告并可返回主菜单（523-536）。
- 检查 IDM 是否存在（538-543）；网络连通性到 `internetdownloadmanager.com`（547-557）。
- 采集系统/IDM 版本信息（559-565），关闭 IDM（566）。
- 备份 CLSID 同重置流程（569-576）。
- 删除旧配置并重建 HKLM IDM 项（577-579, 716-728）。
- PowerShell `:regscan` 以锁定/删除 CLSID（580）。
- 非冻结时调用 `:register_IDM` 写入随机注册信息到 HKCU/HKU `Software\DownloadManager`（582, 648-669）。
- `:download_files` 使用 IDM 静默下载三张图片以触发/锁定键，失败则报错（584-591, 672-706）。
- 再次 `:regscan` 加固 CLSID（593）。
- 根据模式输出“激活完成”或“冻结完成”提示（595-606）后进入 `:done`。

### 关键子程序
- `:delete_queue` / `:del`：删除 IDM 用户键、序列号等（463-507）。
- `:add_key` / `:add`：写 HKLM IDM 驱动标志（716-728）。
- `:register_IDM`：随机化 `FName/LName/Email/Serial`（648-669）。
- `:download_files` / `:download`: 调用 IDMan.exe 下载文件并等待存在性（672-706）。
- `:regscan`（PowerShell, 733-913）：扫描 HKCU/HKU CLSID GUID，必要时获取权限（RtlAdjustPrivilege, 833-835），删除或锁定。

## 注册表路径与读写点（含检测）
- `HKCU\Console` `ForceV2` 检测（136）；QuickEdit 检测（252）。  
- `HKCU\IAS_TEST` 与 `HKU\<SID>\IAS_TEST`：判断 HKCU/HKU 同步（327-337）。  
- 架构/环境检测：`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` (`PROCESSOR_ARCHITECTURE`, 341; 559)。  
- 用户 SID：`HKU\<SID>\Software` 可访问性验证（309, 313）。  
- IDM 安装信息：`HKU\<SID>\Software\DownloadManager` 读取 `ExePath`/`idmvers`（354, 562）。  
- IDM 配置键（删除/写入）：  
  - `HKCU\Software\DownloadManager` `FName/LName/Email/Serial/scansk/...` 删除（463-473）与注册写入（659-663）。  
  - `HKU\<SID>\Software\DownloadManager` 同步删除/写入（479-489, 664-669）。  
  - `HKLM\Software\Internet Download Manager` 或 `HKLM\SOFTWARE\Wow6432Node\Internet Download Manager`（根据 `arch`，348-352）；删除整树（474）；写入 `AdvIntDriverEnabled2`（716-718）。  
- CLSID：`HKCU\Software\Classes\CLSID` / `HKCU\Software\Classes\Wow6432Node\CLSID` 及 `HKU\<SID>\...` 对应分支（345-351）。备份导出（442-445, 574-576）、可写性测试（366-375）、PowerShell 扫描/删除/锁定（446-447, 580, 593, 733-913）。
- 系统版本读取：`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` `ProductName`（559）。

## 外部/系统依赖
- `chcp 936` 强制代码页（5-6, 84, 102, 285）。若目标机无中文代码页可能乱码。
- Null 服务：`sc query Null` 必须 RUNNING，失败仅警告但可能导致批处理异常（70-82）。
- PowerShell：要求 `powershell.exe` 存在且 `LanguageMode=FullLanguage`（171-223）；大量逻辑依赖 PowerShell（regscan、随机序列、下载等待）。
- WMI：`Get-WmiObject` 用于系统信息与 SID（292-302, 306-311）；WMI 失效则退出。
- 管理员/内核权限：`fltmc` 检测提权（229-235）；PowerShell `Take-Permissions` 调用 `RtlAdjustPrivilege` 调整 9/17/18 特权（833-835）。
- 进程依赖：`IDMan.exe` 必须存在并可被静默调用（354-359, 538-543, 697-705）；`tasklist/taskkill` 关闭 IDM（362-363, 566, 690）。
- 终端/宿主：如在 x86 上会通过 Sysnative/ARM32 重新启动 cmd.exe（51-63）；可选启动 `conhost.exe` 规避 Terminal（255-259, 266-268）。
- 网络：需能访问 `internetdownloadmanager.com`（547-557）以通过 ping/TCP 与后续下载（681-686）。

## 高风险/易失败区段
- **权限不足**：未以管理员运行会被直接退出（229-235）；`reg add/query` CLSID 写入失败也会退出（366-373）。
- **PowerShell/WMI 被禁用**：语言模式非 FullLanguage、WMI 返回空或被策略阻止时终止（214-223, 292-302）。
- **运行目录限制**：从临时目录或压缩查看器运行会被拒绝（197-205）。
- **注册表删除/锁定**：`delete_queue` 删除用户/机器级 IDM 配置（463-492）；`:regscan` 获取特权并删除或锁定 CLSID GUID（733-913）可能影响系统注册表或多用户环境。
- **随机注册写入**：`register_IDM` 生成随机姓名/邮箱/序列写入 HKCU/HKU（648-669），可能触发防护或被视为篡改许可。
- **网络/IDM 依赖**：无法连接 `internetdownloadmanager.com` 或 IDM 下载失败会导致激活流程失败（547-557, 585-591, 672-706）。
- **代码页强制**：固定 936 代码页在非中文系统下可能造成输出乱码或脚本兼容性问题（5-6, 84, 102, 285）。
- **Null 服务未运行**：仅警告但脚本声明可能异常，需留意环境（70-82）。
