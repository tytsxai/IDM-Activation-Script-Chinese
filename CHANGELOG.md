# 更新日志（CHANGELOG）

本文件记录 IDM 激活脚本中文版的全部对外变更。版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/) 风格：`主版本.次版本.修订号`。

- 格式：每个版本包含 `新增 / 改动 / 修复 / 文档 / 兼容性` 标签（按需出现）。
- 日期使用本地时区（Asia/Shanghai）。
- 最新版本置顶；已冻结版本不再回溯改动。

---

## v1.3.6 — 2026-06-14

### 修复
- **环境自检"脚本目录不可写"误报**（对应 issue #11 #13 #14）：写入测试语句 `> "!writeTest!" echo test >nul 2>&1` 里的 `>nul` 会覆盖前面对测试文件的重定向，导致文件永远写不进去、`if exist` 永远为假，从而把任何可写目录都误报为"不可写"。已改为 `(echo test)> "!writeTest!" 2>nul`。
- **安装目录含 `(x86)` 时提权崩溃报"此时不应有 \Internet"**（对应 issue #12）：旧入口脚本的提权写法 `Start-Process -FilePath \"%~f0\"` 中的 `\"` 会让 CMD 提前闭合引号，使路径里的 `)` 被当作语法符号。新入口 `开始激活.cmd` 改用单引号包裹路径并以标签跳转避开括号块。
- **Win11 24H2/25H2 上 WMI 自检误报**（对应 issue #14）：`wmic` 在新版 Windows 已被移除，自检改为优先用 PowerShell `Get-CimInstance` 检测，`wmic` 仅作回退。
- 代码页自检改用 `chcp | find "936"`，避免不同区域/外壳下 `chcp` 输出格式差异导致的解析失败（对应 issue #12 中"当前代码页: ="）。
- **修复激活过程中的中文乱码**：`IAS.cmd` 的 `:_color` / `:_color2` 上色函数在不支持 ANSI 的旧版控制台（勾选"使用旧版控制台"或 `HKCU\Console\ForceV2=0`）下，会用 `powershell write-host '中文'` 输出，GBK 中文作为命令行参数传给 PowerShell 时编码不匹配而乱码。现改为该情况下直接 `echo` 纯文本（丢颜色但中文正确显示）。菜单主体是纯 `echo` 故不受影响。
- IDM 路径自检补充当前用户 `HKCU\Software\DownloadManager\ExePath` 与默认安装目录兜底，减少已安装 IDM 但 HKLM `InstallFolder` 缺失时的误报。

### 改动
- **大幅精简入口**：原 `测试脚本.cmd` / `快速激活.cmd` / `普通激活.cmd` / `重置激活.cmd` 四个脚本合并为单一的 `开始激活.cmd`。新手只需双击它：自动提权 → 环境自检 → 弹出 `IAS.cmd` 菜单（冻结 / 激活 / 重置 / 下载 / 帮助）任选。
- `IAS.cmd` 版本号升至 `1.3.6`（核心激活逻辑不变）。

### 文档
- **模式选择说明按用户状态区分**：没领过 30 天试用期 / 想直接能用 → `[2]` 激活（最常用）；已领取并在用 30 天试用期 → `[1]` 冻结（把试用期冻住）；`[2]` 激活后仍提示未注册时也用 `[1]` 冻结兜底。README / 使用说明.txt / llms.txt 同步。
- README、`llms.txt`、`ARCHITECTURE.md`、`docs/README.md`、Issue 模板全部更新为"单入口 `开始激活.cmd`"模型。
- `使用说明.txt` 改为 UTF-8（带 BOM）编码，修复在新版 Windows 记事本中可能出现的乱码；`tools/validate.ps1` 相应放宽：仅对 `.cmd` 强制 GBK，`.txt` 不再强制编码。
- README FAQ Q2 补充说明：`Internet Download Manager` 是注册表项/安装目录名称，不是互联网连接；关闭网络不会影响安装路径检测。

### 发布
- 新增 `release/IDM-Activation-Script-v1.3.6.zip` 与对应 `.sha256` 校验文件。

---

## v1.3.5 — 2026-05-25

### 修复
- 修复 `测试脚本.cmd` 对 `chcp` 输出的解析：Windows 会在代码页数字前保留空格，导致实际为 936 时仍被误判为"代码页非 936"。现在检测前会去掉空格，避免自检阶段对 CP936 的误报。

### 文档
- README FAQ 新增"IDM 自己又启动"说明，区分脚本短暂验证、IDM 自身托盘/启动项行为和需要继续补日志排查的情况。
- 新增 `docs/release-notes-v1.3.5.md`，记录本次运行时修复和验证方式。

### 发布
- 新增 `release/IDM-Activation-Script-v1.3.5.zip` 与同名 SHA256 校验文件。

---

## v1.3.4 — 2026-05-19

### 文档
- **新增 `llms.txt`**：面向 ChatGPT / Claude / Perplexity / Gemini 等 AI 搜索引擎的精炼项目索引，覆盖能做 / 不能做 / 常见问题 / 长尾搜索词。
- **README 顶部新增英文摘要区块**：面向英文搜索流量（"IDM Activation Script Chinese"、"GBK encoded IDM activator"），明确这是 lstprjct/IDM-Activation-Script 的中文本地化分叉，列出三种激活模式与与上游差异。
- **README 顶部新增 Release / llms.txt / Changelog / Issues 导航行**。

### 发布
- 文档专项发版，**脚本与压缩包未改动**，仍沿用 v1.3.3 的 `release/IDM-Activation-Script-v1.3.3.zip` 作为运行时产物。Tag `v1.3.4` 仅标记本次文档更新。
- 已使用 v1.3.3 的用户**无需重新下载**。

---

## v1.3.3 — 2026-04-27

### 文档
- README 新增「搜索与 AI 摘要」区块，用更直接的话说明项目是什么、适合解决哪些问题、应该先运行哪个脚本，方便小白用户和 AI 搜索引擎快速理解。
- 快速下载区同步到 `release/IDM-Activation-Script-v1.3.3.zip`，并更新 SHA256 校验说明。
- README 更新日志摘要同步到 v1.3.3，避免用户看到旧版本号后误以为项目没有继续维护。

### 发布
- 新增 `release/IDM-Activation-Script-v1.3.3.zip` 与同名 `.sha256` 校验文件。
- 本版本不改变脚本核心逻辑，主要价值是让用户更容易找到项目、看懂使用方式，并在下载后知道如何校验文件完整性。

---

## v1.3.2 — 2026-04-27

### 文档
- 在 README 许可证章节补充上游项目已归档的说明，明确本中文版本后续由当前仓库独立维护。

### 发布
- 补充 v1.3 旧发布包的 SHA256 校验文件，方便用户核对历史版本完整性。

---

## v1.3.1 — 2026-04-21

### 新增
- `重置激活.cmd`：一键调用 `IAS.cmd /res`，面向需要清理激活/试用状态的用户。
- `普通激活.cmd`：一键调用 `IAS.cmd /act`，与 `快速激活.cmd`（冻结）形成完整入口三件套。
- `.github/ISSUE_TEMPLATE/bug_report.yml`：结构化 Bug 反馈模板，强制带 Windows 版本、IDM 版本、`测试脚本.cmd` 退出码，降低排查成本。
- `.github/ISSUE_TEMPLATE/help.yml`：使用帮助/新手求助模板，降低"不是 bug 但不会用"场景的反馈门槛。
- `.github/ISSUE_TEMPLATE/config.yml`：关闭空白 Issue，引导用户先查 FAQ 与 CHANGELOG。
- `CHANGELOG.md`：将更新日志从 README / release-notes 抽离为唯一来源。
- README 新增"快速下载"区块，指向 GitHub Releases 页面和仓库直链；Badges 补齐平台徽章锚点。
- README 新增"第一次运行前必看"小节，预警 UAC / SmartScreen / 杀软误报等首次运行弹窗。

### 改动
- `测试脚本.cmd`：脚本结束时会明确打印"**第一项未通过的检查**"与建议查阅的 README 章节锚点，退出码语义保持不变，自动化脚本无感知升级。
- `快速激活.cmd`：重写 PowerShell 提权调用，使用 `-FilePath` 严格引号转义，修复路径含单引号或特殊字符时自动提权失败的问题。
- `使用说明.txt`：精简为"三步极简指南 + FAQ 指针"；"建议管理员身份"改为明确的**必读**提示，并补充首次运行弹窗清单。
- `README.md`：
  - 常见问题区新增 Win11 24H2、Defender 云保护拦截、WDAC/AppLocker 策略、IDM 6.42+ 兼容性四条；
  - "版本与维护"段落同步到 v1.3.1；
  - 文件说明表加入三个一键入口；
  - 系统要求表格去掉让小白困惑的"代码页 936"行（脚本已自动设置），改为明确标注"无需手动设置"；
  - "方法二：命令行"折叠到 `<details>` 里，让新手视线聚焦在"方法一：图形界面"上。
- `IAS.cmd`：在脚本头部新增"代码导航"注释块，列出参数解析、环境检测、激活/冻结/重置等主要代码段的大致行号区间，方便后续维护。

### 修复
- `快速激活.cmd` 在 `%~f0` 路径含单引号时 PowerShell `Start-Process` 报语法错误的问题。

### 文档
- `SECURITY.md` 全文中文化，涵盖私下上报渠道、信息要点、处理流程。
- 发布包 `release/IDM-Activation-Script-v1.3.1.zip` 重新打包，内含最新文档。

### CI
- `.github/workflows/ci.yml` 增加一步 `IAS.cmd /silent` 冒烟探测：在 `windows-latest` 上调用 `IAS.cmd /silent`（不带 `/frz` `/act` `/res` 任何动作参数），断言退出码为 `2`，验证脚本启动到参数解析这条最短路径正常工作，防止语法级回归进入主分支。

---

## v1.3 — 2025-12-09

### 新增
- `IAS.cmd` 支持 `/silent` 与 `/log=<路径>` 参数，可在无人值守场景抑制菜单交互并输出运行日志。
- `快速激活.cmd` 透传同样参数。
- `测试脚本.cmd` 扩展到 10 项检查，退出码按位汇总便于自动化解析。

### CI
- 新增 GitHub Actions（Windows runner）运行 `tools/validate.ps1`，强制 `.cmd`/`.txt` 保持 GBK 编码与 CRLF 行尾，并探测 `cmd.exe` 语法可用性。

### 文档
- 补充执行流程说明与 v1.3 冒烟计划草稿。

---

## v1.2 — 2024-10-05

### 新增
- `快速激活.cmd`（冻结模式快捷方式）、`测试脚本.cmd`（环境检测）、`使用说明.txt`（快速上手指南）。
- `测试脚本.cmd` 补充 Null 服务、PowerShell 语言模式与 TCP 端口检测，失败时返回非零退出码。

### 改动
- 脚本启动及关键交互中强制 `chcp 936`，并在执行 `cls` 后恢复代码页，保证 CMD 内中文显示正常。
- 主菜单与提示信息中文化，保留冻结/普通激活与重置三种模式。
- 保留自动注册表备份、网络检测与 CLSID 锁定等核心功能。

### 修复
- `快速激活.cmd` 在缺少 PowerShell 时提示手动提权，并向上传递 IAS 的返回码。
- 辅助批处理与文本全部统一为 GBK 编码，确保在中文 CMD 下无乱码。

---

## 更早版本

更早版本的改动散落在提交历史中，不再单独追溯。可通过 `git log --oneline` 查看完整时间线。
