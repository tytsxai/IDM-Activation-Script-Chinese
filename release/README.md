# release/ 目录约定

本目录**只保留一份最新的运行时发布包**，它也是本项目**唯一的下载入口**：

| 文件 | 说明 |
| --- | --- |
| `IDM-Activation-Script.zip` | 最新版发布包（固定文件名，不带版本号） |
| `IDM-Activation-Script.zip.sha256` | 对应的 SHA256 校验值 |

包内清单（由 [`tools/pack-release.ps1`](../tools/pack-release.ps1) 的 `$payload` 定义）：

```
开始激活.cmd  IAS.cmd  使用说明.txt  README.md  CHANGELOG.md  SECURITY.md  LICENSE
```

`docs/`、`tools/`、`llms.txt`、`llms-full.txt` **不随包分发**——它们是仓库级的维护与索引资料。

## 不使用 GitHub Releases

本项目**不发布 GitHub Release，仓库内也没有 tag**。下载、校验、版本号全部围绕本目录与
[`CHANGELOG.md`](../CHANGELOG.md)：

- 下载地址永远是 [`release/IDM-Activation-Script.zip`](./IDM-Activation-Script.zip) 的 raw 链接，README 里写一次就不用改。
- 版本号由三处标识，**由 CI 强制一致**：
  - [`CHANGELOG.md`](../CHANGELOG.md) 顶部的 `## vX.Y.Z` 标题（`tools/verify-release.ps1` 校验）；
  - `IAS.cmd` 头部的 `iasver`，运行时显示在窗口标题和菜单上方；
  - `README.md` 页首的版本徽章（`tools/check-docs.ps1` 校验）。

## 为什么文件名不带版本号

文件名固定后，README 里的下载链接只需写一次，永远指向最新版，不会因为发版漏改而把用户导到旧包。
代价是「只改了仓库、忘了重新打包」不会有任何征兆——这一条由
[`tools/verify-release.ps1`](../tools/verify-release.ps1) 在 CI 中守住：包内会被执行的文件
（`IAS.cmd`、`开始激活.cmd`、`使用说明.txt`）与仓库不一致时直接失败。

## 历史版本怎么取

历史版本的压缩包不冗余存放在本目录，而是留在 **git 历史**里。查看这个文件的全部改动：

```bash
git log --oneline -- release/IDM-Activation-Script.zip
```

取出某一次提交时的包与校验值：

```bash
git show <commit>:release/IDM-Activation-Script.zip        > IDM-Activation-Script-old.zip
git show <commit>:release/IDM-Activation-Script.zip.sha256
```

对应版本号看那次提交时的 `CHANGELOG.md`：

```bash
git show <commit>:CHANGELOG.md | head -40
```

## 发版时怎么更新

完整清单见 [`docs/maintenance-checklist.md`](../docs/maintenance-checklist.md)。要点：

1. **在中文 Windows 上**跑 `pwsh -NoProfile -File tools/pack-release.ps1` 重新打包，覆盖本目录两个文件；
2. 跑 `pwsh -NoProfile -File tools/verify-release.ps1` 确认包与仓库一致、版本号自洽；
3. 连同 `CHANGELOG.md` 的新版本段落一起提交。

> **打包必须在中文 Windows 上做。** 在 macOS / Linux 上打包会把中文文件名写成 UTF-8 并置 EFS 标志位，
> 与本仓库的 GBK 文件名约定不同，旧版解压工具可能显示乱码。
>
> 手上没有 Windows 时，从 CI 拿现成的：任意一次 Actions 运行都会上传 `release-bundle-rebuilt` artifact
> （`if: always()`，校验失败时也会产出），下载后放回本目录即可。命令见
> [运维与排错指南](../docs/operations.md#发布包与仓库不一致)。
