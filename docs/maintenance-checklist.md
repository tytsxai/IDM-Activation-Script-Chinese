# 维护 / 发布检查清单（维护安全）

此清单用于降低「文档 / 编码 / 换行误改导致 Windows 端不可用」的风险，并把关键验证步骤显式化。

带 🤖 的项目由 CI 自动校验，人工只需在失败时处理；其余靠人。

## 提交前（本地）

### 编码与换行

- [ ] 🤖 未改动 `.cmd` / `.txt` 的编码（应保持 GBK / 936，无 BOM）与换行（CRLF）；`.md` / `.yml` / `.ps1` 保持 LF。
- [ ] 运行 CI 同款校验（Windows）：
      ```powershell
      pwsh -NoProfile -File tools/validate.ps1
      pwsh -NoProfile -File tools/check-docs.ps1
      pwsh -NoProfile -File tools/verify-release.ps1
      ```
      `check-docs.ps1` 不依赖 `cmd.exe`，**在 macOS / Linux 的 PowerShell 里也能跑**。
- [ ] macOS / Linux 维护者可用 `iconv -f GBK -t UTF-8 <file>` 抽样确认 GBK 解码不报错；
      编码 / 换行的最终判定仍以 CI 为准。
- [ ] `git ls-files --eol` 里没有 `w/lf` 而 `attr/text eol=crlf` 的文件。有的话用
      `rm <文件> && git checkout -- <文件>` 恢复——**这种状态下本地打包会打出 LF 的 `IAS.cmd`**。

### 脚本改动

- [ ] 若改了 `IAS.cmd`：改动符合「代码导航」注释块描述的分区；
      并对照 [关键模块与核心逻辑](modules.md#那些看起来能简化实际不能动的地方) 确认没有踩到已知的不可动点。
- [ ] 🤖 若新增 / 删除了命令行参数、退出码、菜单项或标签：按 [文档同步规则](doc-sync.md) 把文档补齐。
- [ ] 🤖 改了 `IAS.cmd` 的 `iasver`：`CHANGELOG.md` 顶部必须同步出现对应的 `## vX.Y.Z` 标题，
      README 页首徽章与菜单示意框里的版本也要跟着改。
- [ ] 在新版 IDM 上实测通过后，才更新 `IAS.cmd` 头部的 `idmsupport`，并在 CHANGELOG 里说明验证环境。
      **没实测就不要往上抬**——这个值的意义就是「我们真的验证过」。

### 文档

- [ ] 🤖 站内相对链接都指向存在的文件。
- [ ] 更新 README / CHANGELOG 时检查 `docs/` 是否存在版本号、发布包和运行步骤的冲突。
- [ ] 新增 / 删除 `docs/` 下的文件时，同步 `docs/README.md` 的文档索引与 README 的「维护与贡献」表。
- [ ] 改了用户可见行为时，`llms.txt` 与 `llms-full.txt` 一并更新（漏改不报错，但会让 AI 长期引用过期口径）。

### 发布包

- [ ] 若改了 `IAS.cmd` / `开始激活.cmd` / `使用说明.txt`：**在中文 Windows 上**重新打包并覆盖
      `release/IDM-Activation-Script.zip` 与同名 `.sha256`。
      没有 Windows 时从 CI 的 `release-bundle-rebuilt` artifact 拿，见
      [运维与排错指南](operations.md#发布包与仓库不一致)。
- [ ] **打包必须在中文 Windows 上做**。在 macOS / Linux 上打包会把中文文件名写成 UTF-8 并置 EFS 标志位，
      与现有发布包的 GBK 文件名约定不同，旧版解压工具可能显示乱码。

### 开源与合规

- [ ] 本仓库必须保持 GPL-3.0 开源表达；不要把文档、Issue 模板写成私有仓库、闭源分发或不可再分发项目。
- [ ] 改动 CI 时必须保留 `Guard public repository visibility` 步骤，除非有新的等效公开可见性守卫替代。
- [ ] 不提交任何密钥、令牌、个人隐私或机器特征信息。

## PR 合并前（GitHub）

`Windows 验证` 工作流全绿（建议在仓库设置里设为分支保护必过项）。各步骤含义：

| 步骤 | 断言 |
| --- | --- |
| `Guard public repository visibility` | 仓库不是 private |
| `Run encoding and EOL checks` | 编码 / 换行 / `cmd.exe` 探测 |
| `IAS.cmd /silent` | 退出码 `2`（静默模式缺动作参数） |
| `IAS.cmd /noupd\|/act\|/frz /silent` | 退出码均为 `1`（runner 上没装 IDM） |
| 日志冒烟 | `/log=路径` 确实产出文件；默认日志文件名带真实时间戳 |
| 主菜单渲染 | 版本提示行正确、走"未检测到 IDM"分支、无批处理语法错误 |
| 非 ANSI 控制台 | `:_color` / `:_color2` 回退分支文案照常输出 |
| 伪造 IDM 的菜单 | 读出文件版本号并打出"与已适配版本不同" |
| 入口脚本自检 | 各检查行打印、集成开关被正确报告、无语法错误 |
| 内嵌 PowerShell 段 | GBK 解码正确、按标记切成 3 段、中文串完整 |
| `Verify documentation matches the scripts` | 文档与脚本同步（参数 / 退出码 / 菜单 / 标签 / 版本 / 链接） |
| `Verify release bundle matches the repository` | 发布包 sha256 正确、包内运行时文件与仓库一致、`iasver` 与 CHANGELOG 顶部一致 |

- [ ] 若改动影响运行环境（参数解析、环境检测、注册表分支等）：
      在 [`reports/smoke-win-baseline.md`](reports/smoke-win-baseline.md) 的表格中追加一行新的 Windows 冒烟记录。

## 发版前（Windows 真实环境）

CI 覆盖不到真实的注册表写入、网络下载和 UAC 提权，这些必须人工跑。**建议在虚拟机快照里做**，
见 [容器化与隔离环境](deployment/container.md#方案二虚拟机推荐用于发版前的真实验证)。

- [ ] 管理员身份双击 `开始激活.cmd`，确认进入菜单前的环境检测全绿；
      把脚本放进含 `(x86)` 的目录再试一次，确认不再报"此时不应有 \Internet"。
- [ ] 运行主脚本的一条代表性路径（建议 `IAS.cmd /frz /silent /log=C:\Temp\ias.log`），
      确认退出码与日志内容符合预期。日志路径**不能含空格**；不带 `/log=` 时日志落在
      `%SystemRoot%\Temp\IAS-<时间戳>.log`。
- [ ] 确认「不是管理员」时双击 `开始激活.cmd` 能弹 UAC，且带参数运行（如 `开始激活.cmd /frz /silent`）时
      参数会透传给提权后的新进程，而不是被丢掉后弹出交互菜单。
- [ ] 走一遍真实的 `[1]` 冻结、`[2]` 激活、`[3]` 重置，确认状态切换符合预期。
- [ ] 记录 Defender / SmartScreen 提示（如有），并把结论写回 `CHANGELOG.md`。
- [ ] 重新计算并核对 `release/*.zip.sha256`：
      - PowerShell：`Get-FileHash release\IDM-Activation-Script.zip -Algorithm SHA256`
      - macOS / Linux：`shasum -a 256 release/IDM-Activation-Script.zip`
- [ ] 把本次验证结果填进 [`reports/smoke-win-baseline.md`](reports/smoke-win-baseline.md) 的记录表。
- [ ] `git status --short` 中只有预期改动；README、CHANGELOG、`docs/` 与 `release/` 的版本口径一致。

> 本项目**不发布 GitHub Release、不打 tag**：发版就是把新的 `release/` 产物和 `CHANGELOG.md`
> 一起提交到 `main`。约定见 [`release/README.md`](../release/README.md)。

## 相关文档

- [文档同步规则](doc-sync.md)
- [运维与排错指南](operations.md)
- [Windows 冒烟基线](reports/smoke-win-baseline.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [OPEN_SOURCE_POLICY.md](../OPEN_SOURCE_POLICY.md)
