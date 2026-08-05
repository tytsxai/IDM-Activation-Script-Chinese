# 维护 / 发布检查清单（维护安全）

此清单用于降低“文档/编码/换行误改导致 Windows 端不可用”的风险，并把关键验证步骤显式化。

## 提交前（本地）

- 确认未改动 `.cmd` / `.txt` 的编码（应保持 GBK / 936，无 BOM）与换行（CRLF）；`.md` 保持 UTF-8 + LF。
- 运行 CI 同款校验（Windows 上执行）：
  - `pwsh -NoProfile -File tools/validate.ps1`
  - macOS / Linux 维护者可改用 `iconv -f GBK -t UTF-8 <file>` 抽样确认 GBK 解码不报错；编码/换行的最终判定仍以 CI 为准。
- 若改了 `IAS.cmd`：本地用 `iconv` 抽看相关行号，确保改动符合「代码导航」注释块描述的分区。
- 若涉及发布包：重新打包并**覆盖** `release/IDM-Activation-Script.zip` 与同名 `.sha256`（固定文件名、不带版本号，目录内只保留最新一份），同步 `CHANGELOG.md`，并把同一个包作为 Asset 上传到对应 tag 的 GitHub Release。
- **打包必须在中文 Windows 上做**（资源管理器右键"压缩"或 `Compress-Archive` 均可）。在 macOS / Linux 上打包会把中文文件名写成 UTF-8 并置 EFS 标志位，与现有发布包的 GBK 文件名约定不同，旧版解压工具可能显示乱码。
- 改了 `IAS.cmd` 的 `iasver` 时，`CHANGELOG.md` 顶部必须同步出现对应的 `## vX.Y.Z` 标题，否则 `tools/verify-release.ps1` 会直接失败。
- 在新版 IDM 上实测通过后，同步更新 `IAS.cmd` 头部的 `idmsupport`（主菜单显示的"已适配 IDM 版本"），并在 CHANGELOG 里说明验证环境。没实测就不要往上抬，这个值的意义就是"我们真的验证过"。
- `docs/` 作为公开维护资料随仓库保留；更新 README / CHANGELOG / GitHub Release / `llms.txt` 时，必须检查 `docs/` 是否存在版本号、发布包和运行步骤的冲突。
- 本仓库必须保持 GPL-3.0 开源表达；不要把文档、Release 或 Issue 模板写成私有仓库、闭源分发或不可再分发项目。
- 改动 CI 时必须保留 `Guard public repository visibility` 步骤，除非有新的等效公开可见性守卫替代。

## PR 合并前（GitHub）

- `Windows validation` 通过（分支保护建议设为必过项）：
  1. `Guard public repository visibility` 确认仓库不是 private。
  2. `tools/validate.ps1` 编码 / 换行 / `cmd.exe` 探测全部通过。
  3. `IAS.cmd /silent` 冒烟返回 `2`（"静默模式缺动作参数"路径，确认脚本启动到参数解析无回归）。
  4. `IAS.cmd /noupd|/act|/frz /silent` 冒烟均返回 `1`（runner 上没装 IDM，走完探测后命中"未检测到 IDM 安装"）。
  5. 日志冒烟：`/log=路径` 确实产出文件，默认日志文件名带真实时间戳。
  6. `tools/verify-release.ps1` 通过：`release/` 发布包的 sha256 正确、包内运行时文件与仓库一致、`iasver` 与 CHANGELOG 顶部版本号一致。
- 若改动影响运行环境（参数解析、环境检测、注册表分支等）：在 `docs/reports/smoke-win-baseline.md` 表格中追加一行新的 Windows 冒烟记录。

## 发版前（Windows 真实环境）

- 管理员身份双击 `开始激活.cmd`，确认进入菜单前的环境检测全绿；把脚本放进含 `(x86)` 的目录再试一次，确认不再报"此时不应有 \Internet"。
- 运行主脚本的一条代表性路径（建议 `IAS.cmd /frz /silent /log=C:\Temp\ias.log`），确认退出码与日志内容符合预期。日志路径**不能含空格**；不带 `/log=` 时日志落在 `%SystemRoot%\Temp\IAS-<时间戳>.log`。
- 确认「不是管理员」时双击 `开始激活.cmd` 能弹 UAC，且带参数运行（如 `开始激活.cmd /frz /silent`）时参数会透传给提权后的新进程，而不是被丢掉后弹出交互菜单。
- 记录 Defender / SmartScreen 提示（如有），并把结论写回 `CHANGELOG.md` 或对应版本的发布说明。
- 重新计算并核对 `release/*.zip.sha256`：
  - PowerShell：`Get-FileHash release\IDM-Activation-Script.zip -Algorithm SHA256`
  - macOS / Linux：`shasum -a 256 release/IDM-Activation-Script.zip`
- 发布后确认 `git status --short` 中只有预期改动；若准备推送，先确认 README、CHANGELOG、`llms.txt`、`docs/` 与 Release 资产版本一致。
