# 维护/发布检查清单（维护安全）

此清单用于降低“文档/编码/换行误改导致 Windows 端不可用”的风险，并把关键验证步骤显式化。

## 提交前（本地）

- 确认未改动 `.cmd` / `.txt` 的编码（应保持 GBK/936）与换行（CRLF）。
- 运行 CI 同款校验（Windows 上执行）：
  - `pwsh -NoProfile -File tools/validate.ps1`
- 若涉及发布包：更新 `docs/release-notes-*.md` 与校验值。

## PR 合并前（GitHub）

- `Windows validation` 通过（分支保护会强制）。
- 若改动影响运行环境：在 `docs/reports/smoke-win-baseline.md` 填写一次新的 Windows 冒烟记录。

## 发版前（Windows 真实环境）

- 管理员 CMD 下跑一遍 `测试脚本.cmd`，确认全绿且退出码 `0`。
- 运行主脚本的一条代表性路径（建议静默 + 日志），确认退出码与日志输出符合预期。
- 记录 Defender/SmartScreen 提示（如有），并把结论写回 `docs/release-notes-*.md`。

