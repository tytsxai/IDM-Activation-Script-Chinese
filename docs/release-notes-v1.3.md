# IDM 激活脚本 v1.3 发布说明

## 版本概览
- 版本：v1.3（批次 B3）
- 主要变更：新增 `/silent` `/log` 静默/日志参数（IAS/快速激活皆可透传）、环境自检脚本扩充 10 项检查并按位退出码汇总、GitHub Actions（Windows）执行编码/行尾/`cmd` 语法校验。
- 包含文件：`IAS.cmd`、`快速激活.cmd`、`测试脚本.cmd`、`使用说明.txt`、`README.md`、`docs/release-notes-v1.3.md`。

## 冒烟结果与发布标记
- 冒烟：尚未在 Win10/11 管理员环境补跑，当前仅在 macOS 做脚本语法/编码校验（需按下方已知问题补跑）。
- 发布标记：`v1.3`（https://github.com/tytsxai/IDM-Activation-Script-Chinese/tree/v1.3）。

## 安装与升级步骤
1) 校验压缩包：`shasum -a 256 release/IDM-Activation-Script-v1.3.zip`，确认与下方校验值一致后再展开。
2) 解压到本地非临时目录（避免在下载器/压缩软件的虚拟目录直接运行）。
3) 右键“以管理员身份运行” `测试脚本.cmd`，确认 10 项检查均为 `[√]` 且退出码 `0`。
4) 执行激活：新手推荐 `快速激活.cmd`；高级用户可用 `IAS.cmd /frz|/act|/res`，如需静默与日志追加 `/silent /log="C:\Temp\ias.log"`。
5) 如遇环境问题，先根据 `测试脚本.cmd` 的失败项排查（PowerShell/WMI/网络/代码页等）。

## 校验信息
- 文件：`release/IDM-Activation-Script-v1.3.zip`
- SHA256：`810855c004dd763114d17304b7e8b8c3b286b249f109f3c614f7090e8579547e`
- 编码/行尾：`.cmd`/`.txt` 为 GBK + CRLF，`.md` 为 UTF-8 + LF。
- 压缩包文件名：已写入 UTF-8 文件名标记，中文文件名在 Win10/11 解压正常；若旧版解压工具显示乱码，请手动切换为 UTF-8。

## 已知问题与注意事项
- B3-T1 冒烟与静默日志验证未在实际 Windows 管理员环境执行（当前环境为 macOS），发布前需在 Win10/11 x64 补跑并记录日志。
- 依赖中文代码页 936，若控制台乱码可先运行 `chcp 936`。
- 需要管理员权限与可访问 `internetdownloadmanager.com` 的网络；PowerShell/WMI 被策略禁用会导致脚本退出。

## 参考回归范围（建议执行）
- `测试脚本.cmd`（管理员）：确认退出码 `0`。
- `IAS.cmd`：菜单 1/2/3 交互及 `/act` `/frz` `/res` 无人值守路径返回码 `0`。
- 静默/日志：`IAS.cmd /frz /silent /log="C:\Temp\\ias-frz.log"` 等三路，检查日志写入与退出码。
- `快速激活.cmd`：透传 `/silent` `/log=` 行为与直接调用一致。
