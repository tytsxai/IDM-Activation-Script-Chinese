# release/ 目录约定

本目录**只保留一份最新的运行时发布包**：

| 文件 | 说明 |
| --- | --- |
| `IDM-Activation-Script.zip` | 最新版发布包（固定文件名，不带版本号） |
| `IDM-Activation-Script.zip.sha256` | 对应的 SHA256 校验值 |

## 为什么不带版本号

文件名固定后，README 里的下载链接只需写一次，永远指向最新版，不会因为发版漏改而把用户导到旧包。

版本号并没有消失，由这几处标识：

- Git tag 与对应的 [GitHub Release](https://github.com/tytsxai/IDM-Activation-Script-Chinese/releases) 标题；
- [`CHANGELOG.md`](../CHANGELOG.md) 与 `docs/release-notes-<版本>.md`；
- `IAS.cmd` 里的 `iasver`，脚本运行时会显示在窗口标题和菜单上方。

## 历史版本去哪儿了

历史版本的压缩包不冗余存放在仓库里，而是留在**对应 tag 的 [Release](https://github.com/tytsxai/IDM-Activation-Script-Chinese/releases) 页面 `Assets` 区**，长期可下载。

## 发版时怎么更新

见 [`docs/maintenance-checklist.md`](../docs/maintenance-checklist.md)。要点：重新打包覆盖 `IDM-Activation-Script.zip`，重算并覆盖 `.sha256`，然后把同一个包作为 Asset 上传到对应 tag 的 GitHub Release。

> 打包必须在中文 Windows 上做。在 macOS / Linux 上打包会把中文文件名写成 UTF-8 并置 EFS 标志位，与本仓库的 GBK 文件名约定不同，旧版解压工具可能显示乱码。
