# 容器化与隔离环境 / Containers & Sandboxes

先说结论：**这个脚本的运行时不能容器化，也不应该容器化。** 但「在隔离环境里安全地试一遍」和
「把仓库校验放进容器」这两件事都能做。本文说明边界在哪、替代方案是什么。

## 为什么运行时不能容器化

脚本要做的事和容器能提供的东西是冲突的，四条硬性阻碍，任何一条都足以否决：

| 阻碍 | 说明 |
| --- | --- |
| **需要交互式桌面会话** | 提权走 `Start-Process -Verb RunAs`（UAC 弹窗），关 QuickEdit 走 `start conhost.exe`。Windows Server Core / Nano Server 容器没有桌面、没有交互式 UAC，也没有 conhost 图形栈 |
| **需要真实的用户配置单元** | 脚本靠 `Win32_ComputerSystem.UserName` 取当前**交互登录**用户的 SID，再操作 `HKU\<SID>` 与 `HKCU`。容器里没有交互登录用户，这个值为空，脚本会以退出码 `2` 退出 |
| **需要已安装的 IDM** | IDM 是带 GUI 的商业桌面程序，不提供无头安装，也不为容器场景发布镜像。没有 `IDMan.exe` 时脚本直接退出码 `1` |
| **需要真的启动 IDM 下载文件** | `[1]` `[2]` 的收尾验证会调 `IDMan.exe` 下载三张图片。没有 IDM 进程就没有这一步，验证环节形同虚设 |

再往前一步说：**容器化的价值是可复制的无状态部署，而这个脚本的全部意义就是修改宿主机的持久化状态**
（注册表 + 已安装的 IDM）。在容器里跑一遍，改动随容器销毁一起消失，等于什么都没做。

Windows 容器还有一个常被忽略的限制：容器镜像与宿主内核版本要匹配（进程隔离模式下更严格），
而本脚本明确要覆盖 Windows 7 到 11。用容器做兼容性验证反而比裸机更难。

## 想在隔离环境里试脚本：用沙盒或虚拟机

这才是「隔离运行」的正确答案。三个方案，按上手成本排序：

### 方案一：Windows 沙盒（Windows Sandbox）

Windows 10 / 11 **专业版及以上**内置，开箱即用，关闭即销毁。
先在「启用或关闭 Windows 功能」里勾上「Windows 沙盒」并重启。

把下面的内容存成 `ias-sandbox.wsb`，双击运行：

```xml
<Configuration>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>C:\path\to\IDM-Activation-Script</HostFolder>
      <SandboxFolder>C:\IAS</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <Networking>Enable</Networking>
</Configuration>
```

沙盒起来后，把 `C:\IAS` 里的文件**复制到桌面**再运行——映射目录是只读的，
而脚本的自检里有一项要求所在目录可写。

**沙盒的局限**：里面没有 IDM，装一次 IDM 也随沙盒销毁。所以它适合验证
「脚本能不能正常启动、自检输出对不对、菜单渲染正不正常」，**不适合验证冻结 / 激活的真实效果**。

### 方案二：虚拟机（推荐用于发版前的真实验证）

Hyper-V / VMware / VirtualBox / Parallels 都可以。装好 Windows + IDM 之后**打一个快照**，
每次验证完回滚到快照，就得到了一个可重复的干净环境。

这是 [Windows 冒烟基线](../reports/smoke-win-baseline.md) 里那些人工步骤的推荐执行环境——
冻结 / 激活 / 重置会真的改注册表并锁定 CLSID 键，不要在日常机器上反复跑。

### 方案三：另一台闲置物理机

如果要验证 Windows 7 / 8.1 这类虚拟化里不好复现的旧环境（尤其是非 ANSI 控制台的显示行为），
物理机是最可靠的。

## 可以容器化的部分：仓库校验

运行时不能容器化，但**仓库卫生与文档校验**是纯文本处理，容器化没有障碍。适合本地想复现 CI 又不想装 PowerShell 的场景。

```bash
docker run --rm -v "$PWD:/repo" -w /repo mcr.microsoft.com/powershell:latest \
  pwsh -NoProfile -File tools/validate.ps1
```

同样的方式可以跑 `tools/check-docs.ps1` 与 `tools/verify-release.ps1`。

**注意三点**：

1. `validate.ps1` 依赖 `git`，镜像里没有的话要先装，或者改用挂载了 git 的镜像。
2. 它内部会跑一次 `cmd.exe` 探测（`Probe-CmdSyntax`），**在 Linux 容器里这一步必然失败**。
   容器只适合用来看编码 / 行尾这两类校验的结果，最终判定仍以 GitHub Actions 的 `windows-latest` 为准。
3. `verify-release.ps1` 和 `check-docs.ps1` 不依赖 `cmd.exe`，在 Linux 容器里可以完整跑通。

> 本仓库的 CI **不使用容器**，直接跑在 GitHub 托管的 `windows-latest` runner 上。
> 上面的 docker 用法是给维护者本地用的便利手段，没有纳入 CI 验证。

## 不要做的事

- **不要为了「一键部署到很多机器」而把脚本塞进容器**。要批量执行请看 [服务器 / 批量部署](server.md)，
  那里说明了真正的约束（每台机器都得有交互登录会话）。
- **不要在 CI 容器里跑冻结 / 激活 / 重置**。它们会真的改注册表。CI 现有的冒烟之所以安全，
  是因为 runner 上没装 IDM，脚本走到「未检测到 IDM 安装」就退出了，一个键都不会碰。
- **不要在 Linux 容器里打发布包**。zip 条目名会写成 UTF-8 并置标志位，破坏 GBK 文件名约定。
  见 [本地部署](local.md#在-macos--linux-上文档与只读检查)。

## 相关文档

- [本地部署](local.md)
- [服务器 / 批量部署](server.md)
- [Windows 冒烟基线](../reports/smoke-win-baseline.md)
