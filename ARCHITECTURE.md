# 仓库结构与维护说明（架构视角）

本仓库是一个以 Windows 脚本为主的项目，重点维护目标是：在中文 Windows 控制台环境中稳定运行，并避免因为编码/换行/环境差异导致的“误改即坏”。

## 目录结构

- `.github/workflows/ci.yml`
  - GitHub Actions 工作流入口（Windows runner）。
  - 仅做仓库卫生校验（编码、换行、基础 `cmd.exe` 可用性探测）。
- `tools/validate.ps1`
  - CI 校验脚本：强制 `.cmd`/`.txt` 的 GBK（936）与 BOM 约束；按 `.gitattributes` 检查行尾（CRLF/LF）。
  - 目标是尽早在 CI 中阻止“编码/换行被编辑器自动改坏”的提交进入主分支。
- `IAS.cmd`
  - 主批处理脚本（体量最大），包含参数解析、环境探测、以及核心执行流程。
  - 维护注意：该文件依赖 CRLF 行尾与 GBK 编码；部分环境/编辑器的自动转换会导致异常。
- `快速激活.cmd`
  - 入口脚本：用于定位同目录的 `IAS.cmd` 并以管理员权限运行，透传命令行参数。
- `测试脚本.cmd`
  - 环境自检：管理员权限、PowerShell 语言模式、网络连通性、代码页、WMI 等。
  - 用于把“脚本为什么跑不起来”的原因前置并显式化（并用按位退出码便于自动化解析）。
- `docs/`
  - `docs/release-notes-v1.3.md`：发布说明与回归建议。
  - `docs/reports/smoke-win-baseline.md`：Windows 冒烟基线模板（待补跑并填表）。
- `release/`
  - 发布产物（zip），用于用户侧下载与校验。

## 关键约束（高风险点）

- 编码：`.cmd`/`.txt` 必须保持 GBK（代码页 936），否则 Windows 控制台可能乱码，且 CI 会失败。
- 换行：`.cmd`/`.txt` 必须保持 CRLF；`.md` 使用 LF（由 `.gitattributes` 约束与 CI 校验）。
- 运行环境差异：脚本大量依赖 Windows 系统组件（例如 `cmd.exe`、PowerShell、WMI 等），macOS/Linux 无法做等价运行验证，因此需要通过 Windows 冒烟记录补齐发布信心。

## CI 数据流（维护者视角）

1. push/PR 触发 GitHub Actions（Windows runner）。
2. checkout 代码后执行 `tools/validate.ps1`。
3. 校验失败时以 `::error` 格式标注具体文件与原因，阻止合并（配合分支保护）。

