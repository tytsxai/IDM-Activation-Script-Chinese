# IDM 激活脚本中文版 v1.3.1（IDM Activation Script · 简体中文）

[![Windows validation](https://github.com/tytsxai/IDM-Activation-Script-Chinese/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/tytsxai/IDM-Activation-Script-Chinese/actions/workflows/ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPL_v3-blue.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/version-v1.3.1-brightgreen.svg)](./CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011-blue.svg)]()

> **一键激活 Internet Download Manager（IDM）的中文脚本工具**：支持 IDM 冻结试用期、随机注册信息激活、试用期一键重置三种模式，全程中文菜单与提示，无需安装任何依赖，单个 `.cmd` 文件即可在 Windows 7 / 8 / 10 / 11 上稳定运行。

## 📥 快速下载

- 最新版（推荐）：[IDM-Activation-Script-v1.3.1.zip](./release/IDM-Activation-Script-v1.3.1.zip)
- 校验值（SHA256）：[IDM-Activation-Script-v1.3.1.zip.sha256](./release/IDM-Activation-Script-v1.3.1.zip.sha256)
- 完整更新历史：[CHANGELOG.md](./CHANGELOG.md)

> 下载后在 PowerShell 中执行 `Get-FileHash .\IDM-Activation-Script-v1.3.1.zip -Algorithm SHA256`，与 `.sha256` 文件内的值比对一致再解压使用。

> **关键词**：IDM 激活、IDM 中文版、IDM 注册机、IDM 冻结试用期、IDM 试用期重置、Internet Download Manager 激活脚本、IDM Windows 激活、IDM 批处理激活、IDM 免费使用。

> **运行说明**：本工具通过批处理脚本调整 Windows 注册表键值以完成激活，不修改 IDM 任何程序文件，所有注册表变更前均会自动备份，可随时还原。请在合法授权且理解风险的前提下使用，并遵守所在地法律法规与 IDM 软件许可协议。

## 📋 目录

- [快速下载](#-快速下载)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [使用方法](#使用方法)
- [功能说明](#功能说明)
- [常见问题](#常见问题)
- [技术细节](#技术细节)
- [更新日志](#更新日志)
- [维护与贡献](#维护与贡献)
- [版本与维护](#版本与维护)
- [许可证](#许可证)

## ✨ 功能特性

- ✅ **支持最新版本** - 兼容所有 IDM 版本
- ✅ **三种激活模式** - 冻结激活、普通激活、重置功能
- ✅ **中文显示优化** - 全部批处理/文本使用 GBK 编码，运行时强制 `chcp 936`，避免控制台乱码
- ✅ **自动备份** - 安全备份注册表，随时可恢复
- ✅ **智能检测** - 自动检测系统环境和 IDM 状态
- ✅ **环境自检** - 附带环境检测脚本（管理员/PowerShell/Null 服务/网络/代码页）
- ✅ **无需破解** - 不修改 IDM 程序文件

> ⚠️ 提示：脚本文件使用 GBK 编码（便于 Windows 控制台显示），在 GitHub/Web IDE 中查看可能出现乱码，可用支持 GBK 的编辑器或 `iconv`。

## 💻 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 7/8/8.1/10/11 |
| 权限 | 管理员权限 |
| 依赖 | PowerShell (系统自带) |
| 网络 | 需访问 internetdownloadmanager.com |
| CMD 代码页 | 936 (GBK) |

## 🚀 使用方法

> 懒人三步（管理员身份）：`测试脚本.cmd` 自检 → 双击 `快速激活.cmd`（冻结）/ `普通激活.cmd` / `重置激活.cmd` 中对应入口 → 按提示完成即可。  
> 小贴士：`测试脚本.cmd` 会一次检查管理员权限、PowerShell 语言模式、Null 服务、网络连通性、代码页、WMI、IDM 路径与当前目录写权限，全程仅需本仓库文件。

### 方法一：图形界面（推荐新手）

1. **右键点击** `快速激活.cmd`（默认执行冻结激活）或 `IAS.cmd`
2. **选择** "以管理员身份运行"
3. **按照菜单提示操作**

```
┌─────────────────────────────────────┐
│   IDM 激活脚本主菜单                 │
├─────────────────────────────────────┤
│  [1] 激活（冻结）  ⭐ 推荐           │
│  [2] 激活                           │
│  [3] 重置激活/试用期                 │
│  [4] 下载 IDM                       │
│  [5] 帮助                           │
│  [0] 退出                           │
└─────────────────────────────────────┘
```

### 方法二：命令行（推荐高级用户）

以管理员身份打开 CMD，然后运行：

```cmd
# 冻结激活（推荐）
IAS.cmd /frz

# 普通激活
IAS.cmd /act

# 重置激活
IAS.cmd /res

# 静默模式 + 日志（无人值守）
IAS.cmd /frz /silent /log="C:\Temp\ias-frz.log"
```
> 说明：`/silent` 抑制菜单与等待，`/log=路径` 记录运行日志；未带 `/frz` `/act` `/res` 即开启静默将返回码 2。

## 📖 功能说明

### 🌟 激活（冻结）[推荐]

- **功能**：将 IDM 的 30 天试用期永久冻结
- **优点**：不会触发假阳性警告，最稳定
- **适用**：所有用户推荐使用

### ⚡ 激活

- **功能**：使用随机生成的注册信息激活 IDM
- **注意**：部分用户可能看到"假阳性序列号"警告
- **建议**：如遇警告，改用"激活（冻结）"

### 🔄 重置激活/试用期

- **功能**：清除所有激活信息，恢复初始状态
- **用途**：解决激活异常、更换激活方式

## ❓ 常见问题

<details>
<summary><b>Q1: 提示"需要管理员权限"怎么办？</b></summary>

**解决方法：**
- 右键脚本文件
- 选择"以管理员身份运行"
- 不要直接双击运行

</details>

<details>
<summary><b>Q2: 提示"IDM 未安装"？</b></summary>

**解决方法：**
1. 先安装 IDM
2. 官方下载：https://www.internetdownloadmanager.com/download.html
3. 安装完成后再运行激活脚本

</details>

<details>
<summary><b>Q3: 激活后仍提示注册？</b></summary>

**解决方法：**
1. 使用"激活（冻结）"选项
2. 或先执行"重置激活"，再重新激活
3. 完全卸载 IDM 后重新安装

</details>

<details>
<summary><b>Q4: 中文显示为乱码？</b></summary>

**解决方法：**
1. 本版本已修复所有乱码问题
2. 如仍有问题，在 CMD 中运行：`chcp 936`
3. 确保系统区域设置为中国或简体中文

</details>

<details>
<summary><b>Q5: 提示"无法连接到 internetdownloadmanager.com"？</b></summary>

**解决方法：**
1. 检查网络连接
2. 关闭 VPN 或代理
3. 配置系统代理设置
4. 临时关闭防火墙测试

</details>

<details>
<summary><b>Q6: PowerShell 被组织策略禁用？</b></summary>

**解决方法：**
- 联系本机/域管理员解除限制
- 在 PowerShell 终端执行 `Set-ExecutionPolicy RemoteSigned`（需管理员权限）
- 如为公司设备，建议在个人设备上使用

</details>

<details>
<summary><b>Q7: Windows 11 24H2 上脚本是否可用？</b></summary>

**解决方法：**
- 24H2 默认启用 SmartScreen 与云保护，首次运行时可能弹出"已阻止"提示
- 右键 `快速激活.cmd` → 属性 → 底部勾选"解除锁定"，再以管理员身份运行
- 若 PowerShell 在 ConstrainedLanguage 模式下被限制，`测试脚本.cmd` 会明确指出对应检查项失败，按提示处理即可

</details>

<details>
<summary><b>Q8: Windows Defender / 第三方杀软拦截脚本？</b></summary>

**解决方法：**
- 本脚本涉及注册表写入、WMI 查询与 PowerShell 提权，启发式引擎可能产生误报
- 如果信任本仓库发布的 `release` 产物（可用 `release/IDM-Activation-Script-v1.3.1.zip.sha256` 校验），可把解压目录加入 Defender 排除项再运行
- 校验命令：PowerShell 里 `Get-FileHash IDM-Activation-Script-v1.3.1.zip -Algorithm SHA256`，与 `.sha256` 文件内容比对

</details>

<details>
<summary><b>Q9: 企业环境启用了 WDAC / AppLocker，脚本直接拒绝执行？</b></summary>

**解决方法：**
- WDAC 或 AppLocker 策略通常会阻止未签名脚本运行，这是企业 IT 的策略层拦截，不是脚本本身的问题
- 正确处理方式是联系 IT 获取授权，不建议绕过
- 个人设备上不存在此问题

</details>

<details>
<summary><b>Q10: IDM 6.42 / 6.43 等较新版本是否兼容？</b></summary>

**解决方法：**
- 本脚本基于 IDM 注册表 CLSID 结构工作，IDM 6.x 系列整体保持兼容
- 若更新 IDM 后发现激活失效，建议先执行"重置激活"（`重置激活.cmd` 或 `IAS.cmd /res`），再重新选择"冻结激活"
- 仍不生效时，请在 Issue 中带上 `测试脚本.cmd` 输出与 IDM 具体版本号

</details>

## 🔧 技术细节

### 工作原理

1. **锁定/删除** CLSID 注册表键
2. **注入随机** 注册信息（激活模式）
3. **下载测试** 文件验证 IDM 功能
4. **冻结试用期**（冻结模式）

### 注册表备份

脚本会自动备份注册表到以下位置：

```
C:\Windows\Temp\_Backup_HKCU_CLSID_[时间戳].reg
C:\Windows\Temp\_Backup_HKU-[SID]_CLSID_[时间戳].reg
```

**恢复方法：** 双击 `.reg` 文件即可导入恢复

### 编码说明

- 所有 `.cmd`/`.txt` 文件使用 GBK（代码页 936）保存，并在运行时强制切换控制台到相同代码页以保证中文显示。
- 在 UTF-8 环境下阅读源码，可使用 `iconv -f GBK -t UTF-8 IAS.cmd`（或替换为其他文件名）或支持 GBK 的文本编辑器。
- 仓库通过 `.gitattributes` 固定 `.cmd`/`.txt` 为 CRLF 行尾，避免批处理因 LF 换行导致的校验错误。

### 安全性

- ✅ 不修改 IDM 程序文件
- ✅ 仅修改注册表配置
- ✅ 自动备份，可随时恢复
- ✅ 开源透明，代码可审查

## 📦 文件说明

| 文件名 | 说明 |
|--------|------|
| `IAS.cmd` | 主激活脚本（批处理，GBK 编码），支持 `/frz` `/act` `/res` `/silent` `/log=` 参数 |
| `快速激活.cmd` | 一键调用 **冻结激活** 模式，自动请求管理员权限（推荐新手） |
| `普通激活.cmd` | 一键调用 **普通激活** 模式（随机注册信息） |
| `重置激活.cmd` | 一键调用 **重置** 模式，清理当前激活与试用信息 |
| `测试脚本.cmd` | 环境自检（管理员 / PowerShell / Null 服务 / 网络 / 代码页 / WMI / IDM 路径 / 目录写权限） |
| `使用说明.txt` | 三步极简指南（GBK，Windows 记事本即可查看） |
| `README.md` | 当前完整图文说明 |
| `CHANGELOG.md` | 全部历史版本的详细变更记录 |

## 📝 更新日志

> 完整历史变更请查看 [`CHANGELOG.md`](./CHANGELOG.md)。下方仅保留最近两个版本的摘要。

### v1.3.1 (当前版本) - 2026-04-21

#### ✅ 已完成
- 新增 `普通激活.cmd` / `重置激活.cmd` 两个一键入口，与 `快速激活.cmd` 形成完整三件套
- `测试脚本.cmd` 在结尾显式打印"第一项未通过的检查"，帮助用户快速定位问题
- 修复 `快速激活.cmd` 在路径含单引号或特殊字符时 PowerShell 自动提权失败的问题
- 常见问题新增 4 条（Win11 24H2 / Defender / WDAC / IDM 6.42+）
- `SECURITY.md` 全文中文化，新增 `.github/ISSUE_TEMPLATE/bug_report.yml` 结构化 Bug 反馈模板
- CI 新增 `IAS.cmd /?` 冒烟探测，防止语法级回归进入主分支
- 发布包 `release/IDM-Activation-Script-v1.3.1.zip` 重打，校验值同步更新

### v1.3 - 2025-12-09

#### ✅ 已完成
- 新增静默/日志参数：`IAS.cmd` 支持 `/silent` 与 `/log=<路径>`，可在无人值守场景下抑制菜单交互并输出运行日志；`快速激活.cmd` 透传同样参数
- 环境检测强化：`测试脚本.cmd` 扩展 PowerShell/WMI/IDM 路径/目录写权限等 10 项检查，退出码按位汇总便于自动化解析
- CI 校验：新增 GitHub Actions（Windows）运行 `tools/validate.ps1`，强制批处理/文本文件保持 GBK 编码与 CRLF 行尾，并探测 cmd 语法可用性
- 文档补充：新增执行流程说明与 v1.3 冒烟计划草稿，便于在管理员环境下快速回归

### v1.2 - 2024-10-05

#### ✅ 已完成
- 脚本启动及关键交互中强制 `chcp 936`，并在执行 `cls` 后恢复代码页，保证 CMD 内中文显示正常
- 主菜单与提示信息中文化，保留激活（冻结/普通）与重置三种模式
- 保留自动注册表备份、网络检测与 CLSID 锁定等核心功能，单仓库即可完整使用
- 新增 `快速激活.cmd`（冻结模式快捷方式）、`测试脚本.cmd`（环境检测）、`使用说明.txt`（快速上手指南）
- `测试脚本.cmd` 补充 Null 服务、PowerShell 语言模式与 TCP 端口检测，失败时返回非零退出码
- `快速激活.cmd` 在缺少 PowerShell 时提示手动提权，并向上传递 IAS 的返回码
- 辅助批处理与文本全部统一为 GBK 编码，确保在中文 CMD 下无乱码

## 🧰 维护与贡献

- 贡献指南：`CONTRIBUTING.md`
- 架构/结构说明：`ARCHITECTURE.md`
- 维护检查清单：`docs/maintenance-checklist.md`
- 安全问题上报：`SECURITY.md`
- CI 校验脚本：`tools/validate.ps1`（在 GitHub Actions 的 `Windows validation` 工作流中执行）
- 编码/换行约束：`.gitattributes`（`*.cmd`/`*.txt` 为 CRLF；`*.md` 为 LF）

## 🌐 相关链接

- **项目主页**: https://github.com/tytsxai/IDM-Activation-Script-Chinese
- **IDM 官网**: https://www.internetdownloadmanager.com
- **问题反馈**: https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues

## ⚠️ 免责声明

> **本脚本仅供学习和测试使用！**

- 本工具仅用于学习 Windows 注册表操作和批处理编程
- 请支持正版软件，购买官方授权
- 长期使用建议购买正版：https://www.internetdownloadmanager.com/buy_now.html

## 📄 许可证

本项目以 **GNU General Public License v3.0（GPL-3.0）** 开源发布，完整条款见仓库根目录的 `LICENSE` 文件。

使用、修改或再分发本项目时，需遵循 GPL-3.0 的基本要求：

- 可自由使用、学习、修改与再分发脚本；
- 二次发布必须保留 GPL-3.0 许可证文本、版权声明与修改记录；
- 基于本项目派生的作品需以相同或兼容的 GPL 许可证发布；
- 作者不对脚本使用过程中产生的任何直接或间接损失承担责任，详见 `LICENSE` 中"NO WARRANTY"条款。

## 🔄 版本与维护

- 当前版本：**v1.3.1**（发布日期 2026-04-21）
- 维护状态：独立维护，根据真实使用反馈持续迭代脚本与文档
- 仓库文件自洽：所有依赖项已包含在仓库内，可离线运行，无需额外下载其他组件
- 中文编码约束：`.cmd` / `.txt` 强制 GBK + CRLF，`.md` 强制 UTF-8 + LF，由 GitHub Actions CI 自动校验，防止乱码误入主分支
