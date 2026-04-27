# 维护 / 发布检查清单（维护安全）

此清单用于降低“文档/编码/换行误改导致 Windows 端不可用”的风险，并把关键验证步骤显式化。

## 提交前（本地）

- 确认未改动 `.cmd` / `.txt` 的编码（应保持 GBK / 936，无 BOM）与换行（CRLF）；`.md` 保持 UTF-8 + LF。
- 运行 CI 同款校验（Windows 上执行）：
  - `pwsh -NoProfile -File tools/validate.ps1`
  - macOS / Linux 维护者可改用 `iconv -f GBK -t UTF-8 <file>` 抽样确认 GBK 解码不报错；编码/换行的最终判定仍以 CI 为准。
- 若改了 `IAS.cmd`：本地用 `iconv` 抽看相关行号，确保改动符合「代码导航」注释块描述的分区。
- 若涉及发布包：重新打包并更新 `release/IDM-Activation-Script-v<版本>.zip` 与同名 `.sha256`，同步 `docs/release-notes-*.md`。
- `docs/` 默认作为本地维护资料保留，不随发布提交 / 推送到云端仓库；公开发布信息以 `README.md`、`CHANGELOG.md`、GitHub Release 和 `release/*.sha256` 为准。

## PR 合并前（GitHub）

- `Windows validation` 通过（分支保护建议设为必过项）：
  1. `tools/validate.ps1` 编码 / 换行 / `cmd.exe` 探测全部通过。
  2. `IAS.cmd /silent` 冒烟返回 `2`（"静默模式缺动作参数"路径，确认脚本启动到参数解析无回归）。
- 若改动影响运行环境（参数解析、环境检测、注册表分支等）：在 `docs/reports/smoke-win-baseline.md` 表格中追加一行新的 Windows 冒烟记录。

## 发版前（Windows 真实环境）

- 管理员 CMD 下跑一遍 `测试脚本.cmd`，确认 10 项全绿且退出码 `0`。
- 运行主脚本的一条代表性路径（建议 `IAS.cmd /frz /silent /log="C:\Temp\ias.log"`），确认退出码与日志输出符合预期。
- 记录 Defender / SmartScreen 提示（如有），并把结论写回 `docs/release-notes-*.md`。
- 重新计算并核对 `release/*.zip.sha256`：
  - PowerShell：`Get-FileHash release\IDM-Activation-Script-v<版本>.zip -Algorithm SHA256`
  - macOS / Linux：`shasum -a 256 release/IDM-Activation-Script-v<版本>.zip`
- 发布后确认 `git status --short` 中只有预期的本地维护文档改动；若准备推送，先确认暂存区不包含 `docs/`。
