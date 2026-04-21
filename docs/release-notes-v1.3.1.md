# IDM 激活脚本中文版 v1.3.1 发布说明

## 版本概览

- 版本：**v1.3.1**（2026-04-21）
- 发布性质：**文档与用户体验维护版**（Maintenance / UX release）
- 主要变更：
  - 新增 `普通激活.cmd` / `重置激活.cmd`，与 `快速激活.cmd` 形成完整入口三件套；
  - `测试脚本.cmd` 在结尾显式打印"第一项未通过的检查"与对应 README 章节提示；
  - 修复 `快速激活.cmd` 在路径含单引号或特殊字符时 PowerShell 自动提权失败的 bug；
  - README 常见问题新增 4 条（Win11 24H2 / Defender / WDAC / IDM 6.42+）；
  - `SECURITY.md` 全文中文化，新增结构化 Bug 反馈模板；
  - CI 新增 `IAS.cmd /silent` 冒烟探测，防止语法级回归进入主分支；
  - `CHANGELOG.md` 作为唯一的变更历史来源。

- 包含文件：`IAS.cmd`、`快速激活.cmd`、`普通激活.cmd`、`重置激活.cmd`、`测试脚本.cmd`、`使用说明.txt`、`README.md`、`CHANGELOG.md`、`SECURITY.md`、`docs/release-notes-v1.3.1.md`、`docs/reports/smoke-win-baseline.md`。

## 安装与升级步骤

1) 校验压缩包：`Get-FileHash release/IDM-Activation-Script-v1.3.1.zip -Algorithm SHA256`（PowerShell）或 `shasum -a 256 release/IDM-Activation-Script-v1.3.1.zip`（macOS/Linux），与 `.sha256` 文件内容比对。
2) 解压到本地非临时目录（避免在下载器/压缩软件的虚拟目录直接运行）。
3) **管理员身份**运行 `测试脚本.cmd`：
   - 若全部 [√] 且退出码 0，进入第 4 步；
   - 若有 [×]，脚本会在末尾打印"第一项未通过的检查"，按提示定位 README 对应章节处理后再重试。
4) 执行激活（按需选择其中一项）：
   - 新手推荐：双击 `快速激活.cmd`（冻结激活，最稳定）；
   - 普通激活：双击 `普通激活.cmd`（随机注册信息激活）；
   - 重置激活：双击 `重置激活.cmd`（清理激活/试用信息）；
   - 高级用户：`IAS.cmd /frz|/act|/res`，如需无人值守追加 `/silent /log="C:\Temp\ias.log"`。

## 校验信息

- 文件：`release/IDM-Activation-Script-v1.3.1.zip`
- SHA256：`f885c60b8ecd8d5ed9cd942536ef516ca2005abfa6b5a0d9dab5b9b8a7f732cd`（同级 `.sha256` 文件也可下载校验）
- 编码/行尾：`.cmd`/`.txt` 为 GBK + CRLF，`.md` 为 UTF-8 + LF。
- 压缩包内中文文件名已写入 UTF-8 文件名标记，Win10/11 内置解压工具可正常显示。

## 已知事项

- 依赖中文代码页 936，若控制台显示乱码请先 `chcp 936`。
- 需要管理员权限与可访问 `internetdownloadmanager.com` 的网络；PowerShell / WMI 被组织策略禁用会导致脚本无法正常工作。
- 企业 WDAC / AppLocker 策略下脚本可能直接拒绝执行，请联系 IT 授权，不建议绕过。

## 兼容性

- 兼容 Windows 7 / 8 / 8.1 / 10 / 11（含 24H2）。
- 兼容 IDM 6.x 系列；6.42+ 用户如升级后激活失效，按 `重置激活.cmd → 快速激活.cmd` 顺序重做即可。

## 从 v1.3 升级

- v1.3 用户可直接覆盖安装。无需额外迁移步骤。
- 若之前使用自建的 `/silent` 无人值守脚本，参数语义完全兼容，不需调整。
