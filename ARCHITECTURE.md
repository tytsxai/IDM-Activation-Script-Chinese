# 仓库结构与维护说明（架构视角）

本仓库是一个以 Windows 脚本为主的项目，重点维护目标是：在中文 Windows 控制台环境中稳定运行，并避免因为编码/换行/环境差异导致的“误改即坏”。

## 目录结构

- `.github/workflows/ci.yml`
  - GitHub Actions 工作流入口（Windows runner）。
  - 顺序执行仓库卫生校验（`tools/validate.ps1`：编码、换行、基础 `cmd.exe` 探测）、若干条脚本冒烟（`/silent` 最短路径、`/noupd` `/act` `/frz` 未装 IDM 路径、日志路径、交互主菜单渲染）与发布包一致性校验（`tools/verify-release.ps1`），最后重新打包并上传 artifact。逐条断言见下方「CI 数据流」。
- `.github/ISSUE_TEMPLATE/`
  - `bug_report.yml`：结构化 Bug 反馈模板，强制带 Windows / IDM / 脚本版本与 `开始激活.cmd` 的环境检测输出。
  - `help.yml`：使用帮助 / 新手求助模板。
  - `config.yml`：关闭空白 Issue，引导先看 FAQ 与 CHANGELOG。
- `tools/validate.ps1`
  - CI 校验脚本：强制 `.cmd` 为 GBK（936）且无 BOM（控制台输出需要）；`.txt` 不强制编码（记事本打开，`使用说明.txt` 用 UTF-8 BOM）；按 `.gitattributes` 检查行尾（CRLF/LF）；末尾跑一次轻量 `cmd.exe` 探测。
  - 目标是尽早在 CI 中阻止“编码/换行被编辑器自动改坏”的提交进入主分支。
- `IAS.cmd`
  - 主批处理脚本（约 1100 行），包含参数解析、环境探测、激活/冻结/重置流程、IDM 更新检查开关（`CheckUpdtVM`）、注册表备份与日志输出。
  - 头部含「代码导航」注释块，按行号区间标注主要代码段位置。
  - 头部两个版本变量：`iasver`（脚本自身版本，与 tag / CHANGELOG 顶部由 CI 守一致）、`idmsupport`（脚本最后实际验证过的 IDM 版本，主菜单据此显示"已适配 IDM x.xx"）。适配了新版 IDM 就更新 `idmsupport`，不要再回到"支持最新版"这类模糊文案。
  - 维护注意：该文件依赖 CRLF 行尾与 GBK 编码；部分环境/编辑器的自动转换会导致异常。脚本启动时会自检 LF/CRLF。
- `开始激活.cmd`（唯一入口）
  - 自动用 PowerShell 提权（单引号包裹路径，兼容含 `(x86)` 等特殊字符的目录）。
  - 内置 9 项环境自检：管理员权限、`IAS.cmd` 是否就位、PowerShell 可用性与语言模式、Null 服务、网络连通性、代码页、WMI/CIM、IDM 安装路径（附带打印 IDM 版本与 `AdvIntDriverEnabled2` 集成开关）、目录写权限。
  - 自检通过或用户确认后，`call IAS.cmd` 进入菜单（冻结 / 激活 / 重置 / 禁用更新 / 恢复更新 / 下载 / 帮助）；也接受 `/frz` `/act` `/res` `/noupd` `/reupd` `/silent /log=...` 等参数透传。
- `使用说明.txt`
  - 极简上手指南（UTF-8 BOM + CRLF），面向纯小白用户。
- `llms.txt`
  - 面向大语言模型与 AI 搜索引擎的结构化项目摘要（[llms.txt 约定](https://llmstxt.org)），中英双语，UTF-8 无 BOM + CRLF（受 `.gitattributes` 的 `*.txt eol=crlf` 约束）。
  - 内容是 README 的事实性压缩：项目定位、核心功能与参数、退出码、快速开始、限制、与上游的关系、文档与源码地图。
  - 维护约束：**不随发布包分发**（`tools/pack-release.ps1` 的清单里没有它，`verify-release.ps1` 只做「包内 → 仓库」单向比对，因此新增它不影响发布包校验）。改动菜单项、命令行参数、退出码、系统要求或限制条款时必须同步，否则 AI 搜索引擎会长期引用过期口径。
- `README.md` / `CHANGELOG.md` / `CONTRIBUTING.md` / `SECURITY.md` / `ARCHITECTURE.md`
  - README：用户侧完整说明（功能、使用、FAQ、技术细节）。
  - CHANGELOG：唯一的对外版本变更历史。
  - CONTRIBUTING：编码/换行约束与提交前自检步骤。
  - SECURITY：安全漏洞上报渠道与处理流程。
  - ARCHITECTURE：本文件，维护者视角的仓库结构与高风险点。
- `docs/`
  - `README.md`：公开文档索引，面向新用户、维护者和 AI 搜索引擎说明文档入口与真实性边界。
  - `release-notes-<版本>.md`：每次发版新增一份发布说明，与 GitHub Release 正文对应。
  - `maintenance-checklist.md`：维护/发布检查清单。
  - `reports/smoke-win-baseline.md`：当前版本 Windows 冒烟基线模板。
  - 维护约束：`docs/` 作为公开维护资料随仓库保留；发版时应同步 README / CHANGELOG 中的用户可见信息，避免公开文档互相矛盾。
- `release/`
  - 发布产物：`IDM-Activation-Script.zip` 与同名 `.sha256` 校验文件（固定文件名、不带版本号；目录内只保留最新一份，历史版本从对应 tag 的 Release Assets 取）。约定见 `release/README.md`。
- `.gitignore`
  - 只覆盖「开发或运行本仓库真的会掉出来的东西」：`开始激活.cmd` 的目录可写性自检文件 `.__ias_write_test.tmp`（正常路径自删，用户中断时残留）、`/log=路径` 可能落进仓库的 `*.log`、编辑器备份与 macOS/Windows 系统垃圾。
  - 维护约束：`release/` 下的 zip 与 `.sha256` 是被跟踪的对外交付物，因此刻意不写 `*.zip` 一类会误伤它们的规则。新增规则前先跑 `git check-ignore -v $(git ls-files)` 确认没有命中已跟踪文件。

## 关键约束（高风险点）

- 编码：`.cmd`/`.txt` 必须保持 GBK（代码页 936），否则 Windows 控制台可能乱码，且 CI 会失败。
- 换行：`.cmd`/`.txt` 必须保持 CRLF；`.md` 使用 LF（由 `.gitattributes` 约束与 CI 校验）。
- 运行环境差异：脚本大量依赖 Windows 系统组件（例如 `cmd.exe`、PowerShell、WMI 等），macOS/Linux 无法做等价运行验证，因此需要通过 Windows 冒烟记录补齐发布信心。

## CI 数据流（维护者视角）

1. push / PR / 手动 `workflow_dispatch` 触发 GitHub Actions（`windows-latest`）。
2. checkout 代码后顺序执行：
   - `tools/validate.ps1`：校验编码（GBK/无 BOM）、行尾（按 `.gitattributes`）、`cmd.exe` 基础可用性。失败时以 `::error file=...::原因` 注解到对应行，便于在 PR diff 中直接看到。
   - `IAS.cmd /silent` 冒烟：在 `chcp 936` 之后调用脚本主体，断言退出码为 `2`（无动作参数 → 静默退出）。这是脚本最短启动路径，能在不依赖管理员/网络/IDM 的前提下捕获语法或参数解析回归。
   - `IAS.cmd /noupd /silent` 冒烟：走完架构重入、PowerShell/WMI 探测、SID 与 CLSID 校验后进入更新开关分支，runner 上没有安装 IDM，因此断言退出码为 `1`。相比上一条能覆盖脚本的绝大部分启动路径。
   - `IAS.cmd /act /silent` 与 `/frz /silent` 冒烟：同样断言 `1`。这两条分支在确认 `IDMan.exe` 存在之前不写注册表、不联网，所以在 runner 上跑是安全的。
   - 日志冒烟：`/log=C:\ias-ci-custom.log` 断言自定义路径确实产出文件（文档承诺过 `/log=路径`，实现漏掉过一次）；不带路径再跑一次，并断言默认日志文件名里带上了真实时间戳，而不是字面量 `IAS-%_logstamp%.log`。
   - 主菜单渲染冒烟：`echo 0| call IAS.cmd -qedit` 跑一次交互菜单（`-qedit` 跳过 QuickEdit 的 conhost 重入，管道喂 `0` 选"退出"），输出重定向到 `menu-smoke.txt`；随后用 pwsh 按 GBK 解码断言版本提示行（`脚本 <iasver> | 已适配 IDM <idmsupport>`）确实打印、runner 上走"未检测到 IDM"分支，且输出里没有批处理语法错误。菜单是绝大多数用户唯一会看到的界面，此前只有 `/silent` 无人值守路径被覆盖。
   - `tools/verify-release.ps1`：校验 `release/` 发布包与仓库是否一致（详见下节）。
3. 任一步失败即阻止合并（建议在 GitHub 仓库设置中将 `Windows validation` 设为分支保护必过项）。

## 发布包一致性守卫

发布包用固定文件名 `release/IDM-Activation-Script.zip`，README 的下载链接永远指向它。好处是链接一次写死，代价是「只改了仓库、忘了重新打包」不会有任何征兆——用户下载到的还是旧脚本，CI 却一路绿灯。`tools/verify-release.ps1` 守住四点：

1. `.sha256` 记录值与 zip 实际哈希一致，否则 README 里教用户做的校验就是假的；
2. 包内**会被执行**的文件（`IAS.cmd`、`开始激活.cmd`、`使用说明.txt`）与仓库逐字节一致 —— 不一致直接失败；
3. 包内文档类文件（README / CHANGELOG / LICENSE / SECURITY）不一致时只发 `::warning::` —— 文档旧一点不影响运行，设成硬失败会让任何一次文档改动都卡住 CI 直到重新打包；
4. `IAS.cmd` 的 `iasver` 与 `CHANGELOG.md` 顶部版本号一致。

zip 里的中文文件名按 GBK 存储且没有 UTF-8 标志位，脚本显式用代码页 936 打开条目名，否则会读到乱码名并误判成「包里多了文件」。

## 退出码语义（速查）

- `IAS.cmd` 退出码：
  - `0`：当前路径正常完成（菜单退出、激活/冻结/重置/更新开关成功完成）。
  - `1`：流程本身跑到了业务分支但未成功（未检测到 IDM 安装、注册表删除/写入失败、IDM 下载测试失败、网络不可达等）。
  - `2`：环境/参数错误（静默模式缺动作参数、未支持的系统版本、缺 PowerShell、缺管理员权限、WMI 失败、CLSID 写入失败、临时目录运行被阻止等）。
- `开始激活.cmd` 退出码：自检发现问题时由用户决定是否继续；选择退出返回 `1`。**已经是管理员**时，`call IAS.cmd %*` 会原样透传 `IAS.cmd` 的返回码；**不是管理员**时会用 `Start-Process -Verb RunAs` 弹 UAC 重开进程（参数一并透传），激活流程在新进程里跑，原窗口无法回收它的退出码，此时返回 `0`。需要按退出码判断结果的自动化调用，请以管理员身份直接执行 `IAS.cmd`。

## 日志

- 触发条件：`/log`、`/log=路径`，或任何 `/silent` 运行（静默模式会自动开日志，否则出错时什么线索都没有）。
- 默认落点：`%SystemRoot%\Temp\IAS-<时间戳>.log`；`/log=路径` 可改到指定文件，目录不存在会自动创建，写不进去则提示并回退默认落点。
- 参数解析前会先剥掉所有引号并按空格切分，所以**日志路径不能含空格**。
- 文件名的时间戳由 `:init_log` 子程序逐行拼装。这段逻辑**必须留在子程序里**：若搬回 `if (...)` 代码块内，`%_logstamp%` 会在整块解析时一次性展开、取不到上一行刚写入的值，文件名会退化成字面量 `IAS-%_logstamp%.log`，所有静默运行都追加进同一个文件。CI 里有对应的回归断言。
