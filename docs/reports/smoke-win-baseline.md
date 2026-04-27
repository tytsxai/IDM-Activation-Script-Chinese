# IDM 激活脚本 v1.3.3 Windows 冒烟基线

## 范围与前置
- 最小路径验证其一即可（冻结 `/frz`、激活 `/act` 或重置 `/res`），推荐冻结。
- 环境：Win10/11 x64（含 24H2，管理员 CMD），IDM 已安装，代码页 936，网络可直连 `internetdownloadmanager.com`。
- 包：`release/IDM-Activation-Script-v1.3.3.zip`。
- SHA256：`e85d8f0c4c1f499c0996460bba41ec97cbe98f89914ca2744696b9aecbe19e98`（同目录 `.sha256` 文件应一致）。

## 自动化冒烟（GitHub Actions，已启用）
- 工作流：[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)，触发条件 `push` / `pull_request` / `workflow_dispatch`。
- 校验步骤：
  1. `pwsh tools/validate.ps1`：编码（GBK，无 BOM）、行尾（按 `.gitattributes`）、`cmd.exe` 基础探测。
  2. `chcp 936 && IAS.cmd /silent`：断言退出码为 `2`（"静默模式缺动作参数"路径），覆盖脚本启动到参数解析。
- 这两步只能验证语法和最短路径；完整功能（注册表写入、网络下载、UI 提权）必须在下方真实 Windows 环境补跑。

## 人工冒烟执行步骤（发版前必跑）
1. `测试脚本.cmd`（管理员），确认 10/10 全绿且退出码 `0`；若失败，记录脚本末尾打印的「首个未通过项」与对应 README 章节。
2. 运行三选一入口（`快速激活.cmd` / `普通激活.cmd` / `重置激活.cmd`），或 `IAS.cmd /frz|/act|/res` 的一个代表性路径（建议使用静默 + 日志，例 `IAS.cmd /frz /silent /log="C:\Temp\ias.log"`），预期退出码 `0`，日志写入成功。
3. 观察是否有 Defender / SmartScreen 拦截、UAC 弹窗异常或编码乱码，并在记录表中备注。
4. 提交 PR 前另行运行 `IAS.cmd /silent`（无动作参数）一次，确认退出码为 `2`（与 CI 同款冒烟，可在本地提前发现回归）。

## 记录模板
| 日期 | OS / 版本 | 执行命令 | 退出码 | 日志路径 | 备注 |
| --- | --- | --- | --- | --- | --- |
| 待补 |  |  |  |  |  |

## 当前状态
- v1.3.3 已完成发布包 SHA256 校验；GitHub Actions `Windows validation` 在 `main` 与 `v1.3.3` tag 上均通过，覆盖 `/silent` 最短路径冒烟。
- 真实 IDM 注册表流程（冻结 / 激活 / 重置）的发布前回归请在 Win10/11 管理员环境完成后补充上表并附异常描述 / 截图（如有）。
