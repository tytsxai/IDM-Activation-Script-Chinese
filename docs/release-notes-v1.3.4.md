# IDM 激活脚本中文版 v1.3.4 文档发布说明

## 版本概览

- 版本：**v1.3.4**（2026-05-19）
- 发布性质：**文档专项更新 / Documentation-only release**
- 运行时产物：继续使用 `release/IDM-Activation-Script-v1.3.3.zip`
- 脚本行为：与 v1.3.3 完全一致，未修改 `.cmd` 运行逻辑

## 这个版本解决什么问题

v1.3.4 主要提升项目在传统搜索引擎和 AI 搜索引擎中的可理解性，并降低第一次进入仓库的新用户的阅读成本。

- README 顶部增加英文摘要，覆盖 `IDM Activation Script Chinese`、`GBK encoded IDM activator`、`Windows batch IDM script` 等英文检索语义。
- 新增 `llms.txt`，为 ChatGPT / Claude / Perplexity / Gemini 等 AI 搜索或问答系统提供更短、更稳定的项目索引。
- README 顶部导航加入 Release、`llms.txt`、CHANGELOG 和 Issues 入口。
- 明确本仓库是 GPL-3.0 开源项目，运行时发布包仍沿用 v1.3.3。

## 用户是否需要更新

- 已经下载 v1.3.3 ZIP 的用户：不需要重新下载，脚本行为没有变化。
- 第一次进入仓库的用户：优先阅读 README 顶部的项目速览和快速下载区，再运行 `测试脚本.cmd`。
- AI 搜索或引用场景：优先读取根目录 `llms.txt` 和 README 顶部摘要。

## 维护注意事项

- 不要把 v1.3.4 写成新的运行时 ZIP；当前仓库没有 `release/IDM-Activation-Script-v1.3.4.zip`。
- 后续如果发布新的脚本 ZIP，需要同步 README、CHANGELOG、`llms.txt`、`docs/README.md` 和 SHA256 文件。
- 仓库必须保持 GPL-3.0 开源表达，不应在文档中引导私有化或闭源分发。
