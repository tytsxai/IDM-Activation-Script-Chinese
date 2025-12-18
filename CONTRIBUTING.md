# 贡献指南（维护安全）

本仓库包含 Windows 批处理与中文文本文件。为避免“看起来没问题、实际在 Windows 上坏掉”的误改，提交前请遵守以下约束。

## 基本原则

- 不要在仓库中提交任何密钥、令牌、个人隐私或机器特征信息。
- 任何变更都应能在 GitHub Actions 的 `Windows validation` 工作流中通过。
- 尽量保持改动小且可回滚：一次 PR 只做一件事（文档/CI/脚本逻辑请分开）。

## 编码与换行（最重要）

本仓库对文件的编码/换行有强约束：

- `*.cmd`、`*.txt`：GBK（代码页 936）+ CRLF
- `*.md`：UTF-8（无 BOM）+ LF

相关约束由 `.gitattributes` 以及 `tools/validate.ps1` 强制校验，CI 不通过会直接阻止合并。

### 常见误区

- 不要把 `.cmd` / `.txt` 另存为 UTF-8（尤其是带 BOM 的 UTF-8），会导致控制台乱码并触发 CI 失败。
- 不要把 `.cmd` 改成 LF 换行，批处理在部分环境下会异常，且 `IAS.cmd` 内部也有 LF 检测。

## 本地自检（推荐）

在 Windows PowerShell / PowerShell 7 中运行：

`pwsh -NoProfile -File tools/validate.ps1`

若脚本报错，会通过 `::error` 输出具体文件与原因；修复后再提交。

## CI 说明

- 工作流文件：`.github/workflows/ci.yml`
- 校验脚本：`tools/validate.ps1`
- 运行环境：GitHub-hosted Windows runner（`windows-latest`）

