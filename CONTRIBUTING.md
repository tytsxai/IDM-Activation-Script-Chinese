# 贡献指南（维护安全）

本仓库包含 Windows 批处理与中文文本文件。为避免“看起来没问题、实际在 Windows 上坏掉”的误改，提交前请遵守以下约束。

## 基本原则

- 不要在仓库中提交任何密钥、令牌、个人隐私或机器特征信息。
- 本仓库按 GPL-3.0 开源维护，文档、发布说明和派生说明都应保持公开可审查、可再分发的表达，不要把项目描述为私有或闭源分发。
- 任何变更都应能在 GitHub Actions 的 `Windows validation` 工作流中通过。
- 尽量保持改动小且可回滚：一次 PR 只做一件事（文档/CI/脚本逻辑请分开）。

## 文档同步约束

改动用户可见行为时，文档必须一并更新。历史上出现过「文档教用户选的选项，菜单里根本没有」——
因为改了菜单文案却只同步了一部分文档。

**完整的同步矩阵在 [docs/doc-sync.md](./docs/doc-sync.md)**，这里只给最常撞到的几条：

| 改了什么 | 需要同步 |
|----------|----------|
| 命令行参数 | `docs/reference/cli.md`、`README.md`、`llms.txt`、`llms-full.txt`、`使用说明.txt` |
| 退出码 | `docs/reference/cli.md`、`README.md`、`ARCHITECTURE.md`、`docs/operations.md` |
| 菜单项编号 / `choice /C` 字符串 | `README.md` 的菜单示意框、`使用说明.txt`、`llms.txt`、`llms-full.txt` |
| `IAS.cmd` 的标签 | `docs/reference/internals.md`、`docs/modules.md` |
| 读写的注册表键或文件 | `docs/reference/registry.md`、`README.md`（技术细节） |
| `IAS.cmd` 的 `iasver` | `CHANGELOG.md` 顶部版本号、`README.md` 版本徽章与菜单示意框、`llms.txt`、`llms-full.txt` |

**其中六类由 CI 强制**：`tools/check-docs.ps1` 会从脚本里提取命令行参数、退出码、菜单编号、
内部标签、版本号，与文档比对，并校验所有 Markdown 的仓库内相对链接。漏改直接失败，
错误信息会指出具体文件。

`llms.txt` 与 `llms-full.txt` 是给大语言模型与 AI 搜索引擎读的结构化摘要——漏改**不会有任何报错**，
但会让 AI 长期引用到过期口径，因此改动菜单、参数、退出码或限制条款时务必带上它们。

## 编码与换行（最重要）

本仓库对文件的编码/换行有强约束：

- `*.cmd`：GBK（代码页 936，无 BOM）+ CRLF。这些字节会在 `chcp 936` 的控制台里直接 echo 出来，改成别的编码就是乱码。
- `*.txt`：CRLF。编码不强制 GBK —— `使用说明.txt` 是在记事本里打开的，不走控制台，所以它按 **UTF-8 + BOM** 保存（各语言版本的 Windows 记事本都能正确识别）。`tools/validate.ps1` 只对 `.cmd` 做 GBK 校验，原因写在脚本头部注释里。
- `*.md`：UTF-8（无 BOM）+ LF
- `*.ps1`：UTF-8 **带 BOM** + LF。CI 用 `pwsh` 执行，但带 BOM 能保证 Windows PowerShell 5.1 也按 UTF-8 解码脚本里的中文，不会在英文区域的机器上变乱码。

相关约束由 `.gitattributes` 以及 `tools/validate.ps1` 强制校验，CI 不通过会直接阻止合并。

### 常见误区

- 不要把 `.cmd` / `.txt` 另存为 UTF-8（尤其是带 BOM 的 UTF-8），会导致控制台乱码并触发 CI 失败。
- 不要把 `.cmd` 改成 LF 换行，批处理在部分环境下会异常，且 `IAS.cmd` 内部也有 LF 检测。
- **PowerShell 调用禁止裸调用**：不要写 `powershell.exe "命令"`，必须带 `-NoProfile -Command`。裸调用在真实控制台下会进入交互模式挂死（见 [#4](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/4)）。`IAS.cmd` 中统一通过 `%psc%` 变量调用（已包含 `-NoProfile -Command`），新增调用写 `%psc% "命令"` 即可，**不要**再手动拼 `-NoProfile -Command`，否则参数会重复导致静默失败。

## 本地自检（推荐）

在 Windows PowerShell / PowerShell 7 中运行：

```powershell
pwsh -NoProfile -File tools/validate.ps1        # 编码 / 换行 / cmd.exe 可用性
pwsh -NoProfile -File tools/check-docs.ps1      # 文档与脚本是否同步、站内链接是否有效
pwsh -NoProfile -File tools/verify-release.ps1  # 发布包与仓库是否一致、版本号是否自洽
```

`check-docs.ps1` 与 `verify-release.ps1` 不依赖 `cmd.exe`，**在 macOS / Linux 的 PowerShell 里也能跑**；
`validate.ps1` 带 `cmd.exe` 探测，只能在 Windows 上跑完整。

若脚本报错，会通过 `::error` 输出具体文件与原因；修复后再提交。

改动了 `IAS.cmd` / `开始激活.cmd` / `使用说明.txt` 之后，`verify-release.ps1` 会失败——因为 `release/` 里的发布包还是旧的。**在 Windows 上**跑一次重新打包即可：

```powershell
pwsh -NoProfile -File tools/pack-release.ps1
```

手上没有 Windows 时，可以从 CI 的 `release-bundle-rebuilt` artifact 下载已经打好的包，放回 `release/` 一起提交。不要在 macOS / Linux 上用 `zip` 打包：中文文件名会写成 UTF-8 + 标志位，与现有发布包的 GBK 约定不同。

## CI 说明

- 工作流文件：`.github/workflows/ci.yml`
- 校验脚本：`tools/validate.ps1`（仓库卫生）、`tools/check-docs.ps1`（文档同步）、`tools/verify-release.ps1`（发布包一致性）
- 打包脚本：`tools/pack-release.ps1`（仅 Windows）
- 运行环境：GitHub-hosted Windows runner（`windows-latest`）
- 逐步骤含义见 [ARCHITECTURE.md 的「CI 数据流」](./ARCHITECTURE.md#ci-数据流维护者视角)

## 更多文档

- 仓库结构与高风险点：[ARCHITECTURE.md](./ARCHITECTURE.md)
- 脚本实际怎么跑（**改 `IAS.cmd` 前必读最后一节**）：[docs/modules.md](./docs/modules.md)
- 参数与退出码契约：[docs/reference/cli.md](./docs/reference/cli.md)
- 内部标签：[docs/reference/internals.md](./docs/reference/internals.md)
- 本地开发环境：[docs/deployment/local.md](./docs/deployment/local.md)
- 发版检查清单：[docs/maintenance-checklist.md](./docs/maintenance-checklist.md)
