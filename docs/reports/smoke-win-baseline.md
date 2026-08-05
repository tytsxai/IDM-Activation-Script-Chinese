# Windows 冒烟基线与记录模板

发版前必须在真实 Windows 上补跑的验证。CI 只覆盖语法、编码与最短路径，
真实的注册表写入、网络下载、UAC 提权都跑不到，必须人工确认。

## 前置环境

- Windows 10 / 11 x64（含 24H2 / 25H2），以管理员身份运行的 CMD。
- 已安装 IDM，代码页 `936`，网络可直连 `internetdownloadmanager.com`。
- 待验证的包：`release/IDM-Activation-Script.zip`（文件名固定，不带版本号）。
- 先核对 SHA256 与同目录 `.sha256` 一致：
  ```powershell
  Get-FileHash .\IDM-Activation-Script.zip -Algorithm SHA256
  ```

## 自动化部分（GitHub Actions，已启用）

工作流 [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)，触发条件
`push` / `pull_request` / `workflow_dispatch`，在 `windows-latest` 上执行：

- `tools/validate.ps1`：编码（GBK 无 BOM）、行尾（按 `.gitattributes`）校验；
- `IAS.cmd` 各参数组合的退出码断言（`/silent` 缺动作参数 → `2`；未装 IDM 时
  `/act` `/frz` `/noupd` → `1`）；
- `/log=路径` 与默认日志路径都确实产出日志文件，且默认文件名带真实时间戳；
- 交互主菜单渲染，断言版本提示行正确、无批处理语法错误；
- 伪造 `IDMan.exe` 后再跑一次菜单，断言版本探测与"与已适配版本不同"提示；
- `开始激活.cmd` 主入口的环境自检整条走通，断言各检查行打印、浏览器集成开关
  被正确报告、无批处理语法错误；
- 内嵌 PowerShell 段按 GBK 解码且按标记正确切分（防中文乱码回归）；
- 发布包与仓库内容一致。

**这些都不碰真实 IDM**，所以以下人工步骤不能省。

## 人工冒烟步骤（发版前必跑）

1. 以管理员身份双击 `开始激活.cmd`，确认环境自检各项通过、无乱码、
   能正常进入菜单。记录自检里的 IDM 版本与浏览器集成开关状态。
2. 走一条代表性激活路径（建议 `[2]` 激活），确认 IDM 实际进入已注册状态。
3. 再验证 `[1]` 冻结与 `[3]` 重置各一次，确认状态切换符合预期。
4. 命令行路径抽验一次：`IAS.cmd /frz /silent /log=C:\Temp\ias.log`，
   预期退出码 `0`，日志写入成功。
5. 全程观察是否有 Defender / SmartScreen 拦截、UAC 弹窗异常、控制台乱码，
   并在下表备注。

## 记录模板

| 日期 | OS / 版本 | IDM 版本 | 执行路径 | 退出码 | 日志路径 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 待补 |  |  |  |  |  |  |

## 当前状态

- 自动化冒烟在 `main` 上通过。
- 真实 IDM 环境下的冻结 / 激活 / 重置回归**待补**，请在完成后填入上表，
  异常情况附描述或截图。
