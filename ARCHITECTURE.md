# 仓库结构与维护说明（架构视角）

本仓库是一个以 Windows 脚本为主的项目，重点维护目标是：在中文 Windows 控制台环境中稳定运行，并避免因为编码/换行/环境差异导致的“误改即坏”。

## 目录结构

- `.github/workflows/ci.yml`
  - GitHub Actions 工作流入口（Windows runner）。
  - 两步：1) 调用 `tools/validate.ps1` 做仓库卫生校验（编码、换行、基础 `cmd.exe` 可用性探测）；2) 用 `IAS.cmd /silent` 做最短路径冒烟，断言退出码为 `2`（"静默模式缺少动作参数"路径）。
- `.github/ISSUE_TEMPLATE/`
  - `bug_report.yml`：结构化 Bug 反馈模板，强制带 Windows / IDM / 脚本版本与 `测试脚本.cmd` 输出。
  - `help.yml`：使用帮助 / 新手求助模板。
  - `config.yml`：关闭空白 Issue，引导先看 FAQ 与 CHANGELOG。
- `tools/validate.ps1`
  - CI 校验脚本：强制 `.cmd`/`.txt` 的 GBK（936）与 BOM 约束；按 `.gitattributes` 检查行尾（CRLF/LF）；末尾跑一次轻量 `cmd.exe` 探测。
  - 目标是尽早在 CI 中阻止“编码/换行被编辑器自动改坏”的提交进入主分支。
- `IAS.cmd`
  - 主批处理脚本（约 1000 行），包含参数解析、环境探测、激活/冻结/重置流程、注册表备份与日志输出。
  - 头部含「代码导航」注释块，按行号区间标注主要代码段位置。
  - 维护注意：该文件依赖 CRLF 行尾与 GBK 编码；部分环境/编辑器的自动转换会导致异常。脚本启动时会自检 LF/CRLF。
- `快速激活.cmd` / `普通激活.cmd` / `重置激活.cmd`
  - 三个一键入口，分别透传 `/frz` `/act` `/res` 给 `IAS.cmd`，并自动用 PowerShell 提权。
  - 三者结构一致，仅参数不同；任一脚本均接受附加参数（如 `/silent /log=...`）并向上传递返回码。
- `测试脚本.cmd`
  - 环境自检：管理员权限、PowerShell 语言模式、Null 服务、网络连通性、代码页、WMI、IDM 安装路径、目录写权限等共 10 项检查。
  - 退出码按位汇总（`ERR_ADMIN=1` / `ERR_PS_MISSING=2` / ...），结尾打印「首个未通过项」与建议查阅的 README 章节，便于自动化解析与人工排查。
- `使用说明.txt`
  - 三步极简指南（GBK + CRLF），面向纯小白用户。
- `README.md` / `CHANGELOG.md` / `CONTRIBUTING.md` / `SECURITY.md` / `ARCHITECTURE.md`
  - README：用户侧完整说明（功能、使用、FAQ、技术细节）。
  - CHANGELOG：唯一的对外版本变更历史。
  - CONTRIBUTING：编码/换行约束与提交前自检步骤。
  - SECURITY：安全漏洞上报渠道与处理流程。
  - ARCHITECTURE：本文件，维护者视角的仓库结构与高风险点。
- `docs/`
  - `release-notes-v1.3.3.md`：当前本地发布说明与回归建议。
  - `release-notes-v1.3.1.md`：v1.3.1 历史发布说明（保留）。
  - `release-notes-v1.3.md`：v1.3 历史发布说明（保留）。
  - `maintenance-checklist.md`：维护/发布检查清单。
  - `reports/smoke-win-baseline.md`：当前版本 Windows 冒烟基线模板。
  - 维护约束：`docs/` 用作本地维护资料，默认不随发布提交到云端仓库。
- `release/`
  - 发布产物：`IDM-Activation-Script-v<版本>.zip` 与同名 `.sha256` 校验文件。

## 关键约束（高风险点）

- 编码：`.cmd`/`.txt` 必须保持 GBK（代码页 936），否则 Windows 控制台可能乱码，且 CI 会失败。
- 换行：`.cmd`/`.txt` 必须保持 CRLF；`.md` 使用 LF（由 `.gitattributes` 约束与 CI 校验）。
- 运行环境差异：脚本大量依赖 Windows 系统组件（例如 `cmd.exe`、PowerShell、WMI 等），macOS/Linux 无法做等价运行验证，因此需要通过 Windows 冒烟记录补齐发布信心。

## CI 数据流（维护者视角）

1. push / PR / 手动 `workflow_dispatch` 触发 GitHub Actions（`windows-latest`）。
2. checkout 代码后顺序执行：
   - `tools/validate.ps1`：校验编码（GBK/无 BOM）、行尾（按 `.gitattributes`）、`cmd.exe` 基础可用性。失败时以 `::error file=...::原因` 注解到对应行，便于在 PR diff 中直接看到。
   - `IAS.cmd /silent` 冒烟：在 `chcp 936` 之后调用脚本主体，断言退出码为 `2`（无动作参数 → 静默退出）。这是脚本最短启动路径，能在不依赖管理员/网络/IDM 的前提下捕获语法或参数解析回归。
3. 任一步失败即阻止合并（建议在 GitHub 仓库设置中将 `Windows validation` 设为分支保护必过项）。

## 退出码语义（速查）

- `IAS.cmd` 退出码：
  - `0`：当前路径正常完成（菜单退出、激活/冻结/重置成功完成）。
  - `2`：环境/参数错误（静默模式缺动作参数、未支持的系统版本、缺 PowerShell、缺管理员权限、WMI 失败、CLSID 写入失败、临时目录运行被阻止等）。
- `测试脚本.cmd` 退出码：按位汇总，定义见脚本头部 `ERR_*` 变量；`0` 表示全绿。
- `快速激活.cmd` / `普通激活.cmd` / `重置激活.cmd` 退出码：原样透传 `IAS.cmd` 的返回码。
