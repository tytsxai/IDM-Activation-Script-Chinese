# 配置说明 / Configuration

这个项目没有配置文件。**所有可调项一共四类**：命令行参数、脚本头部变量、运行时环境依赖、仓库级文件约束。
本文把四类都列全，并说明各自的优先级和边界。

## 一、命令行参数（面向使用者）

日常唯一需要关心的配置方式。完整契约见 [命令行接口契约](reference/cli.md)，这里只给速查：

| 参数 | 作用 |
| --- | --- |
| `/frz` `/act` `/res` `/noupd` `/reupd` | 动作，一次只传一个 |
| `/silent`（别名 `/quiet`） | 无人值守，自动开启日志 |
| `/log` / `/log=路径` | 日志落点，路径不能含空格 |

**优先级**：命令行参数 > 脚本头部变量。头部开关已经是 `1` 时，不传参数也会进入无人值守模式。

## 二、脚本头部变量（面向维护者）

`IAS.cmd` 开头有两组可编辑的变量。

### 版本标识（发版时必须维护）

```cmd
@set iasver=1.0.1
@set idmsupport=6.43
```

| 变量 | 含义 | 改动约束 |
| --- | --- | --- |
| `iasver` | 脚本自身版本号，显示在窗口标题与主菜单 | **改它必须同步 `CHANGELOG.md` 顶部的 `## vX.Y.Z` 标题**，否则 `tools/verify-release.ps1` 直接失败 |
| `idmsupport` | 最后一次**真机验证过**的 IDM 版本，主菜单据此显示「已适配 IDM x.xx」 | 只有在新版 IDM 上实测通过后才能往上抬。没实测就别改——这个值的意义就是「我们真的验证过」 |

主菜单会同时显示 `idmsupport` 和本机探测到的 IDM 版本，两者主版本号不一致时给出提示。
这是刻意替换掉「支持最新版」这类无法验证的说法。

### 动作默认开关（把参数写死进脚本）

```cmd
set _activate=0
set _freeze=0
set _reset=0
set _noupd=0
set _reupd=0
```

把任意一个改成 `1`，等同于每次运行都带上对应参数，脚本直接进入无人值守模式、不再显示菜单。

**适用场景**：要把脚本分发到一批机器上、又不方便控制调用方式时，可以做一个改好开关的定制副本。
一般情况下用命令行参数更清晰，也不会破坏发布包一致性校验。

> 改了这些开关就改了 `IAS.cmd`，`tools/verify-release.ps1` 会因为「发布包与仓库不一致」而失败。
> 定制副本请在仓库之外维护，不要提交回来。

## 三、运行时环境依赖（不由脚本控制，但决定行为）

脚本会读取这些外部状态并据此改变行为。它们不是「配置项」，但排查问题时经常是根因。

| 来源 | 影响 |
| --- | --- |
| `HKCU\Console` → `ForceV2` | 为 `0x0` 时脚本判定控制台不支持 ANSI（`_NCS=0`），走无颜色的纯文本输出分支 |
| `HKCU\Console` → `QuickEdit` | Windows 10 1511 以下据此决定是否需要 conhost 重入 |
| Windows build 号（`ver`） | `< 7600` 直接拒绝运行；`< 10586` 强制走非 ANSI 分支；`>= 17763` 才用 `start conhost.exe` 重入 |
| `PROCESSOR_ARCHITECTURE` | 决定注册表走不走 `Wow6432Node`，以及是否需要 `Sysnative` / `SysArm32` 重入 |
| PowerShell 语言模式 | 非 `FullLanguage` 直接以退出码 `2` 退出（组策略常见限制） |
| 当前控制台代码页 | 脚本自己会 `chcp 936`，无需手工设置 |
| `%SystemRoot%\Temp` 可写性 | 备份与默认日志的落点。不可写会导致备份失败 |
| 到 `internetdownloadmanager.com` 的连通性 | `/frz` `/act` 的前置条件；`/res` `/noupd` `/reupd` 不需要 |
| IDM 是否正在运行 | 所有写注册表的流程都会先 `taskkill /f /im idman.exe` |

**没有任何环境变量可以用来配置脚本行为。** 脚本读取的 `%SystemRoot%` `%ProgramFiles%` `%appdata%` 等
都是 Windows 标准变量，改它们只会让脚本找错路径，不是配置手段。

## 四、仓库级文件约束（面向贡献者）

这些不是运行时配置，但改错了会让脚本在 Windows 上直接坏掉，而且在 macOS / Linux 上看不出来。
由 [`.gitattributes`](../.gitattributes) 与 [`tools/validate.ps1`](../tools/validate.ps1) 双重把关，CI 不通过会阻止合并。

| 文件类型 | 编码 | 行尾 | 校验者 | 为什么 |
| --- | --- | --- | --- | --- |
| `*.cmd` | **GBK（936），无 BOM** | CRLF | `.gitattributes` + `validate.ps1` | 这些字节会在 `chcp 936` 的控制台里直接 echo 出来；改成别的编码就是乱码。LF 会触发脚本自带的换行自检 |
| `使用说明.txt` | UTF-8 **带 BOM** | CRLF | `.gitattributes` | 它是在记事本里打开的，不走控制台。带 BOM 能让各语言版本的记事本都正确识别 |
| `llms.txt` / `llms-full.txt` | UTF-8 无 BOM | CRLF | `.gitattributes` | `*.txt` 规则统一约束行尾；这两个文件不走控制台，编码不受 GBK 约束 |
| `*.md` | UTF-8 无 BOM | LF | `.gitattributes` | GitHub 渲染 |
| `*.yml` / `*.yaml` | UTF-8 | LF | `.gitattributes` | YAML 解析器要求 |
| `*.ps1` | UTF-8 **带 BOM** | LF | `.gitattributes` | CI 用 `pwsh` 执行，但带 BOM 能保证 Windows PowerShell 5.1 也按 UTF-8 解码脚本里的中文 |
| `LICENSE` / `.gitignore` / `.gitattributes` | — | LF | `.gitattributes` | 扩展名为空的文件需要显式规则，否则 Windows 检出会改成 CRLF，发布包内容就依赖于打包机器 |
| `release/*.zip` | 二进制 | — | `.gitattributes` | 任何 EOL 启发式改动都会让公布的 SHA256 对不上 |

`validate.ps1` 的 GBK 校验**只作用于 `.cmd`**，原因写在脚本头部注释里：`.txt` 是给编辑器读的，不需要 GBK。

### 在 macOS / Linux 上怎么核对

本机没有 Windows 时，最终判定以 CI 为准，但可以先自查：

```bash
# .cmd 是否能按 GBK 解码
iconv -f GBK -t UTF-8 IAS.cmd > /dev/null && echo "GBK OK"

# 阅读 GBK 源码
iconv -f GBK -t UTF-8 IAS.cmd | less

# 行尾状态（w/ 列是工作区，i/ 列是索引）
git ls-files --eol
```

> **注意一个常见陷阱**：`git ls-files --eol` 里出现 `w/lf` 而 `attr/text eol=crlf`，说明本地工作区的文件
> 被某个编辑器或工具改成了 LF。这不影响提交内容（git 存的一直是 LF，检出时才转 CRLF），
> 但**不要在这种状态下本地打包**——打出来的 zip 里会是 LF 的 `IAS.cmd`，用户一运行就被换行自检拒绝。
> 用 `rm <文件> && git checkout -- <文件>` 恢复。

## 发布包清单

`tools/pack-release.ps1` 里的 `$payload` 数组定义了发布包包含哪些文件：

```
开始激活.cmd  IAS.cmd  使用说明.txt  README.md  CHANGELOG.md  SECURITY.md  LICENSE
```

改这个数组等于改对外发布的文件集合，必须同步：

- `README.md` 的「文件说明」表
- `tools/verify-release.ps1` 的 `$runtimeFiles`（会被执行的文件，不一致时硬失败；其余只警告）

`llms.txt` 与 `llms-full.txt` **刻意不在清单里**——它们是给 AI 搜索引擎读的仓库级文件，随发布包分发没有意义。

## 相关文档

- [命令行接口契约](reference/cli.md)
- [关键模块与核心逻辑](modules.md)
- [文档同步规则](doc-sync.md) — 改了本文里的哪一项，需要连带更新哪些文件
- [CONTRIBUTING.md](../CONTRIBUTING.md) — 提交前的本地自检命令
