# 文档同步规则 / Keeping Docs in Sync with Code

这个仓库的文档不是「写完就放着」的附属品：菜单文案、命令行参数、退出码、注册表键都直接出现在文档里，
脚本一改、文档不改，用户就会照着一份不存在的说明操作。历史上真实发生过——
**文档教用户选的选项，菜单里根本没有**，因为改了菜单文案却只同步了一部分文档。

本文规定两件事：**改了什么必须同步什么**（人工约定），以及**哪些同步由 CI 强制**（自动守卫）。

## 一、同步矩阵

改动左列时，右列的每一个文件都必须一并检查。带 🔒 的由 CI 强制，漏改会直接失败。

| 改了什么 | 必须同步 |
| --- | --- |
| **命令行参数**（新增 / 删除 / 改名） | 🔒 [`docs/reference/cli.md`](reference/cli.md)、🔒 `README.md`、🔒 `llms.txt`、🔒 `llms-full.txt`、`使用说明.txt`、[`docs/deployment/server.md`](deployment/server.md) |
| **退出码**（新增取值或改语义） | 🔒 [`docs/reference/cli.md`](reference/cli.md)、`README.md`、`ARCHITECTURE.md`、[`docs/operations.md`](operations.md)、`llms.txt`、`llms-full.txt` |
| **主菜单项编号或 `choice /C` 字符串** | 🔒 `README.md`（菜单示意框）、`使用说明.txt`、`llms.txt`、`llms-full.txt`、[`docs/reference/internals.md`](reference/internals.md) |
| **菜单项文案** | `README.md`、`使用说明.txt`、`llms.txt`、`llms-full.txt`、`docs/README.md` |
| **`IAS.cmd` 的标签**（新增 / 删除 / 改名） | 🔒 [`docs/reference/internals.md`](reference/internals.md)、[`docs/modules.md`](modules.md) |
| **读写的注册表键或文件** | [`docs/reference/registry.md`](reference/registry.md)、`README.md`（技术细节）、[`docs/modules.md`](modules.md) |
| **环境自检项** | `README.md`、`ARCHITECTURE.md`、[`docs/modules.md`](modules.md)、`llms.txt`、`llms-full.txt` |
| **系统要求、限制与注意** | `README.md`、`llms.txt`、`llms-full.txt`、[`docs/deployment/local.md`](deployment/local.md) |
| **`IAS.cmd` 的 `iasver`** | 🔒 `CHANGELOG.md` 顶部的 `## vX.Y.Z` 标题、🔒 `README.md` 的版本徽章与菜单示意框、🔒 `llms.txt`、🔒 `llms-full.txt` |
| **`IAS.cmd` 的 `idmsupport`** | 🔒 `README.md`（菜单示意框里的「已适配 IDM x.xx」）、`CHANGELOG.md`（说明验证环境） |
| **发布包清单**（`pack-release.ps1` 的 `$payload`） | `README.md`（文件说明表）、`tools/verify-release.ps1` 的 `$runtimeFiles`、[`docs/configuration.md`](configuration.md) |
| **CI 步骤** | `ARCHITECTURE.md`（CI 数据流）、[`docs/maintenance-checklist.md`](maintenance-checklist.md)、[`docs/reports/smoke-win-baseline.md`](reports/smoke-win-baseline.md) |
| **编码 / 行尾约束** | `.gitattributes`、`tools/validate.ps1`、`CONTRIBUTING.md`、[`docs/configuration.md`](configuration.md) |
| **分发方式**（Release、下载入口） | `README.md`、`release/README.md`、`ARCHITECTURE.md`、[`docs/maintenance-checklist.md`](maintenance-checklist.md)、[`docs/deployment/server.md`](deployment/server.md) |
| **新增 / 删除 `docs/` 下的文件** | `docs/README.md`（文档索引）、`README.md`（维护与贡献一节） |

### 为什么 `llms.txt` 和 `llms-full.txt` 值得单列

它们是给大语言模型与 AI 搜索引擎读的结构化摘要。**漏改不会有任何报错**，
但会让 AI 长期引用到过期口径——用户从 AI 那里得到的答案会和真实脚本对不上，而且没人会注意到。
所以参数、退出码、菜单、限制条款这四类改动，它们是强制同步项。

这两个文件**不随发布包分发**（不在 `pack-release.ps1` 的清单里），是仓库级文件。

## 二、自动守卫：`tools/check-docs.ps1`

在 CI 的 `Verify documentation matches the scripts` 步骤执行。它不检查文字是否通顺，
只检查**能机械验证的事实**是否一致。六组断言：

| # | 断言 | 从哪儿提取事实 |
| --- | --- | --- |
| 1 | 脚本接受的每一个命令行参数都在文档里有记录 | `IAS.cmd` 参数解析里的 `if /i "%%X"=="..."` 字面量 |
| 2 | 脚本用到的每一个退出码都在 `cli.md` 的退出码表里有一行 | `IAS.cmd` 里的 `call :set_exit <码>` |
| 3 | 主菜单的编号集合与 `choice /C` 字符串一致，且 `README.md` 的菜单示意框列出同一套编号 | `:MainMenu` 到 `choice /C:` 之间的 `[N]` |
| 4 | `IAS.cmd` 的每个标签在 `internals.md` 里有条目；`internals.md` 也不记录不存在的标签 | `IAS.cmd` 行首的 `:label` |
| 5 | `iasver` / `idmsupport` 与 `README.md`、`llms.txt`、`llms-full.txt` 里写的版本一致 | `IAS.cmd` 头部两个 `@set` |
| 6 | 所有 Markdown 文件里的仓库内相对链接都指向真实存在的文件 | 所有被 git 跟踪的 `.md` |

**它只做前向校验**（脚本 → 文档），唯一的反向校验是第 4 组的标签双向比对。
文档里的解释、示例、排错建议对不对，机器判断不了——那部分靠 [维护 / 发布检查清单](maintenance-checklist.md) 和 review。

### 本地跑一遍

```powershell
pwsh -NoProfile -File tools/check-docs.ps1
```

不依赖 `cmd.exe` 和注册表，**在 macOS / Linux 的 PowerShell 里也能跑**（`validate.ps1` 不行，它带 `cmd.exe` 探测）。

失败时按 `::error file=...::` 格式输出，在 PR diff 里能直接定位到文件。

### 新增了参数 / 标签 / 退出码怎么办

守卫失败不是让你去改守卫，而是提示你**文档还没跟上**：

1. 先按第一节的同步矩阵把文档补齐。
2. 只有当新增的东西**确实不该出现在文档里**（例如又一个内部重入标记），
   才去 `tools/check-docs.ps1` 里把它加进豁免列表，并在提交说明里写清楚为什么。

## 三、机器管不了的部分

这些只能靠人，列在 [维护 / 发布检查清单](maintenance-checklist.md) 里：

- 文档描述的**行为**是否与脚本实际行为一致（例如「冻结不写序列号」这类因果解释）。
- FAQ 的处理步骤在真实 Windows 上是否还有效。
- 截图 / 菜单示意框里的文案是否与实际界面一致（编号由 CI 守，文案不守）。
- `idmsupport` 是否**真的**在那个 IDM 版本上验证过——这个值的全部意义就是「我们真的验证过」，
  没实测就往上抬等于把文档写成假的。
- `docs/reports/smoke-win-baseline.md` 的记录表是否补了本次发版的行。

## 相关文档

- [维护 / 发布检查清单](maintenance-checklist.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
