# 仓库结构与维护说明（架构视角）

本仓库是一个以 Windows 脚本为主的项目，重点维护目标是：在中文 Windows 控制台环境中稳定运行，
并避免因为编码 / 换行 / 环境差异导致的「误改即坏」。

本文是**维护者视角的仓库地图与高风险点清单**。想了解脚本内部怎么跑，看
[关键模块与核心逻辑](docs/modules.md)；想查参数或标签，看 [docs/reference/](docs/reference/cli.md)。

## 全局视图

```
仓库根
├── 开始激活.cmd          可选入口：UAC 提权 + 9 项环境自检 → call IAS.cmd
├── IAS.cmd               核心引擎：参数、环境探测、三条业务分支、备份、日志
├── 使用说明.txt          随包分发的极简指南（记事本读）
├── release/              对外交付物：固定文件名 zip + .sha256
├── tools/                维护脚本（PowerShell）：校验、文档同步、打包
├── docs/                 完整文档体系
├── .github/              CI 工作流与 Issue 模板
└── llms.txt / llms-full.txt   给 AI 搜索引擎的结构化摘要（不随包分发）
```

## 目录结构

- `IAS.cmd`
  - 主批处理脚本（约 1270 行），包含参数解析、环境探测、激活/冻结/重置流程、
    IDM 更新检查开关（`CheckUpdtVM`）、注册表备份与日志输出。
  - 头部含「代码导航」注释块，按行号区间标注主要代码段位置。**行号会随改动漂移**，
    权威的按标签索引见 [内部子程序接口](docs/reference/internals.md)。
  - 头部两个版本变量：`iasver`（脚本自身版本，与 `CHANGELOG.md` 顶部由 CI 守一致）、
    `idmsupport`（脚本最后实际验证过的 IDM 版本，主菜单据此显示"已适配 IDM x.xx"）。
    适配了新版 IDM 就更新 `idmsupport`，不要再回到"支持最新版"这类模糊文案。
  - 维护注意：该文件依赖 CRLF 行尾与 GBK 编码；部分环境/编辑器的自动转换会导致异常。
    脚本启动时会自检 LF/CRLF，**末尾必须保留一个空行**，否则自检误报。
- `开始激活.cmd`（面向新手的入口）
  - 自动用 PowerShell 提权（单引号包裹路径，兼容含 `(x86)` 等特殊字符的目录；必须传 `-ArgumentList`，否则参数被丢弃）。
  - 内置 9 项环境自检：管理员权限、`IAS.cmd` 是否就位、PowerShell 可用性与语言模式、Null 服务、
    网络连通性、代码页、WMI/CIM、IDM 安装路径（附带打印 IDM 版本与 `AdvIntDriverEnabled2` 集成开关）、目录写权限。
  - 自检通过或用户确认后，`call IAS.cmd` 进入菜单；也接受 `/frz` `/act` `/res` `/noupd` `/reupd` `/silent /log=...` 等参数透传。
  - **它不是必需的**：以管理员身份直接跑 `IAS.cmd` 功能完全一样。自动化调用应当直接用 `IAS.cmd`（退出码语义见下）。
- `使用说明.txt`
  - 极简上手指南（UTF-8 BOM + CRLF），面向纯小白用户，随发布包分发。
- `.github/workflows/ci.yml`
  - GitHub Actions 工作流入口（Windows runner）。逐条断言见下方「CI 数据流」。
- `.github/ISSUE_TEMPLATE/`
  - `bug_report.yml`：结构化 Bug 反馈模板，强制带 Windows / IDM / 脚本版本与 `开始激活.cmd` 的环境检测输出。
  - `help.yml`：使用帮助 / 新手求助模板。
  - `config.yml`：关闭空白 Issue，引导先看 FAQ 与 CHANGELOG。
- `tools/`
  - `validate.ps1`：仓库卫生。强制 `.cmd` 为 GBK（936）且无 BOM；按 `.gitattributes` 检查行尾；
    末尾跑一次轻量 `cmd.exe` 探测。`.txt` 不强制编码（记事本打开，`使用说明.txt` 用 UTF-8 BOM）。
  - `check-docs.ps1`：**文档与代码同步守卫**。从脚本里提取参数、退出码、菜单编号、标签、版本号，
    与文档比对；另外校验所有 Markdown 的仓库内相对链接。规则见 [文档同步规则](docs/doc-sync.md)。
    不依赖 `cmd.exe`，在 macOS / Linux 的 PowerShell 里也能跑。
  - `verify-release.ps1`：发布包一致性（详见下方专节）。
  - `pack-release.ps1`：重新生成发布包。**只能在 Windows 上跑**（zip 条目名要按 GBK 存且不置 UTF-8 标志位）。
- `docs/`
  - `README.md`：文档索引，列出全部文档与两条阅读路径。
  - `modules.md`：关键模块与核心逻辑——脚本实际怎么跑。
  - `configuration.md`：四类可调项（参数、头部变量、环境依赖、文件约束）。
  - `deployment/`：`local.md` 本地部署与开发环境、`container.md` 容器化边界与隔离环境、`server.md` 无人值守与批量。
  - `reference/`：`cli.md` 命令行契约、`internals.md` 内部标签、`registry.md` 注册表与文件系统副作用。
  - `operations.md`：运维与排错指南。
  - `doc-sync.md`：文档同步矩阵与 CI 守卫说明。
  - `maintenance-checklist.md`：维护 / 发布检查清单。
  - `reports/smoke-win-baseline.md`：Windows 冒烟基线与记录模板。
  - 维护约束：`docs/` 作为公开维护资料随仓库保留，**不随发布包分发**；
    发版时应同步 README / CHANGELOG 中的用户可见信息，避免公开文档互相矛盾。
- `llms.txt` / `llms-full.txt`
  - 面向大语言模型与 AI 搜索引擎的结构化项目摘要（[llms.txt 约定](https://llmstxt.org)），
    UTF-8 无 BOM + CRLF（受 `.gitattributes` 的 `*.txt eol=crlf` 约束）。
  - 内容是 README 的事实性压缩：项目定位、核心功能与参数、退出码、快速开始、限制、与上游的关系、文档与源码地图。
  - 维护约束：**不随发布包分发**（`tools/pack-release.ps1` 的清单里没有它们，`verify-release.ps1`
    只做「包内 → 仓库」单向比对，因此不影响发布包校验）。改动菜单项、命令行参数、退出码、
    系统要求或限制条款时**必须同步**，否则 AI 搜索引擎会长期引用过期口径。CI 会校验参数与版本号两项。
- `README.md` / `CHANGELOG.md` / `CONTRIBUTING.md` / `SECURITY.md` / `OPEN_SOURCE_POLICY.md`
  - README：用户侧完整说明（功能、使用、FAQ、技术细节），并作为文档体系的总入口。
  - CHANGELOG：唯一的对外版本变更历史。
  - CONTRIBUTING：编码/换行约束与提交前自检步骤。
  - SECURITY：安全漏洞上报渠道与处理流程。
  - OPEN_SOURCE_POLICY：公开开源策略与 CI 可见性守卫。
- `release/`
  - 发布产物：`IDM-Activation-Script.zip` 与同名 `.sha256` 校验文件（固定文件名、不带版本号；
    目录内只保留最新一份）。约定与历史版本取法见 `release/README.md`。
  - **本仓库不使用 GitHub Releases，也不打 tag**：`release/` 目录是唯一的分发渠道，
    历史版本从 git 历史里取。
- `.gitignore`
  - 只覆盖「开发或运行本仓库真的会掉出来的东西」：`开始激活.cmd` 的目录可写性自检文件
    `.__ias_write_test.tmp`（正常路径自删，用户中断时残留）、`/log=路径` 可能落进仓库的 `*.log`、
    编辑器备份与 macOS/Windows 系统垃圾。
  - 维护约束：`release/` 下的 zip 与 `.sha256` 是被跟踪的对外交付物，因此刻意不写 `*.zip` 一类会误伤它们的规则。
    新增规则前先跑 `git check-ignore -v $(git ls-files)` 确认没有命中已跟踪文件。

## 关键约束（高风险点）

- **编码**：`.cmd` 必须保持 GBK（代码页 936）且无 BOM，否则 Windows 控制台乱码，CI 会失败。
- **换行**：`.cmd` / `.txt` 必须保持 CRLF；`.md` / `.yml` / `.ps1` 使用 LF（由 `.gitattributes` 约束与 CI 校验）。
  `IAS.cmd` 末尾必须留空行。
- **PowerShell 调用约定**：**禁止裸 `powershell.exe "..."`**，必须带 `-NoProfile -Command`。
  裸调用在真实控制台（stdin 为控制台设备）下会进入交互模式挂死。`IAS.cmd` 通过 `%psc%` 变量统一处理，
  新增调用写 `%psc% "命令"` 即可，不要手动拼 `-NoProfile -Command`（否则参数会重复）；
  `开始激活.cmd` 因调用点少，直接内联 `powershell -NoProfile -Command`。
- **本地工作区行尾**：`git ls-files --eol` 里出现 `w/lf` 而 `attr/text eol=crlf`，说明本地文件被编辑器改成了 LF。
  提交内容不受影响，但**不要在这种状态下本地打包**——打出来的包里是 LF 的 `IAS.cmd`，用户一运行就被换行自检拒绝。
- **运行环境差异**：脚本大量依赖 Windows 系统组件（`cmd.exe`、PowerShell、WMI、注册表、UAC），
  macOS/Linux 无法做等价运行验证，因此需要通过 Windows 冒烟记录补齐发布信心。

更多「看起来可以简化、实际不能动」的具体位置，见
[关键模块与核心逻辑](docs/modules.md#那些看起来能简化实际不能动的地方)。

## CI 数据流（维护者视角）

1. push / PR / 手动 `workflow_dispatch` 触发 GitHub Actions（`windows-latest`）。
2. checkout 代码后顺序执行：
   1. **`Guard public repository visibility`** — 读事件里的 `repository.private`，仓库被改成 private 就直接失败。
   2. **`tools/validate.ps1`** — 编码（GBK 无 BOM）、行尾（按 `.gitattributes`）、`cmd.exe` 基础可用性。
      失败时以 `::error file=...::原因` 注解到对应行，便于在 PR diff 中直接看到。
   3. **`IAS.cmd /silent` 冒烟** — 断言退出码 `2`（无动作参数 → 静默退出）。这是脚本最短启动路径，
      能在不依赖管理员/网络/IDM 的前提下捕获语法或参数解析回归。
   4. **`IAS.cmd /noupd /silent` 冒烟** — 走完架构重入、PowerShell/WMI 探测、SID 与 CLSID 校验后进入更新开关分支，
      runner 上没装 IDM，断言退出码 `1`。相比上一条能覆盖脚本的绝大部分启动路径。
   5. **`IAS.cmd /act /silent` 与 `/frz /silent` 冒烟** — 同样断言 `1`。这两条分支在确认 `IDMan.exe`
      存在之前不写注册表、不联网，所以在 runner 上跑是安全的。
   6. **日志冒烟** — `/log=C:\ias-ci-custom.log` 断言自定义路径确实产出文件（文档承诺过 `/log=路径`，实现漏掉过一次）；
      不带路径再跑一次，并断言默认日志文件名里带上了真实时间戳，而不是字面量 `IAS-%_logstamp%.log`。
   7. **主菜单渲染冒烟** — `echo 0| call IAS.cmd -qedit` 跑一次交互菜单，输出按 GBK 解码后断言版本提示行
      （`脚本 <iasver> | 已适配 IDM <idmsupport>`）确实打印、走"未检测到 IDM"分支、且没有批处理语法错误。
      菜单是绝大多数用户唯一会看到的界面。
   8. **非 ANSI 控制台冒烟** — 显式把 `HKCU\Console\ForceV2` 置 0，让脚本判定 `_NCS=0`，
      真正跑一遍 `:_color` / `:_color2` 的回退分支，断言文案照常输出、不出现空 `echo`、不吐 ANSI 转义码。
      CI runner 永远走 ANSI 分支，把回退分支改错不会有任何征兆，直到 Windows 7/8/8.1 用户运行时才暴露。
   9. **伪造 IDM 的菜单冒烟** — 用 `notepad.exe` 冒充 `IDMan.exe` 并写 `HKCU` 的 `ExePath`，
      把版本探测那条 PowerShell 也跑一遍，断言读出了文件版本号并打出"与已适配版本不同"的提示，跑完立刻清理。
   10. **入口脚本冒烟** — 伪造已安装的 IDM 与浏览器集成开关键，把 `开始激活.cmd` 的环境自检整条走通，
       断言各检查行打印、集成开关被正确报告、无批处理语法错误。
       （入口文件名是中文，而 Actions 把 cmd 步骤按 UTF-8 写进临时 `.cmd`、cmd.exe 却按 OEM 代码页解析，
       所以先用 pwsh 复制出一个纯 ASCII 名的副本再跑。）
   11. **内嵌 PowerShell 段守卫** — 断言 `ReadAllText` 每一处都显式带 936 编码、按 `:regscan:` 标记正好切成 3 段、
       切出来的段没有 U+FFFD 替换字符、关键中文串还在。
   12. **`tools/check-docs.ps1`** — 文档与脚本同步（参数、退出码、菜单编号、标签、版本号、站内链接）。
   13. **`tools/verify-release.ps1`** — 发布包与仓库是否一致（详见下节）。
   14. **`tools/pack-release.ps1`（`if: always()`）** — 重新打包并上传 `release-bundle-rebuilt` artifact。
       **必须排在校验之后**：先跑打包会把 `release/` 刷成最新，校验就永远是假绿。
       用 `if: always()` 是为了在校验失败时也产出一份打好的包——维护者（可能在 macOS 上，没法生成 GBK 条目名的 zip）
       直接下载这个 artifact 放回 `release/` 提交即可。
3. 任一步失败即阻止合并（建议在 GitHub 仓库设置中将 `Windows 验证` 设为分支保护必过项）。

## 发布包一致性守卫

发布包用固定文件名 `release/IDM-Activation-Script.zip`，README 的下载链接永远指向它。
好处是链接一次写死，代价是「只改了仓库、忘了重新打包」不会有任何征兆——用户下载到的还是旧脚本，CI 却一路绿灯。
`tools/verify-release.ps1` 守住四点：

1. `.sha256` 记录值与 zip 实际哈希一致，否则 README 里教用户做的校验就是假的；
2. 包内**会被执行**的文件（`IAS.cmd`、`开始激活.cmd`、`使用说明.txt`）与仓库逐字节一致 —— 不一致直接失败；
3. 包内文档类文件（README / CHANGELOG / LICENSE / SECURITY）不一致时只发 `::warning::` —— 文档旧一点不影响运行，
   设成硬失败会让任何一次文档改动都卡住 CI 直到重新打包；
4. `IAS.cmd` 的 `iasver` 与 `CHANGELOG.md` 顶部版本号一致。

zip 里的中文文件名按 GBK 存储且没有 UTF-8 标志位，脚本显式用代码页 936 打开条目名，
否则会读到乱码名并误判成「包里多了文件」。

## 文档与代码的同步守卫

`tools/check-docs.ps1` 解决的是另一类静默漂移：**脚本改了，文档还写着旧的**。
它从脚本里提取六类可机械验证的事实与文档比对，规则与豁免方式见 [文档同步规则](docs/doc-sync.md)。

它**只做前向校验**（脚本 → 文档），唯一的反向校验是标签的双向比对。
文档里的解释、示例、排错建议是否正确，机器判断不了，那部分靠
[维护 / 发布检查清单](docs/maintenance-checklist.md) 和 review。

## 退出码语义（速查）

- `IAS.cmd` 退出码：
  - `0`：当前路径正常完成（菜单退出、激活/冻结/重置/更新开关成功完成）。
  - `1`：流程本身跑到了业务分支但未成功（未检测到 IDM 安装、注册表删除/写入失败、IDM 下载测试失败、网络不可达等）。
  - `2`：环境/参数错误（静默模式缺动作参数、未支持的系统版本、缺 PowerShell、缺管理员权限、WMI 失败、
    CLSID 写入失败、临时目录运行被阻止、检测到 LF 换行等）。
  - 只记录**第一个**非零码（`:set_exit` 不覆盖已有值），拿到的是最早的失败原因。
- `开始激活.cmd` 退出码：自检发现问题时由用户决定是否继续；选择退出返回 `1`。**已经是管理员**时，
  `call IAS.cmd %*` 会原样透传 `IAS.cmd` 的返回码；**不是管理员**时会用 `Start-Process -Verb RunAs` 弹 UAC
  重开进程（参数一并透传），激活流程在新进程里跑，原窗口无法回收它的退出码，此时返回 `0`。
  需要按退出码判断结果的自动化调用，请以管理员身份直接执行 `IAS.cmd`。

完整对照表见 [命令行接口契约](docs/reference/cli.md#退出码)。

## 日志

- 触发条件：`/log`、`/log=路径`，或任何 `/silent` 运行（静默模式会自动开日志，否则出错时什么线索都没有）。
- 默认落点：`%SystemRoot%\Temp\IAS-<时间戳>.log`；`/log=路径` 可改到指定文件，
  目录不存在会自动创建，写不进去则提示并回退默认落点。
- 参数解析前会先剥掉所有引号并按空格切分，所以**日志路径不能含空格**。
- 文件名的时间戳由 `:init_log_default` 子程序逐行拼装。这段逻辑**必须留在子程序里**：
  若搬回 `if (...)` 代码块内，`%_logstamp%` 会在整块解析时一次性展开、取不到上一行刚写入的值，
  文件名会退化成字面量 `IAS-%_logstamp%.log`，所有静默运行都追加进同一个文件。CI 里有对应的回归断言。
- 日志解读见 [运维与排错指南](docs/operations.md#日志怎么读)。
