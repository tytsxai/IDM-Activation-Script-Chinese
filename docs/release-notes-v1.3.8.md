# IDM 激活脚本中文版 v1.3.8 发布说明

- 版本：**v1.3.8**（2026-06-23）
- 类型：纯文档修订（运行时脚本与发布包零改动）
- 运行时发布包：沿用 `release/IDM-Activation-Script-v1.3.7.zip`（SHA256 不变）

## 本次变更

本版本不修改任何脚本，仅修正文档中会误导用户、或影响传统搜索引擎与 AI 搜索引擎正确理解项目的几处不一致：

| 类别 | 问题 | 处理 |
|---|---|---|
| 上游署名 | README 许可证段写作 `WindowsAddict/IDM-Activation-Script`，与 README 顶部、`llms.txt`、CHANGELOG 一致使用的 `lstprjct/IDM-Activation-Script` 冲突 | 统一为 `lstprjct/IDM-Activation-Script`，移除无法核实的归档日期，避免抓到互相矛盾的"事实来源" |
| 新手指引 | `docs/README.md` 仍写"新手在菜单选 `[1]` 冻结激活"，与 v1.3.6 起脚本实际推荐（默认 `[2]` 激活、`[1]` 仅作兜底）相反 | 对齐为 `[2]` 激活优先，命令示例改为 `IAS.cmd /act` |
| 文档索引 | `docs/README.md` 发布说明列表与 `ARCHITECTURE.md` 的 `docs/` 枚举只列到 v1.3.4/v1.3.5 | 补全 v1.3.5–v1.3.7 条目，使索引与实际文件一致 |

## 与 v1.3.7 的关系

v1.3.8 **不改动任何脚本或发布包**，`IAS.cmd` / `开始激活.cmd` 行为与 v1.3.7 完全一致，运行时包仍为 `IDM-Activation-Script-v1.3.7.zip`。已是 v1.3.7 运行时的用户**无需重新下载脚本**；本版本仅让仓库文档跨文件保持一致、定位更清晰。

## 验证建议

```powershell
.\tools\validate.ps1
Get-FileHash .\release\IDM-Activation-Script-v1.3.7.zip -Algorithm SHA256
```
