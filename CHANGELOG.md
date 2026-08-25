# 更新日志（CHANGELOG）

本文件记录 IDM 激活脚本中文版的全部对外变更。版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/) 风格：`主版本.次版本.修订号`。

- 格式：每个版本包含 `新增 / 改动 / 修复 / 文档 / 兼容性` 标签（按需出现）。
- 日期使用本地时区（Asia/Shanghai）。
- 最新版本置顶；已冻结版本不再回溯改动。

---

## 未发布（Unreleased）

### 修复
- **IAS.cmd 裸 powershell.exe 调用导致黑屏卡死** — `set psc=powershell.exe` 改为 `set "psc=powershell.exe -NoProfile -Command"`。在真实控制台下裸 `powershell.exe "..."` 会进入交互模式而非执行命令，导致环境检测通过后清屏黑屏、窗口永久无响应（[#4](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/4)）。
- **发布包滞后于仓库** — `release/IDM-Activation-Script.zip` 里的 `IAS.cmd` 仍是修复前的版本，README 首推的下载链接指向它，用户下到的是带黑屏卡死缺陷的脚本。已用 CI 产出的 `release-bundle-rebuilt` 重新覆盖，`tools/verify-release.ps1` 恢复通过（此前 CI 已连续三次因这一项失败）。

### 工程
- **新增文档同步守卫 `tools/check-docs.ps1`** — 从 `IAS.cmd` 提取命令行参数、退出码、菜单编号、内部标签与版本号，与文档比对，并校验所有 Markdown 的仓库内相对链接。CI 新增 `Verify documentation matches the scripts` 步骤执行它。守的是「脚本改了、文档还写着旧的」这类静默漂移——它不会让任何测试变红，却会让用户照着一份不存在的说明操作。规则见 `docs/doc-sync.md`。

### 文档
- **FAQ 新增 Q18/Q19** — Q18 覆盖「激活/冻结后过一两天又弹试用到期」（[#2](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/2)、[#5](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/5)）；Q19 覆盖「环境检测通过后黑屏卡死」（[#4](https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues/4)）。
- **建立完整文档体系** — 新增 `docs/modules.md`（关键模块与核心逻辑）、`docs/configuration.md`（配置说明）、`docs/reference/{cli,internals,registry}.md`（命令行契约 / 内部子程序 / 注册表与文件系统副作用）、`docs/deployment/{local,container,server}.md`（本地 / 容器与隔离环境 / 无人值守与批量）、`docs/operations.md`（运维与排错）、`docs/doc-sync.md`（同步规则）。`docs/README.md` 重写为完整索引，README 增加文档地图。
- **清理 Release / tag 删除后的失效引用** — 仓库不再使用 GitHub Releases 与 tag，`release/` 目录成为唯一下载入口。README 的版本徽章由 `github/v/release`（会渲染成 "none"）改为静态徽章并纳入 CI 校验；`releases/latest` 链接、"历史版本从对应 tag 的 Release Assets 取"等说法全部改写，`release/README.md` 补上从 git 历史取历史版本的方法。
- **修正与实现漂移的口径** — FAQ 条数 17 → 19（`docs/README.md`、`llms.txt`）；`IAS.cmd` 行数 1100 / 1264 → 约 1270（`ARCHITECTURE.md`、README、`llms-full.txt`）；`ARCHITECTURE.md` 的 CI 数据流补齐非 ANSI 冒烟、伪造 IDM 冒烟、入口脚本冒烟与内嵌 PowerShell 段守卫四步；去掉行号引用（会漂移）改为按标签索引。
- **删除无法验证的断言** — `llms.txt` / `llms-full.txt` 中「已在 24H2 上验证通过」改为陈述支持范围，与 `docs/reports/smoke-win-baseline.md` 里「真实 IDM 环境回归待补」保持一致，也与 README 免责声明「只写仓库内可自行验证的内容」一致。
- **补上被漏记的行为** — `:delete_queue` 会删除**整个** `HKLM` 侧的 IDM 键（连同 `InstallFolder`），随后只把 `AdvIntDriverEnabled2` 写回；此前文档只写了「删注册信息与试用计数」。这解释了「跑过脚本后 IDM 路径探测回退到 `ExePath`」这一常被误判为故障的现象。
- **修正 Issue 模板的失效链接** — `config.yml` 里 FAQ 的锚点 `#-常见问题` 多了一个连字符，点进去落不到章节；同时新增排错指南入口。

---

## 文档更新 — 2026-08-06（无脚本变更）

仅文档与仓库元信息，**未改动任何脚本行为**，脚本版本仍为 `v1.0.1`。本次目标是让搜索引擎与 AI 搜索引擎能准确识别项目定位、功能边界与使用方式。

### 新增
- **`llms.txt`** — 面向大语言模型与 AI 搜索引擎的结构化项目摘要（[llms.txt 约定](https://llmstxt.org)），中英双语，涵盖项目事实、核心功能与参数、退出码、快速开始、限制、与上游的关系、文档与源码地图。不随发布包分发。
- **README「与上游原版的区别」章节** — 与上游归档态（仅 4 个文件、942 行、仅 `/act` `/frz` `/res`、无代码页处理）逐项对比，说明本仓库在中文化、入口自检、更新开关、无人值守与 CI 上的增量。
- **README 首屏英文定位段** — 供英文检索与 AI 抓取识别项目类型和能力边界。

### 修复
- **README 残留旧菜单文案** — 4 处仍写「激活（冻结）」/「冻结激活」，而 v1.0.1 起菜单实际显示「冻结试用期（推荐）」，用户照文档在菜单里找不到对应项。v1.0.1 统一了「推荐哪个选项」，但漏掉了「选项叫什么名字」。
- **环境自检项数口径不一致** — README 与 `ARCHITECTURE.md` 列的是 8 项，实际是 9 项（漏了「`IAS.cmd` 是否就位」）；三处文档已统一。

### 文档
- 17 条 FAQ 增加稳定锚点（`#q1`…`#q17`），交叉引用由指向整章的 `#常见问题` 改为精确跳转；Q2/Q3/Q4/Q6 标题补全为完整的问题句。
- 「功能特性」去掉空泛的「智能检测」，补入可脚本化调用（`/silent`、`/log=`、退出码）与注册表备份的具体落点。
- `docs/README.md` 补 `llms.txt` 入口与上游关系说明；`ARCHITECTURE.md` 补 `llms.txt` 的编码/行尾约束与「改了菜单/参数/退出码需同步」的维护约束。
- 仓库 description 改为中英双语并补入英文关键词；GitHub Topics 用 `trial-freeze`、`windows-registry`、`idm-activation` 替换零区分度的 `open-source` 与重复的 `gbk-encoding`、`batch`。

---

## v1.0.1 — 2026-08-06

修正主菜单两个模式的命名歧义，并把文档的推荐口径与脚本实际行为对齐。

### 改动
- **主菜单区分两种模式** — `[1]` 由「激活（冻结）」改为「冻结试用期（推荐）」，`[2]` 由「激活」改为「激活（写入注册信息）」。此前两项都叫「激活」，用户无法区分。
- **推荐口径统一为冻结优先** — README、`使用说明.txt`、`开始激活.cmd` 的进入提示与文档索引统一推荐 `[1]` 冻结试用期。此前文档推荐 `[2]` 激活，而脚本在执行激活前就会弹出「建议改用冻结」的提示，两者互相矛盾；上游项目归档时也已把冻结调整为首选。

### 修复
- 修正 `IAS.cmd` 中 fake serial 的误译「假阳性序列号」→「虚假序列号」，并删除「对某些用户而言（设置）」中的无意义残留。
- 「IDM 激活/重置功能已完成」改为「IDM 激活/重置已完成」。

### 工程
- **新增非 ANSI 控制台的回归守卫** — `:_color` / `:_color2` 依赖一个不易察觉的约定：颜色变量在支持 ANSI 转义的控制台上展开成**单个** token（`Red="41;97m"`），不支持时展开成**两个** token（`Red="Red" "white"`），于是同一处调用在两种模式下的文案参数位并不相同（分别是 `%2` 与 `%3`、`%2%4` 与 `%3%6`）。CI runner 永远走 ANSI 分支，把回退分支改错不会有任何征兆，直到 Windows 7/8/8.1 用户运行时才暴露。新增的守卫把 `HKCU\Console\ForceV2` 置 0，让脚本自己判定 `_NCS=0`，真正跑一遍回退分支并断言文案照常输出、不出现空 echo 与转义码。

### 文档
- 修正 README 中「所有 `.cmd`/`.txt` 使用 GBK」的错误表述 —— `使用说明.txt` 实为 UTF-8 + BOM（面向记事本阅读），此前与同一文件的文件说明表自相矛盾。
- 修正 README 中把编码约束归给 `.gitattributes` 的错误：它只约束行尾，编码由 `tools/validate.ps1` 在 CI 中校验。
- 移除 Star History 图表 —— 与免责声明中「不提供也不宣称任何 Star 数」直接冲突。
- 上游链接由已失效（404）的 `lstprjct/IDM-Activation-Script` 更正为原始项目 `WindowsAddict/IDM-Activation-Script`，并标注其已于 2024-04 归档。
- 仓库与云端介绍统一为中文，移除 `README.en.md` 与 `llms.txt`。

---

## v1.0.0 — 2026-08-06

首个公开版本。中文 Windows 环境下的 IDM 试用期冻结、激活、试用状态重置与更新提示开关，单个 `.cmd` 入口双击即用。

### 功能
- **`[1]` 冻结试用期** — 锁定 IDM 的试用期计数，使剩余天数不再减少。
- **`[2]` 激活** — 写入随机注册信息，无需账号或试用期，写入后直接可用。
- **`[3]` 重置激活 / 试用期** — 清除激活与试用状态，回到初始状态重来。
- **`[4]` / `[5]` 禁用 / 恢复 IDM 更新提示** — 改写 `HKCU\Software\DownloadManager` 下的 `CheckUpdtVM`，关掉 IDM 自动更新检查与"发现新版本"弹窗；顺带避免自动升级后激活失效。
- **环境自检** — `开始激活.cmd` 进菜单前检查管理员权限、PowerShell 语言模式、Null 服务、网络连通性、代码页、WMI/CIM、IDM 安装路径与版本、IDM 浏览器集成开关、脚本目录可写性，任一异常都给出中文说明和处理指引。
- **注册表自动备份** — 每次改注册表前导出备份到 `%SystemRoot%\Temp`，双击导入即可还原。
- **命令行参数** — `/act` `/frz` `/res` `/noupd` `/reupd` `/silent` `/log[=路径]`，可无人值守执行，退出码语义明确。

### 工程
- `.cmd` 脚本使用 GBK（CP936）编码且不带 BOM，运行时强制 `chcp 936`，避免中文控制台乱码；`使用说明.txt` 面向记事本阅读，用 UTF-8 + BOM 保存。全部 `.cmd` / `.txt` 统一 CRLF 行尾。
- 不修改 IDM 程序文件，不做二进制补丁，只依赖 Windows 自带组件（CMD / PowerShell / 注册表）。
- GitHub Actions（`windows-latest`）CI 覆盖：编码与行尾校验、各参数组合的退出码断言、日志文件名与路径、交互主菜单渲染、`开始激活.cmd` 主入口环境自检、内嵌 PowerShell 段的 GBK 解码与分割守卫、发布包与仓库一致性、仓库公开可见性守卫。
- GPL-3.0 开源，保持公开可审查、可再分发。
