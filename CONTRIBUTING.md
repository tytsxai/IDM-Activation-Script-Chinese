# 贡献指南（维护安全）

本仓库包含 Windows 批处理与中文文本文件。为避免“看起来没问题、实际在 Windows 上坏掉”的误改，提交前请遵守以下约束。

## 基本原则

- 不要在仓库中提交任何密钥、令牌、个人隐私或机器特征信息。
- 本仓库按 GPL-3.0 开源维护，文档、发布说明和派生说明都应保持公开可审查、可再分发的表达，不要把项目描述为私有或闭源分发。
- 任何变更都应能在 GitHub Actions 的 `Windows validation` 工作流中通过。
- 尽量保持改动小且可回滚：一次 PR 只做一件事（文档/CI/脚本逻辑请分开）。

## 编码与换行（最重要）

本仓库对文件的编码/换行有强约束：

- `*.cmd`：GBK（代码页 936，无 BOM）+ CRLF。这些字节会在 `chcp 936` 的控制台里直接 echo 出来，改成别的编码就是乱码。
- `*.txt`：CRLF。编码不强制 GBK —— `使用说明.txt` 是在记事本里打开的，不走控制台，所以它按 **UTF-8 + BOM** 保存（各语言版本的 Windows 记事本都能正确识别）。`tools/validate.ps1` 只对 `.cmd` 做 GBK 校验，原因写在脚本头部注释里。
- `llms.txt`：UTF-8 + LF（面向 AI 检索的跨平台文本，`.gitattributes` 里对 `*.txt` 的 CRLF 规则有单独覆盖）。
- `*.md`：UTF-8（无 BOM）+ LF
- `*.ps1`：UTF-8 **带 BOM** + LF。CI 用 `pwsh` 执行，但带 BOM 能保证 Windows PowerShell 5.1 也按 UTF-8 解码脚本里的中文，不会在英文区域的机器上变乱码。

相关约束由 `.gitattributes` 以及 `tools/validate.ps1` 强制校验，CI 不通过会直接阻止合并。

### 常见误区

- 不要把 `.cmd` / `.txt` 另存为 UTF-8（尤其是带 BOM 的 UTF-8），会导致控制台乱码并触发 CI 失败。
- 不要把 `.cmd` 改成 LF 换行，批处理在部分环境下会异常，且 `IAS.cmd` 内部也有 LF 检测。

## 本地自检（推荐）

在 Windows PowerShell / PowerShell 7 中运行：

```powershell
pwsh -NoProfile -File tools/validate.ps1        # 编码 / 换行 / cmd.exe 可用性
pwsh -NoProfile -File tools/verify-release.ps1  # 发布包与仓库是否一致、版本号是否自洽
```

若脚本报错，会通过 `::error` 输出具体文件与原因；修复后再提交。

改动了 `IAS.cmd` / `开始激活.cmd` / `使用说明.txt` 之后，`verify-release.ps1` 会失败——因为 `release/` 里的发布包还是旧的。**在 Windows 上**跑一次重新打包即可：

```powershell
pwsh -NoProfile -File tools/pack-release.ps1
```

手上没有 Windows 时，可以从 CI 的 `release-bundle-rebuilt` artifact 下载已经打好的包，放回 `release/` 一起提交。不要在 macOS / Linux 上用 `zip` 打包：中文文件名会写成 UTF-8 + 标志位，与现有发布包的 GBK 约定不同。

## CI 说明

- 工作流文件：`.github/workflows/ci.yml`
- 校验脚本：`tools/validate.ps1`（仓库卫生）、`tools/verify-release.ps1`（发布包一致性）
- 打包脚本：`tools/pack-release.ps1`（仅 Windows）
- 运行环境：GitHub-hosted Windows runner（`windows-latest`）
