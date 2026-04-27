# IDM 激活脚本中文版 v1.3.3 本地发布说明

## 版本概览

- 版本：**v1.3.3**（2026-04-27）
- 发布性质：**搜索可见性与小白使用说明优化版**
- 发布状态：GitHub Release 已创建，`main` 与 `v1.3.3` tag 的 `Windows validation` 均已通过。
- 发布包：`release/IDM-Activation-Script-v1.3.3.zip`
- SHA256：`e85d8f0c4c1f499c0996460bba41ec97cbe98f89914ca2744696b9aecbe19e98`

## 这个版本解决什么问题

v1.3.3 不改变脚本核心逻辑，主要解决“用户找得到、看得懂、下得对、知道先运行哪个文件”的问题。

- README 顶部新增「搜索与 AI 摘要」，让 Google 与 AI 搜索更容易识别项目用途。
- 下载入口、版本号、SHA256 校验说明统一同步到 v1.3.3。
- 发布说明改为小白可读：下载压缩包、解压、先运行 `测试脚本.cmd`、再运行对应一键入口。
- 保留 v1.3.2 的上游归档说明，避免用户误以为上游仍在维护。

## 小白使用路径

1. 下载 `IDM-Activation-Script-v1.3.3.zip`。
2. 解压到普通文件夹，不要直接在压缩包里运行。
3. 右键 `测试脚本.cmd`，选择「以管理员身份运行」。
4. 自检通过后，新手优先运行 `快速激活.cmd`（冻结模式）。
5. 如果需要普通激活，运行 `普通激活.cmd`；如果之前状态异常，运行 `重置激活.cmd` 后再重试。

## 发布后验证

- `git diff --check`：通过。
- `shasum -a 256 -c release/IDM-Activation-Script-v1.3.3.zip.sha256`：通过。
- `.cmd` / `.txt` GBK 解码抽检：通过。
- GitHub Actions `Windows validation`：
  - `main` push：通过。
  - `v1.3.3` tag push：通过。

## 本地维护边界

- 本文件位于 `docs/`，用于本地维护和后续交接。
- 按当前项目规则，`docs/` 默认不推送到云端仓库。
- 对外用户应优先阅读 `README.md`、`CHANGELOG.md` 与 GitHub Release 页面。
