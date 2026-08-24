# IDM 激活脚本中文版 — Internet Download Manager 试用期冻结与激活工具

[![Windows CI](https://github.com/tytsxai/IDM-Activation-Script-Chinese/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/tytsxai/IDM-Activation-Script-Chinese/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](./LICENSE)
[![Version](https://img.shields.io/github/v/release/tytsxai/IDM-Activation-Script-Chinese?label=version&color=brightgreen)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Windows%207%20%7C%208%20%7C%208.1%20%7C%2010%20%7C%2011-blue.svg)](#系统要求)

[文档](docs/README.md) · [AI 摘要 (llms.txt)](llms.txt) · [更新日志](CHANGELOG.md) · [问题反馈](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues) · [开源策略](OPEN_SOURCE_POLICY.md)

面向中文 Windows 的 **IDM（Internet Download Manager）试用期管理与激活批处理脚本**。一键冻结试用期、写入注册信息激活、重置试用状态、关闭 IDM 更新提示。全中文菜单，GBK 编码在中文控制台不乱码，不修改 IDM 程序文件，每次改注册表前自动备份可还原。双击 `开始激活.cmd` 即用，无需安装任何依赖。

### Quick Start (30 秒上手)

[下载 ZIP](#快速下载) → 全部解压 → 双击 `开始激活.cmd` → UAC 点"是" → 菜单里按 `1` 冻结试用期。

详细步骤见[使用方法](#使用方法)，不确定选哪个模式见[功能说明](#功能说明)。

### English Summary

A Simplified-Chinese Windows **batch toolkit for Internet Download Manager (IDM)**: freeze the trial period, activate by writing generated registration data, reset activation/trial state, and toggle IDM's automatic update check. Chinese console UI with proper GBK/CP936 code-page handling, no IDM binary patching, automatic registry backup before every write. Works on Windows 7 through 11, zero external dependencies, open-source under GPL-3.0. For a machine-readable project summary, see [llms.txt](./llms.txt).

## 项目简介

**IDM 激活脚本中文版**（IDM Activation Script）是 [WindowsAddict/IDM-Activation-Script](https://github.com/WindowsAddict/IDM-Activation-Script) 的简体中文维护分支：全中文菜单、GBK/CP936 控制台编码、一键入口，把 Internet Download Manager（IDM）的**试用期冻结、随机注册信息激活、试用状态重置、关闭自动更新检查**封装成一个双击即用的批处理工具。不修改 IDM 程序文件，每次改注册表前自动备份，运行时只依赖 Windows 自带组件（CMD / PowerShell / 注册表），不安装、不下载任何第三方程序。

| 项目 | 说明 |
| --- | --- |
| **是什么** | 面向中文 Windows 的 Internet Download Manager（IDM）激活与试用期管理批处理脚本 |
| **解决什么** | 英文 IDM 脚本在中文 CMD/PowerShell 里乱码；新手不知道该运行哪个文件、要不要管理员权限、怎么处理 SmartScreen/Defender 拦截；激活或试用状态异常后缺一个可回退、可排查的处理流程 |
| **适合谁** | 中文 Windows 7 / 8 / 8.1 / 10 / 11 用户；以及想研究 Windows 批处理、注册表操作、GBK/CP936 控制台兼容的开发者 |
| **核心功能** | `[1]` 冻结试用期 · `[2]` 随机注册信息激活 · `[3]` 重置激活/试用 · `[4]`/`[5]` 禁用/恢复 IDM 自动更新检查 · 运行前环境自检 · 注册表自动备份可还原 |
| **典型场景** | 新装 IDM 想直接可用 · 把已领的 30 天试用期固定住 · 激活异常后重置重来 · 关掉反复弹出的更新提示 · 自用多机无人值守（`/silent`）→ 详见[使用场景](#使用场景) |
| **技术栈** | Windows Batch/CMD · PowerShell（UAC 提权、环境探测）· Windows 注册表 / WMI / CIM · GBK / CP936 + CRLF · GitHub Actions（`windows-latest`）CI |
| **支持平台** | Windows 7 / 8 / 8.1 / 10 / 11（含 24H2）；仅 Windows，macOS / Linux 不支持 |
| **许可证** | GPL-3.0，公开可审查、可自由再分发 |
| **不包含** | 不含 IDM 安装包，不修改 IDM 程序文件，不绕过企业策略（WDAC / AppLocker） |

**核心入口**

| 文件 | 用途 |
| --- | --- |
| `开始激活.cmd` | **唯一需要双击的主文件**：自动请求管理员权限 → 环境自检 → 弹出菜单（冻结 / 激活 / 重置 / 禁用更新提示任选） |
| `IAS.cmd` | 核心引擎，被 `开始激活.cmd` 调用；也支持 `/frz` `/act` `/res` `/noupd` `/reupd` `/silent` `/log=` 参数 |

> 所有功能都在一个 `开始激活.cmd` 里，新手只需双击它。

**限制与注意**

- 会修改 IDM 相关注册表键（运行前自动备份、可还原），建议只在自己可控的设备上使用。
- SmartScreen / Defender / 第三方杀软可能拦截未签名批处理，属常见误报；可先校验 SHA256 再运行。
- `[1]` 冻结与 `[2]` 激活需要能连通 internetdownloadmanager.com，连不通会直接以退出码 `1` 退出且不改注册表；`[3]` `[4]` `[5]` 可离线执行。
- 企业环境的 WDAC / AppLocker 策略会拦截未签名脚本，这是 IT 策略层面的限制，应联系管理员而非绕过。
- 请在合法授权且理解风险的前提下使用，遵守当地法律法规与 IDM 软件许可协议。

## 快速下载

> **👉 直接下载按钮（推荐）**：[前往 GitHub Releases 页面下载最新版](https://github.com/tytsxai/IDM-Activation-Script-Chinese/releases/latest)  
> 页面中 `Assets` 区域的 `.zip` 文件即为安装包，点击即下载。

也可以在本仓库内直接下载（右键"链接另存为"）：

- 最新版压缩包（点击右键另存为）：[IDM-Activation-Script.zip](https://github.com/tytsxai/IDM-Activation-Script-Chinese/raw/main/release/IDM-Activation-Script.zip)
- 校验值（SHA256）：[IDM-Activation-Script.zip.sha256](https://github.com/tytsxai/IDM-Activation-Script-Chinese/raw/main/release/IDM-Activation-Script.zip.sha256)
- 完整更新历史：[CHANGELOG.md](./CHANGELOG.md)

> 压缩包**固定叫 `IDM-Activation-Script.zip`，不带版本号**，所以上面两个链接永远指向最新版，不用每次发版换链接。当前版本号见页首徽章、[CHANGELOG.md](./CHANGELOG.md) 或运行脚本时的窗口标题。

> 安全起见建议校验：下载后在 PowerShell 中执行 `Get-FileHash .\IDM-Activation-Script.zip -Algorithm SHA256`，与 `.sha256` 文件内的值比对一致后再解压使用。若嫌麻烦，校验可略过。

## 目录

- [项目简介](#项目简介)
- [快速下载](#快速下载)
- [功能特性](#功能特性)
- [与上游原版的区别](#与上游原版的区别)
- [系统要求](#系统要求)
- [使用方法](#使用方法)
- [功能说明](#功能说明)
- [使用场景](#使用场景)
- [常见问题](#常见问题)
- [技术细节](#技术细节)
- [文件说明](#文件说明)
- [更新日志](#更新日志)
- [维护与贡献](#维护与贡献)
- [相关链接](#相关链接)
- [搜索引擎与 AI 索引信息](#搜索引擎与-ai-索引信息)
- [免责声明](#免责声明)
- [许可证](#许可证)
- [版本与维护](#版本与维护)

## 功能特性

- ✅ **IDM 6.x 常见版本兼容** - 基于现有注册表结构维护，更新 IDM 后可重新运行冻结或重置流程
- ✅ **三种处理模式** - `[1]` 冻结试用期、`[2]` 激活（写入注册信息）、`[3]` 重置，随时可互相切换
- ✅ **可关闭 IDM 更新弹窗** - `[4]`/`[5]` 一键禁用或恢复 IDM 自动更新检查，顺带避免升级后激活失效
- ✅ **中文显示优化** - 全部批处理/文本使用 GBK 编码，运行时强制 `chcp 936`，避免控制台乱码
- ✅ **注册表自动备份** - 每次改写前把相关分支导出为 `%SystemRoot%\Temp` 下的 `.reg`，双击即可导入还原
- ✅ **环境自检** - 进菜单前依次检查 9 项（管理员权限 / `IAS.cmd` 就位 / PowerShell 与语言模式 / Null 服务 / 网络 / 代码页 / WMI-CIM / IDM 安装路径与版本 / 目录写权限），失败时直接指出是哪一项
- ✅ **可脚本化调用** - `/silent` 无人值守、`/log=路径` 落盘日志，退出码 `0`/`1`/`2` 区分成功、业务失败与环境错误
- ✅ **无需破解** - 不修改 IDM 程序文件，只读写 IDM 相关注册表键
- ✅ **开源可审查** - GPL-3.0 许可，脚本与发布说明均可公开审查，发布包附 SHA256 校验值

> ⚠️ 提示：脚本文件使用 GBK 编码（便于 Windows 控制台显示），在 GitHub/Web IDE 中查看可能出现乱码，可用支持 GBK 的编辑器或 `iconv`。

## 与上游原版的区别

本项目源自 [WindowsAddict/IDM-Activation-Script](https://github.com/WindowsAddict/IDM-Activation-Script)。**该上游仓库已于 2024-04 归档、不再更新**，下表对比的是它归档时的最终状态（仓库内仅 `IAS.cmd`、`README.md`、`.gitattributes`、`.Rhistory` 四个文件）。

| 对比项 | 上游原版（已归档） | 本仓库（持续维护） |
|--------|--------------------|--------------------|
| 界面语言 | 英文 | 简体中文 |
| 控制台编码 | 不做代码页处理，中文 Windows 下易乱码 | GBK 保存 + 运行时 `chcp 936`，中文正常显示 |
| 入口 | 直接运行 `IAS.cmd` | 独立入口 `开始激活.cmd`，自动提权 + 9 项环境自检后再进菜单 |
| 命令行参数 | `/act` `/frz` `/res` | 上述三项，外加 `/noupd` `/reupd` `/silent` `/log=` |
| IDM 更新提示开关 | 无 | `[4]` / `[5]` 一键禁用或恢复（`CheckUpdtVM`） |
| 无人值守 / 日志 | 无 | `/silent` + `/log=路径`，配合退出码 `0` / `1` / `2` 供脚本判断 |
| 系统信息探测 | 旧版 WMI（`Get-WmiObject`） | 优先 `Get-CimInstance`，失败才回退，规避新版 Windows 上的卡死 |
| 自动化校验 | 无 CI | GitHub Actions（`windows-latest`）校验编码、行尾、脚本冒烟、发布包哈希一致性 |
| 发布产物 | 无 | 固定文件名 zip + `.sha256`，CI 守住"改了仓库忘了重新打包" |
| 脚本规模 | 约 942 行 | 约 1264 行 |

核心的注册表操作思路继承自上游，冻结（`/frz`）与激活（`/act`）的原理一致；本仓库的增量集中在中文化、可用性、可排查性和工程守卫上。上游已归档，因此**问题反馈请提到本仓库的 [Issues](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues)**，提到上游不会有人处理。

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 7 / 8 / 8.1 / 10 / 11（含 24H2） |
| 权限 | **管理员权限**（脚本会自动请求，无需手动设置） |
| 依赖 | PowerShell（Windows 系统自带，无需额外安装） |
| 网络 | `[1]` 冻结与 `[2]` 激活**需要联网**：开始前先探测 internetdownloadmanager.com（ping + 80 端口），不通就以退出码 `1` 结束且不改任何注册表；收尾还会让 IDM 下载几张官网小图片验证下载功能。`[3]` 重置、`[4]`/`[5]` 更新开关是纯注册表操作，可离线执行。连不通时先关闭 VPN / 代理再试 |
| 编码 | 中文控制台（脚本自动执行 `chcp 936`，**无需手动设置**） |
| 磁盘 | 解压到普通可写目录即可（不要放在 `C:\Program Files` 或压缩包内直接运行） |

## 使用方法

> 懒人两步：解压后双击 `开始激活.cmd` → 在弹出的"是"窗口里授予管理员权限 → 它会先自检环境，再弹出菜单，**按数字选 `[1]` 冻结试用期（推荐，最稳）** 即可；若你从未领过 30 天试用期、想让 IDM 直接可用，再改选 `[2]` 激活。  
> 小贴士：`开始激活.cmd` 进菜单前会一次检查 9 项 —— 管理员权限、`IAS.cmd` 是否就位、PowerShell 可用性与语言模式、Null 服务、网络连通性、代码页、WMI/CIM、IDM 安装路径（顺带打印 IDM 版本与浏览器集成开关）与当前目录写权限，全程仅需本仓库文件。

> ### ⚠️ 第一次运行前必看
>
> 1. **必须以管理员身份运行**。`开始激活.cmd` 会自动弹出 UAC 提权窗口，点"**是**"即可。
> 2. **Windows 可能弹出"已阻止"或"Windows 已保护你的电脑"**（SmartScreen）。这是对未签名批处理脚本的标准提示，不是脚本真的有问题。处理方法：
>    - SmartScreen 弹窗：点 **"更多信息"** → **"仍要运行"**；
>    - 文件属性里若出现"此文件来自其他计算机，可能会阻止此文件"，在文件上右键 → **属性** → 底部勾选"**解除锁定**" → 确定。
> 3. **杀软（Defender/360/火绒）可能报毒**。本脚本涉及注册表写入和提权，属于启发式引擎的常规误报。若信任本仓库的发布包（SHA256 已公布），可把解压目录临时加入杀软白名单再运行。

### 方法一：图形界面（推荐新手）

1. **双击** `开始激活.cmd`（会自动请求管理员权限；若没弹窗，可右键 → "以管理员身份运行"）
2. **等待环境自检完成**，随后自动进入菜单
3. **按数字选择**（推荐 `[1]` 冻结试用期，最稳；从未领过试用期、想直接可用则选 `[2]` 激活）

```
┌─────────────────────────────────────┐
│  脚本 1.0.1 | 已适配 IDM 6.43        │
│  本机检测到的 IDM：6.43.x            │
├─────────────────────────────────────┤
│  [1] 冻结试用期      ⭐ 推荐         │
│  [2] 激活（写入注册信息）            │
│  [3] 重置激活/试用期                 │
│  [4] 禁用 IDM 更新提示               │
│  [5] 恢复 IDM 更新提示               │
│  [6] 下载 IDM                       │
│  [7] 帮助                           │
│  [0] 退出                           │
└─────────────────────────────────────┘
```

<details>
<summary><b>方法二：命令行（高级用户，新手可以跳过）</b></summary>

以管理员身份打开 CMD，然后运行：

```cmd
# 冻结试用期（推荐，最稳）
IAS.cmd /frz

# 激活（从未领过试用期、想直接可用时选它）
IAS.cmd /act

# 重置激活
IAS.cmd /res

# 禁用 IDM 自动更新检查（不再弹"发现新版本"）
IAS.cmd /noupd

# 恢复 IDM 自动更新检查
IAS.cmd /reupd

# 静默模式 + 日志（无人值守）
IAS.cmd /act /silent /log=C:\Temp\ias.log
```

> 说明：`/silent`（等价别名 `/quiet`）抑制菜单与等待；未带 `/frz` `/act` `/res` `/noupd` `/reupd` 即开启静默将返回码 2。同时给 `/noupd` 和 `/reupd` 时以 `/noupd` 为准。
>
> 日志：
> - `/log` 不带路径 → 写到 `%SystemRoot%\Temp\IAS-<时间戳>.log`，脚本启动时会把完整路径打印出来；
> - `/log=路径` → 写到指定文件（目录不存在会自动创建；写不进去会提示并回退到上面的默认位置）；
> - `/silent` 会自动开启日志，不用再写 `/log`；
> - **路径里不要有空格**：参数按空格切分，`C:\My Logs\ias.log` 会被截断。反馈问题时附上这个日志文件最有用。

`开始激活.cmd` 会把收到的参数原样透传给 `IAS.cmd`。但如果它不是以管理员身份启动的，会先弹 UAC 重开一个进程，**原窗口拿不到新进程的退出码**；需要按退出码判断结果的自动化调用，请以管理员身份直接执行 `IAS.cmd`。

</details>

## 功能说明

> **怎么选？看你当前的状态：**
> - **拿不准就选 `[1]` 冻结试用期**（推荐）：不写序列号，在 IDM 6.42+ 上最稳；正在用 30 天试用期的话，冻结会把它固定住不让到期
> - **从未领取 30 天试用期 / 想让 IDM 直接能用** → 选 `[2]` **激活**（写入随机注册信息，不需要账号）
> - 选 `[2]` 激活后 IDM 仍提示"未注册"或弹虚假序列号窗口 → 改用 `[1]` 冻结

### ❄️ 冻结试用期（菜单 `[1]`）[推荐]

- **功能**：把 IDM 当前的试用期冻结住，不写入序列号
- **优点**：不会触发"虚假序列号"提示，在 IDM 6.42+ 上最稳定、最不容易再弹注册窗
- **说明**：正在用 30 天试用期的话，冻结就是把它固定下来不让过期
- **适用**：绝大多数用户的首选；用 `[2]` 激活后仍被提示"未注册"时也用它兜底

### 🌟 激活（菜单 `[2]`）

- **功能**：写入随机注册信息直接激活 IDM，写入后即可正常使用
- **优点**：**不需要账号、也不需要先领试用期**
- **代价**：部分环境下 IDM 会弹虚假序列号窗口；脚本在执行前也会提示你优先考虑 `[1]`
- **适用**：从未领过试用期、只想让 IDM 直接能用的用户

### 🔄 重置激活/试用期

- **功能**：清除所有激活信息，恢复初始状态
- **用途**：解决激活异常、更换激活方式

### 🔕 禁用 / 恢复 IDM 更新提示（菜单 `[4]` / `[5]`）

- **功能**：把注册表 `HKCU\Software\DownloadManager` 下的 `CheckUpdtVM` 置为 `0`（`[5]` 改回 `1`），关闭 IDM 的自动更新检查
- **效果**：IDM 不再反复弹"发现新版本 / 请更新"的提示窗；也不会自动升级到新版本导致激活失效
- **代价**：停留在当前版本后，不再获得官方的修复与新功能；想更新时先选 `[5]` 恢复即可
- **说明**：只改这一个开关值，不写序列号、不动 CLSID，与激活状态互不影响；执行前会先关闭正在运行的 IDM 让设置生效

## 使用场景

| 你的情况 | 推荐做法 |
|----------|----------|
| 刚装好 IDM，只想让它能用 | 菜单 `[1]` 冻结试用期；从未领过试用期、想跳过它直接可用则选 `[2]` 激活 |
| 已经用 IDM 账号领了 30 天试用期，想把它固定住 | 菜单 `[1]` 冻结试用期 |
| 用 `[2]` 激活后 IDM 弹"未注册 / 假序列号" | 先 `[3]` 重置，再 `[1]` 冻结（见 [Q13](#q13)） |
| 升级 IDM 后激活失效 | `[3]` 重置 → 重新 `[1]` 冻结（或 `[2]` 激活），再用 `[4]` 关掉自动更新 |
| IDM 反复弹"发现新版本" | 菜单 `[4]` 禁用更新提示，需要时 `[5]` 恢复 |
| 自己有多台机器，想免交互执行 | `IAS.cmd /frz /silent /log=C:\Temp\ias.log`，按退出码判断结果 |
| 想改回原样、不再使用本脚本 | `[3]` 重置，或导入 `C:\Windows\Temp` 下的 `.reg` 备份还原 |
| 想研究 Windows 批处理 / 注册表 ACL / GBK 控制台兼容 | 直接读 `IAS.cmd`，结构说明见 [ARCHITECTURE.md](./ARCHITECTURE.md) |

**不适合的场景**：公司/学校受管设备（WDAC、AppLocker 会拦截）、服务器批量部署、macOS 与 Linux、以及任何需要商业授权凭证的正式生产环境——这些情况请购买 IDM 正版授权。

## 常见问题

<a id="q1"></a>
<details>
<summary><b>Q1: 提示"需要管理员权限"怎么办？</b></summary>

**解决方法：**
- 右键脚本文件
- 选择"以管理员身份运行"
- 不要直接双击运行

</details>

<a id="q2"></a>
<details>
<summary><b>Q2: 提示"IDM 未安装"/未找到 IDM 安装路径？</b></summary>

**解决方法：**
1. 先确认 `IDMan.exe` 已存在，常见路径是 `C:\Program Files (x86)\Internet Download Manager\IDMan.exe` 或 `C:\Program Files\Internet Download Manager\IDMan.exe`。
2. 自检里显示的 `HKLM\SOFTWARE\...\Internet Download Manager` 是 Windows 注册表项名称，不是网络连接；关闭互联网不会改变这个结果。
3. 如果自检提示"未在注册表找到 IDM 安装路径"，通常是 IDM 安装不完整、绿色版未写注册表，或当前用户下的 `ExePath` 没有写入。请先重新安装官方 IDM，再运行 `开始激活.cmd`。
4. 官方下载：https://www.internetdownloadmanager.com/download.html

</details>

<a id="q3"></a>
<details>
<summary><b>Q3: IDM 激活后仍提示"未注册"怎么办？</b></summary>

**解决方法：**
1. 改用 `[1]` "冻结试用期"选项——它不写序列号，最不容易被 IDM 判定为"假序列号"而重复弹注册窗
2. 或先选 `[3]` "重置激活"，再重新选 `[2]` 激活
3. 完全卸载 IDM 后重新安装，再激活

</details>

<a id="q4"></a>
<details>
<summary><b>Q4: 运行脚本时中文菜单显示为乱码？</b></summary>

**解决方法：**
1. 菜单与提示均为 GBK + `chcp 936`，正常中文系统不会乱码。旧版控制台（"使用旧版控制台"勾选时）下，个别带颜色的提示会以无颜色的纯文本显示，中文仍然正确。
2. 如仍有个别乱码，在 CMD 中运行 `chcp 936` 后重试。
3. 确保系统区域设置为中国或简体中文。

</details>

<a id="q5"></a>
<details>
<summary><b>Q5: 提示"无法连接到 internetdownloadmanager.com"？</b></summary>

**解决方法：**
1. 检查网络连接
2. 关闭 VPN 或代理
3. 配置系统代理设置
4. 临时关闭防火墙测试

</details>

<a id="q6"></a>
<details>
<summary><b>Q6: PowerShell 被组织策略禁用或处于受限语言模式？</b></summary>

**解决方法：**
- 联系本机/域管理员解除限制
- 在 PowerShell 终端执行 `Set-ExecutionPolicy RemoteSigned`（需管理员权限）
- 如为公司设备，建议在个人设备上使用

</details>

<a id="q7"></a>
<details>
<summary><b>Q7: Windows 11 24H2 上脚本是否可用？</b></summary>

**解决方法：**
- 24H2 默认启用 SmartScreen 与云保护，首次运行时可能弹出"已阻止"提示
- 右键 `开始激活.cmd` → 属性 → 底部勾选"解除锁定"，再以管理员身份运行
- 若 PowerShell 在 ConstrainedLanguage 模式下被限制，`开始激活.cmd` 的环境自检会明确指出对应检查项失败，按提示处理即可

</details>

<a id="q8"></a>
<details>
<summary><b>Q8: Windows Defender / 第三方杀软拦截脚本？</b></summary>

**解决方法：**
- 本脚本涉及注册表写入、WMI 查询与 PowerShell 提权，启发式引擎可能产生误报
- 如果信任本仓库发布的 `release` 产物（可用 `release/IDM-Activation-Script.zip.sha256` 校验），可把解压目录加入 Defender 排除项再运行
- 校验命令：PowerShell 里 `Get-FileHash IDM-Activation-Script.zip -Algorithm SHA256`，与 `.sha256` 文件内容比对

</details>

<a id="q9"></a>
<details>
<summary><b>Q9: 企业环境启用了 WDAC / AppLocker，脚本直接拒绝执行？</b></summary>

**解决方法：**
- WDAC 或 AppLocker 策略通常会阻止未签名脚本运行，这是企业 IT 的策略层拦截，不是脚本本身的问题
- 正确处理方式是联系 IT 获取授权，不建议绕过
- 个人设备上不存在此问题

</details>

<a id="q10"></a>
<details>
<summary><b>Q10: IDM 6.42 / 6.43 等较新版本是否兼容？</b></summary>

**解决方法：**
- 本脚本基于 IDM 注册表 CLSID 结构工作，IDM 6.x 系列整体保持兼容
- **主菜单会直接标出"已适配 IDM `<版本>`"和"本机检测到的 IDM `<版本>`"**（`开始激活.cmd` 的环境自检里也会打印本机 IDM 版本），不再是模糊的"支持最新版"；两者不一致时菜单会给出提示，但不代表一定不能用——IDM 6.x 之间差异通常很小，可以照常尝试
- 若更新 IDM 后发现激活失效，建议先在菜单选 `[3]` 执行"重置激活"（或 `IAS.cmd /res`），再重新选择 `[2]` "激活"；若激活后仍提示未注册，改用 `[1]` "冻结试用期"
- 仍不生效时，请在 Issue 中带上 `开始激活.cmd` 的环境检测输出与 IDM 具体版本号

</details>

<a id="q11"></a>
<details>
<summary><b>Q11: 冻结或激活后 IDM 自己又启动，是脚本一直在后台运行吗？</b></summary>

**说明与处理：**
- 脚本不是常驻程序，执行完成后不会留后台进程。
- 冻结/激活流程可能会短暂启动 IDM 做状态验证；如果 IDM 之后又自己出现，通常是 IDM 自身的启动项、托盘驻留、浏览器集成或计划任务行为。
- 可以在 IDM 设置里关闭"开机启动"/托盘相关选项，并在任务管理器的"启动应用"里确认 IDM 没有被设置为开机启动。
- 如仍异常，请在 Issue 中补充 `开始激活.cmd` 完整环境检测输出、实际运行入口、IDM 版本和复现步骤；只写 `1` 或空日志无法判断脚本问题。

</details>

<a id="q12"></a>
<details>
<summary><b>Q12: 脚本一直卡在"正在初始化…"不动怎么办？</b></summary>

**原因：** "正在初始化…"之后脚本会做系统信息探测（WMI/CIM）、获取用户 SID、校验注册表访问。个别新版 Windows（如 Win11 24H2/25H2）上，旧版 `Get-WmiObject`（走 DCOM/RPC）在 WMI 仓库异常或被安全软件挂钩时可能长时间卡住，看起来就是"卡在初始化"。

**解决方法：**
1. 脚本的系统信息探测优先用 `Get-CimInstance`，失败才回退旧版 WMI，并在初始化时打印分步进度（`检测系统信息` / `获取用户账户 SID` / `校验注册表访问`），卡住时能一眼看出卡在哪一步。
2. 若仍卡住，多为本机 WMI 仓库损坏：管理员 CMD 里执行 `winmgmt /verifyrepository`，异常时 `net stop winmgmt` 后 `winmgmt /salvagerepository`，再重试。
3. 临时退出杀毒/安全软件的实时防护后重试，排除其对 WMI/PowerShell 的挂钩。
4. 反馈时请附上卡住时脚本显示到哪一行进度，便于定位。

</details>

<a id="q13"></a>
<details>
<summary><b>Q13: 用 [2] 激活后弹出"假序列号已被封锁 / 请购买 IDM / 剩余 0 天"怎么办？</b></summary>

**原因：** `[2]` 激活会写入一个随机序列号；IDM 联网校验后可能把它判定为"假序列号"，从而弹出提示并回落到试用/购买页面。这是随机序列号方式的固有风险，并非脚本出错。

**解决方法：**
1. 改用 `[1]` **冻结试用期**：它**不写入任何序列号**，而是冻结 IDM 的试用期跟踪，不会触发联网序列号校验，因此不会再被判"假序列号"，在 IDM 6.42+ 上最稳定。
2. 切换前先选 `[3]` **重置激活**清掉旧的随机序列号，再选 `[1]` 冻结。
3. 若之前已领取并在用 30 天试用期，直接用 `[1]` 冻结把试用期固定住即可。

</details>

<a id="q14"></a>
<details>
<summary><b>Q14: 激活后浏览器打不开某些网页（如 1panel 面板/内网管理页），重置后恢复正常？</b></summary>

**说明：** 本脚本**不修改 hosts、防火墙、系统代理，也不拦截任何网络**，只操作 IDM 相关注册表项。因此这类"某些网页打不开"通常来自 **IDM 浏览器集成模块**：激活后 IDM 处于工作状态，其浏览器扩展会监控页面请求，遇到长连接/流式响应/特定资源（部分面板类页面）时可能接管或干扰，导致页面加载异常；`[3]` 重置后 IDM 回到未激活状态、集成模块不再介入，于是恢复。

**解决方法：**
1. 在浏览器里**临时停用 IDM Integration Module 扩展**，或在 IDM → 选项 → 常规 里取消勾选对应浏览器的集成，再访问该页面验证。
2. 在 IDM → 选项 → 站点管理 / 文件类型 里，把该面板域名或该类型加入**不接管**列表。
3. 若确认与 IDM 集成无关（停用扩展仍打不开），请在 Issue 中附上该页面地址类型、浏览器版本与是否走了代理，便于进一步排查。

</details>

<a id="q15"></a>
<details>
<summary><b>Q15: IDM 老是弹"发现新版本/请更新"，能不能关掉？</b></summary>

**说明：** IDM 默认会定期联网检查新版本并弹窗提示；而且一旦真的升级到新版，本脚本写入的激活状态经常会失效，需要重新运行一次。

**解决方法：**
1. 运行 `开始激活.cmd`，在菜单里选 **`[4]` 禁用 IDM 更新提示**（命令行等价：`IAS.cmd /noupd`）。脚本会把注册表 `HKCU\Software\DownloadManager` 下的 `CheckUpdtVM` 置为 `0`，IDM 就不再自动检查更新，也不会再弹更新窗。
2. 需要恢复时选 **`[5]` 恢复 IDM 更新提示**（`IAS.cmd /reupd`），该值会改回 `1`。
3. 执行时脚本会先结束正在运行的 `IDMan.exe`，设置在 IDM 下次启动时生效；如果弹窗仍出现，先确认 IDM 已完全退出（托盘图标也要退出）再重开。
4. 这一步只改更新检查开关，不写序列号、不动 CLSID，不会影响已有的激活或冻结状态。

</details>

<a id="q16"></a>
<details>
<summary><b>Q16: Edge / Chrome 里的 IDM 扩展图标变灰、右下角带红叉，不能接管下载？</b></summary>

**说明：** 这是 IDM 自己的**浏览器集成**（IDM Integration Module 扩展 ↔ 本机 IDM 程序）没有连上，不是激活脚本的功能。脚本只把注册表 `AdvIntDriverEnabled2` 写回 `1`（打开 IDM 的高级浏览器集成开关），既不安装、不更新、也不禁用任何浏览器扩展。

**先看自检输出：** 运行 `开始激活.cmd` 时，环境检测会打印一行 `IDM 浏览器集成开关`。这个键（`AdvIntDriverEnabled2`）是浏览器集成与本脚本**唯一的交集**，先看它就能判断问题在哪一侧：

- 显示 `[√] IDM 浏览器集成开关已开启` → **脚本这一侧没有问题**，直接从下面第 1 步开始排查 IDM 与扩展；
- 显示 `[i] ... 当前为 0x0` 或 `[i] 未读到 ...` → 跑一次菜单 `[2]` 激活，脚本会把它写回 `1`，然后重启 IDM 再看扩展。

注意：这个开关为 `1` 只代表 IDM 的集成总开关是开的，**不代表扩展一定能连上** —— 扩展与 IDM 之间还要版本匹配、IDM 在运行、注册状态正常。所以开关正常时仍需按下面的步骤排查。

**按顺序排查：**
1. **先确认 IDM 正在运行**。激活 / 冻结 / 重置流程的最后一步会结束 `IDMan.exe`，脚本跑完 IDM 是关着的。手动启动 IDM，再刷新网页并重新加载扩展。
2. **确认扩展和 IDM 版本匹配**。商店里的 IDM Integration Module 会自动更新，一旦扩展比本机 IDM 新（或本机 IDM 太旧），扩展就会显示灰色报错。把 IDM 升级到与扩展相近的版本，或从 IDM 安装目录里手动加载扩展。升级 IDM 后激活可能失效，重新跑一次脚本即可；不想被自动升级打扰可以用菜单 `[4]`（见 [Q15](#q15)）。
3. **确认 IDM 里的集成开关是开的**：IDM → 选项 → 常规 → 勾选对应浏览器（Edge / Chrome）的集成，保存后**完全退出浏览器**（含托盘和后台进程）再打开。
4. **确认 IDM 处于正常注册状态**。IDM 判定"假序列号"后会限制自身功能，扩展也会跟着报错。若 IDM 主界面弹注册窗或提示序列号被封锁，先按 [Q13](#q13) 用 `[3]` 重置 + `[1]` 冻结，再看扩展。
5. **确认装 IDM 的 Windows 账户和用扩展的账户是同一个**。集成信息写在 `HKCU` 下，用另一个账户装的 IDM 在当前账户里集成不上；换回原账户或以当前账户重装 IDM。
6. 上面都试过仍是灰色报错，属于 IDM 自身的集成问题（通常重装 IDM 可修复）。若要在本仓库反馈，请附上**扩展图标点开后的完整报错文字**、IDM 版本号（运行 `开始激活.cmd` 时会打印）、浏览器与扩展版本，只写"灰色报错"无法定位。

</details>

<a id="q17"></a>
<details>
<summary><b>Q17: 环境检测全绿后清屏，一闪而过「拒绝访问。」进不了菜单？</b></summary>

**原因：** 环境自检通过后会进入 `IAS.cmd`。交互模式为关闭 QuickEdit，会执行 `start conhost.exe` 再拉起一次脚本。Win11 25H2 或安全软件/策略拦截时，`start` 失败，cmd 只打印系统文案「拒绝访问。」（脚本本身没有这句），窗口很快关掉。

**你现在可以这样处理：**
1. **正常情况下不该出现**：重入失败会自动在当前窗口继续并给出中文警告，不会裸闪退。若仍遇到，请附环境检测输出反馈。
2. 临时绕过（任意版本）：管理员 CMD 进入脚本目录后执行 `IAS.cmd -qedit`，跳过 conhost 重入直接进菜单。
3. 若仍失败：查 Windows 安全中心「保护历史记录」是否拦截了 `conhost`/`powershell`/`cmd`；临时排除脚本目录或关掉第三方杀软后再试。

</details>

<a id="q18"></a>
<details>
<summary><b>Q18: 激活/冻结后过一两天又弹「免费试用已到期」或「请注册」？</b></summary>

**原因：** IDM 会周期性联网校验注册状态。`[2]` 激活写入的随机序列号被 IDM 服务器判定为无效后，会重新弹出试用到期或注册窗口；`[1]` 冻结锁住的 CLSID 键也可能在 IDM 自动更新后被重写。

**解决方法：**
1. 先运行 `[3]` **重置激活**，清掉旧状态。
2. 改用 `[1]` **冻结试用期**（不写序列号，不触发联网校验，最稳）。
3. 同时选 `[4]` **禁用 IDM 更新提示**，防止 IDM 自动升级后覆盖冻结状态。
4. 若仍然复发，完全卸载 IDM → 重装 → `[3]` 重置 → `[1]` 冻结 → `[4]` 禁用更新。

</details>

<a id="q19"></a>
<details>
<summary><b>Q19: 环境检测全部通过后黑屏卡死，任务管理器里 powershell.exe 一直不退出？</b></summary>

**原因：** `IAS.cmd` 中 `powershell.exe` 的调用缺少 `-NoProfile -Command` 参数。在真实控制台（stdin 为控制台设备）下，裸 `powershell.exe "..."` 不会执行引号内的命令，而是进入交互模式永久等待输入，导致黑屏卡死。`开始激活.cmd` 的环境检测已带 `-NoProfile -Command`，所以能正常通过，问题只出现在进入 `IAS.cmd` 之后。

**解决方法：**
1. 更新到最新版本（此问题已在 `IAS.cmd` 中修复）。
2. 临时绕过：管理员 CMD 进入脚本目录后执行 `IAS.cmd -qedit`。

</details>

## 技术细节

### 工作原理

以 `[1]` 冻结 / `[2]` 激活为例，实际执行顺序是：

1. **前置检查 + 备份**：确认 `IDMan.exe` 存在、能连通 internetdownloadmanager.com（任一不满足即以退出码 `1` 退出，不动注册表），随后结束正在运行的 IDM，把当前 CLSID 注册表分支导出到 `%SystemRoot%\Temp`
2. **清理**：删除 `HKCU\Software\DownloadManager` 下的注册信息与试用计数值
3. **恢复集成开关**：把 `AdvIntDriverEnabled2` 写回 `1`
4. **锁定**：扫描出 IDM 用来记录试用状态的 CLSID 键，取得所有权后加 Deny ACL 锁住（数量超过 20 个时改为直接删除）
5. **写入注册信息**：仅 `[2]` 激活模式执行，随机生成姓名 / 邮箱 / 序列号写入注册表；`[1]` 冻结模式跳过这一步，因此不会触发 IDM 的假序列号判定
6. **验证 + 再锁一次**：调用 IDM 下载几张官网小图片确认下载功能正常，然后重新执行一次锁定

`[3]` 重置是第 1、2 步 + 删除（而非锁定）CLSID 键 + 第 3 步；`[4]` / `[5]` 是独立分支，只改 `CheckUpdtVM` 一个值。

### 涉及的注册表位置

脚本只读写下面这些位置，不碰 hosts、防火墙、系统代理或任何 IDM 程序文件：

| 位置 | 用途 |
|------|------|
| `HKCU\Software\Classes\CLSID`（64 位系统走 `Wow6432Node\CLSID`） | IDM 藏试用期跟踪信息的键；激活/冻结时取得所有权后加 Deny ACL 锁住（识别出的键超过 20 个时改为直接删除），重置时删除 |
| `HKU\<SID>\Software\Classes\CLSID` | 当 `HKCU` 与 `HKU\<SID>` 未同步时的等价路径 |
| `HKCU\Software\DownloadManager` 下的 `FName` `LName` `Email` `Serial` `scansk` `tvfrdt` `radxcnt` `LstCheck` `ptrk_scdt` `LastCheckQU` | 注册信息与试用计数；激活时写入，重置时删除 |
| `HKCU\Software\DownloadManager` 下的 `CheckUpdtVM` | 自动更新检查开关，仅 `[4]` / `[5]` 使用 |
| `HKLM\Software\Internet Download Manager` 下的 `AdvIntDriverEnabled2` | IDM 集成开关；清理注册表键后重新写回 `1` |
| `HKLM\SOFTWARE\Internet Download Manager` 的 `InstallFolder`、`HKCU\Software\DownloadManager` 的 `ExePath` | **只读**，用于定位 IDM 安装路径 |

### 退出码

无人值守 / 脚本化调用时可据此判断结果：

| 退出码 | 含义 |
|--------|------|
| `0` | 正常完成（激活 / 冻结 / 重置 / 更新开关成功，或从菜单正常退出） |
| `1` | 进入业务流程但未成功：未检测到 IDM 安装、注册表读写失败、IDM 下载测试失败等 |
| `2` | 环境或参数错误：静默模式未带动作参数、系统版本不支持、缺 PowerShell、缺管理员权限、WMI 失败、临时目录被阻止运行等 |

`开始激活.cmd` 在自检发现问题且用户选择退出时返回 `1`；已经是管理员时透传 `IAS.cmd` 的退出码。若它需要先弹 UAC 提权，激活流程会在新进程里跑，原窗口无法回收退出码 —— 这种场景请以管理员身份直接调用 `IAS.cmd`。

### 注册表备份

脚本会自动备份注册表到以下位置：

```
C:\Windows\Temp\_Backup_HKCU_CLSID_[时间戳].reg
C:\Windows\Temp\_Backup_HKU-[SID]_CLSID_[时间戳].reg
```

**恢复方法：** 双击 `.reg` 文件即可导入恢复。脚本每次跑完（含失败退出）都会把本次备份的文件名模式打印在结尾，照着去 `C:\Windows\Temp` 找即可。

**注意：** 备份文件和运行日志**不会自动清理**，每运行一次就多一份（CLSID 分支导出可能有几 MB）。确认 IDM 工作正常后，可以自行删除 `C:\Windows\Temp` 下的 `_Backup_*_CLSID_*.reg` 与 `IAS-*.log`。

### 编码说明

- `.cmd` 脚本以 GBK（代码页 936）保存且不带 BOM，运行时强制切换控制台到同一代码页以保证中文显示；`使用说明.txt` 面向记事本阅读，以 UTF-8 + BOM 保存。
- 在 UTF-8 环境下阅读源码，可使用 `iconv -f GBK -t UTF-8 IAS.cmd`（或替换为其他文件名）或支持 GBK 的文本编辑器。
- 仓库通过 `.gitattributes` 固定 `.cmd`/`.txt` 为 CRLF 行尾，避免批处理因 LF 换行导致的校验错误。

### 安全性

- ✅ 不修改 IDM 程序文件
- ✅ 仅修改注册表配置
- ✅ 自动备份，可随时恢复
- ✅ 开源透明，代码可审查

## 文件说明

| 文件名 | 说明 |
|--------|------|
| `开始激活.cmd` | **新手唯一需要双击的主文件**：自动请求管理员权限 → 环境自检 → 弹出菜单（冻结 / 激活 / 重置 / 禁用更新提示） |
| `IAS.cmd` | 核心引擎（批处理，GBK 编码），被 `开始激活.cmd` 调用；也支持 `/frz` `/act` `/res` `/noupd` `/reupd` `/silent` `/log=` 参数 |
| `使用说明.txt` | 极简上手指南（UTF-8，Windows 记事本即可查看） |
| `README.md` | 当前完整图文说明 |
| `CHANGELOG.md` | 全部历史版本的详细变更记录 |
| `llms.txt` | 面向大语言模型与 AI 搜索引擎的结构化项目摘要（[llms.txt 约定](https://llmstxt.org)），中英双语，不随发布包分发 |
| `llms-full.txt` | llms.txt 的扩展版，包含完整功能列表、工作原理、FAQ 速查、文件清单等技术参考，同样不随发布包分发 |

## 更新日志

> 完整变更请查看 [`CHANGELOG.md`](./CHANGELOG.md)。

### v1.0.1 (当前版本) - 2026-08-06

主菜单区分「冻结试用期」与「激活」两种模式，文档推荐口径统一为冻结优先，并修正若干误译与文档事实错误。

### v1.0.0 - 2026-08-06

首个公开版本。`[1]` 冻结试用期、`[2]` 激活、`[3]` 重置、`[4]`/`[5]` 禁用/恢复 IDM 更新提示，
外加进菜单前的环境自检与注册表自动备份。全中文菜单，GBK + `chcp 936`，不修改 IDM 程序文件。

## 维护与贡献

- 贡献指南：[CONTRIBUTING.md](./CONTRIBUTING.md)
- 架构 / 结构说明：[ARCHITECTURE.md](./ARCHITECTURE.md)
- 开源维护策略：[OPEN_SOURCE_POLICY.md](./OPEN_SOURCE_POLICY.md)
- 维护 / 发布检查清单：[docs/maintenance-checklist.md](./docs/maintenance-checklist.md)
- Windows 冒烟基线：[docs/reports/smoke-win-baseline.md](./docs/reports/smoke-win-baseline.md)
- 安全漏洞上报：[SECURITY.md](./SECURITY.md)
- AI / LLM 摘要：[llms.txt](./llms.txt) 与 [llms-full.txt](./llms-full.txt) —— 改动菜单项、命令行参数、退出码、系统要求或限制条款时，需同步这两个文件，否则 AI 搜索引擎会引用到过期口径
- CI 校验脚本：[tools/validate.ps1](./tools/validate.ps1)（在 GitHub Actions 的 `Windows validation` 工作流中执行）
- 换行约束：[.gitattributes](./.gitattributes)（`*.cmd` / `*.txt` 为 CRLF；`*.md` / `*.yml` 为 LF）。编码由 [tools/validate.ps1](./tools/validate.ps1) 在 CI 中校验：`.cmd` 必须是无 BOM 的 GBK

## 相关链接

| 链接 | 说明 |
| --- | --- |
| [项目主页 / Repository](https://github.com/tytsxai/IDM-Activation-Script-Chinese) | IDM 激活脚本中文版 GitHub 仓库 |
| [最新版本下载 / Releases](https://github.com/tytsxai/IDM-Activation-Script-Chinese/releases/latest) | 下载 IDM-Activation-Script.zip |
| [问题反馈 / Issues](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues) | Bug 报告与使用帮助 |
| [文档索引 / Docs](./docs/README.md) | 用户与维护者文档入口 |
| [AI / LLM 结构化摘要](./llms.txt) | 面向 AI 搜索引擎的项目摘要（中英双语） |
| [IDM 官网](https://www.internetdownloadmanager.com) | Internet Download Manager 官方网站 |
| [上游原版（已归档）](https://github.com/WindowsAddict/IDM-Activation-Script) | 英文原始项目，2024-04 归档不再更新 |

## 搜索引擎与 AI 索引信息

本项目提供面向 AI 搜索引擎的结构化摘要，遵循 [llms.txt 约定](https://llmstxt.org)：

- [llms.txt](./llms.txt) — 项目摘要（中英双语），适合快速索引
- [llms-full.txt](./llms-full.txt) — 完整技术参考，包含功能列表、工作原理、FAQ、文件清单

**推荐 GitHub Topics**：`idm` `internet-download-manager` `idm-activation-script` `idm-trial-freeze` `windows-batch` `cmd-script` `powershell` `gbk` `cp936` `windows-11` `chinese-localization` `registry-tool`

## 免责声明

> **本脚本仅供学习和测试使用！**

- 本工具仅用于学习 Windows 注册表操作和批处理编程
- Internet Download Manager 是 Tonec Inc. 的商业软件，**本仓库与 Tonec Inc. 无任何隶属、授权或合作关系**，也不分发 IDM 安装包
- 请支持正版软件，购买官方授权
- 长期使用建议购买正版：https://www.internetdownloadmanager.com/buy_now.html
- 本仓库不提供也不宣称任何 Star 数、下载量、用户案例、性能对比或商业背书；文档只写仓库内可自行验证的内容

## 许可证

本项目以 **GNU General Public License v3.0（GPL-3.0）** 开源发布，完整条款见仓库根目录的 `LICENSE` 文件。

本中文版本基于上游项目 [WindowsAddict/IDM-Activation-Script](https://github.com/WindowsAddict/IDM-Activation-Script) 演进，当前中文版本由本仓库独立维护。

> 上游状态：原始项目 `WindowsAddict/IDM-Activation-Script` 已于 2024-04 归档，不再接受更新；早期文档里引用过的 `lstprjct/IDM-Activation-Script` 镜像仓库已从 GitHub 移除（访问返回 404）。因此本仓库的问题反馈与修复请直接提到本仓库的 [Issues](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues)，不要去上游提。

使用、修改或再分发本项目时，需遵循 GPL-3.0 的基本要求：

- 可自由使用、学习、修改与再分发脚本；
- 二次发布必须保留 GPL-3.0 许可证文本、版权声明与修改记录；
- 基于本项目派生的作品需以相同或兼容的 GPL 许可证发布；
- 作者不对脚本使用过程中产生的任何直接或间接损失承担责任，详见 `LICENSE` 中"NO WARRANTY"条款。

## 版本与维护

- 当前版本 **v1.0.1**（2026-08-06），文档与运行时脚本包同步。核心功能：`[1]` 冻结试用期（推荐）、`[2]` 激活、`[3]` 重置、`[4]`/`[5]` 禁用/恢复 IDM 更新提示。
- 由本仓库独立维护，基于真实使用反馈持续迭代，保持 GPL-3.0 开源。
- 运行所需文件全在仓库内，不下载任何第三方组件（`[1]` / `[2]` 收尾的 IDM 下载测试需要联网，见[系统要求](#系统要求)）；每次 push / PR 都会跑 Windows CI 校验编码、行尾与脚本冒烟（徽章见页首）。
