# 本地部署 / Local Setup

这个项目是**免安装的批处理脚本**：没有安装程序、没有服务、没有守护进程、没有需要配置的运行时。
「部署」在这里只有两个含义——**终端用户把它跑起来**，和**维护者把开发环境搭起来**。两者都在本文。

## 一、终端用户：跑起来

### 前置条件

| 项 | 要求 |
| --- | --- |
| 操作系统 | Windows 7 / 8 / 8.1 / 10 / 11（含 24H2）。低于 build 7600 会被直接拒绝 |
| 权限 | 管理员。脚本会自动弹 UAC，不用手工设置 |
| 依赖 | 无。只用 Windows 自带的 `cmd.exe`、PowerShell、`reg.exe`、WMI |
| 已安装的 IDM | 需要。脚本不分发也不安装 IDM |
| 网络 | `[1]` 冻结与 `[2]` 激活需要能连通 `internetdownloadmanager.com`；`[3]` `[4]` `[5]` 可离线 |
| 磁盘位置 | 普通可写目录。**不要放在 `C:\Program Files`，不要在压缩包里直接双击** |

### 步骤

1. **下载**：从仓库的 [`release/IDM-Activation-Script.zip`](../../release/IDM-Activation-Script.zip) 取最新包
   （下载入口见 [README 的「快速下载」](../../README.md#快速下载)）。
2. **校验**（可选但推荐）：

   ```powershell
   Get-FileHash .\IDM-Activation-Script.zip -Algorithm SHA256
   ```

   与同目录 `.sha256` 文件里的值比对一致再解压。
3. **全部解压**到一个普通文件夹。压缩包里的 `开始激活.cmd` 与 `IAS.cmd` 必须在同一目录——
   在压缩包查看器里直接双击会让脚本从临时目录运行，脚本检测到后会以退出码 `2` 拒绝执行。
4. **双击 `开始激活.cmd`**，在 UAC 窗口点「是」。
5. 等 9 项环境自检跑完，在菜单里按数字选择。拿不准就选 `[1]` 冻结试用期。

### 第一次运行会遇到的系统提示

这些都是 Windows 对未签名脚本的标准行为，不是脚本有问题：

| 提示 | 处理 |
| --- | --- |
| UAC「你要允许此应用对你的设备进行更改吗」 | 点「是」 |
| SmartScreen「Windows 已保护你的电脑」 | 点「更多信息」→「仍要运行」 |
| 文件属性里的「此文件来自其他计算机」 | 右键 → 属性 → 勾选「解除锁定」→ 确定 |
| Defender / 360 / 火绒报毒 | 启发式误报（脚本要写注册表、要提权）。校验过 SHA256 后可把解压目录加白名单 |

### 不用图形菜单的跑法

以**管理员身份**打开 CMD，进入解压目录：

```cmd
IAS.cmd /frz
```

完整参数与退出码见 [命令行接口契约](../reference/cli.md)。批量与无人值守见 [服务器 / 批量部署](server.md)。

### 卸载 / 还原

脚本没有安装任何东西，删掉解压目录就等于卸载。要把注册表改动也还原：

- **推荐**：运行菜单 `[3]` 重置——它会解开被锁定的 CLSID 键并清掉写入的注册信息。
- 或者导入运行时自动生成的备份：`C:\Windows\Temp\_Backup_*_CLSID_*.reg`，双击导入即可。
- 备份与日志不会自动清理，确认 IDM 正常后可以自行删除，见 [注册表与文件系统副作用](../reference/registry.md#文件系统)。

## 二、维护者：本地开发环境

### 克隆

```bash
git clone git@github.com:tytsxai/IDM-Activation-Script-Chinese.git
cd IDM-Activation-Script-Chinese
```

**不要改动 git 的换行配置。** 仓库靠 [`.gitattributes`](../../.gitattributes) 保证 `.cmd` / `.txt` 检出为 CRLF、
`.md` / `.yml` / `.ps1` 检出为 LF。设置 `core.autocrlf` 会和它打架。

### 在 Windows 上（完整环境）

这是唯一能跑全部校验的环境。

```powershell
# 仓库卫生：编码、行尾、cmd.exe 可用性
pwsh -NoProfile -File tools/validate.ps1

# 文档与代码是否同步：参数、退出码、标签、版本号、站内链接
pwsh -NoProfile -File tools/check-docs.ps1

# 发布包与仓库是否一致、版本号是否自洽
pwsh -NoProfile -File tools/verify-release.ps1

# 改了 IAS.cmd / 开始激活.cmd / 使用说明.txt 之后重新打包
pwsh -NoProfile -File tools/pack-release.ps1
```

冒烟测试可以照抄 CI 的做法，不需要安装 IDM：

```cmd
chcp 936
IAS.cmd /silent            & echo 期望 2（静默但没给动作参数），实际 %errorlevel%
IAS.cmd /noupd /silent     & echo 期望 1（本机没装 IDM），实际 %errorlevel%
echo 0| IAS.cmd -qedit     & rem 渲染一次主菜单再退出
```

> `-qedit` 跳过为关闭 QuickEdit 而做的 conhost 重入，否则脚本会另开窗口、当前窗口立刻返回。

**要跑真实的冻结 / 激活 / 重置，必须装 IDM**，并按
[Windows 冒烟基线](../reports/smoke-win-baseline.md) 的步骤记录结果。

### 在 macOS / Linux 上（文档与只读检查）

没有 PowerShell 和 `cmd.exe`，能做的有限，但足够改文档：

```bash
# 阅读 GBK 源码
iconv -f GBK -t UTF-8 IAS.cmd | less
iconv -f GBK -t UTF-8 开始激活.cmd | less

# GBK 解码自查（等价于 validate.ps1 的编码校验）
for f in IAS.cmd 开始激活.cmd; do iconv -f GBK -t UTF-8 "$f" >/dev/null && echo "$f GBK OK"; done

# 行尾状态
git ls-files --eol
```

**在 macOS / Linux 上不能做的三件事**：

1. **不能打包**。`tools/pack-release.ps1` 要求 zip 条目名按 GBK 存储且不置 UTF-8 标志位，
   用 `zip` 或 `Compress-Archive` 打出来的包不满足这个约定，旧解压工具会显示乱码。
2. **不能验证脚本行为**。`cmd.exe`、注册表、WMI、UAC 都不存在。
3. **不能信任本地行尾**。见 [配置说明的陷阱提示](../configuration.md#在-macos--linux-上怎么核对)。

改了运行时文件又需要一个新发布包时，**从 CI 拿**：任意一次 Actions 运行都会上传
`release-bundle-rebuilt` artifact（`if: always()`，校验失败时也会产出），下载后放回 `release/` 即可。

```bash
gh run download <run-id> -R tytsxai/IDM-Activation-Script-Chinese -n release-bundle-rebuilt -D /tmp/bundle
cp /tmp/bundle/IDM-Activation-Script.zip     release/
cp /tmp/bundle/IDM-Activation-Script.zip.sha256 release/
```

### 想在隔离环境里试脚本

不要在日常使用的机器上验证冻结 / 激活 / 重置——它们会真的改注册表。
隔离方案见 [容器化与隔离环境](container.md)。

## 相关文档

- [容器化与隔离环境](container.md)
- [服务器 / 批量部署](server.md)
- [配置说明](../configuration.md)
- [运维与排错指南](../operations.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
