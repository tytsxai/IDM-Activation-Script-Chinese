# IDM 激活脚本中文版 v1.3.6 发布说明

- 版本：**v1.3.6**（2026-06-14）
- 类型：运行时修复 + 入口精简
- 发布包：`release/IDM-Activation-Script-v1.3.6.zip`

## 背景

近期多个 Issue（#11 #12 #13 #14）反映：环境自检阶段把可写目录误报为"脚本目录不可写"，少数含 `(x86)` 的安装目录提权时直接闪退报错，Win11 新版上 WMI 检测误报。本版集中修复，并把过多的入口脚本合并为一个。

## 修复内容

1. **"脚本目录不可写"误报（#11 / #13 / #14）**
   写入测试 `> "!writeTest!" echo test >nul 2>&1` 中的 `>nul` 覆盖了对测试文件的重定向，文件根本没被创建，于是任何目录都被判为不可写。改为 `(echo test)> "!writeTest!" 2>nul`。

2. **含 `(x86)` 路径提权崩溃"此时不应有 \Internet"（#12）**
   旧入口的提权写法 `Start-Process -FilePath \"%~f0\"` 里的 `\"` 会让 CMD 提前闭合引号，使路径中的 `)` 触发语法错误。新入口 `开始激活.cmd` 改用单引号包裹路径，并用标签跳转避开括号块。

3. **Win11 24H2/25H2 WMI 自检误报（#14）**
   `wmic` 在新版 Windows 已移除。自检改为优先 PowerShell `Get-CimInstance`，`wmic` 仅作回退。

4. **代码页自检解析失败（#12）**
   改用 `chcp | find "936"`，不再依赖 `chcp` 输出的具体格式。

## 入口精简

原 `测试脚本.cmd` / `快速激活.cmd` / `普通激活.cmd` / `重置激活.cmd` 四个脚本，合并为单一的 **`开始激活.cmd`**：

> 双击 `开始激活.cmd` → 授予管理员权限 → 自动环境自检 → 弹出菜单：
> `[1]` 激活（冻结，推荐）、`[2]` 激活、`[3]` 重置激活/试用期。

`IAS.cmd` 作为核心引擎保持不变（版本号升至 1.3.6）。

## 文档同步

- README、`llms.txt`、`ARCHITECTURE.md`、`docs/README.md`、Issue 模板全部更新为单入口模型。
- `使用说明.txt` 改为 UTF-8（带 BOM），避免新版记事本乱码；`tools/validate.ps1` 仅对 `.cmd` 强制 GBK。

## 验证建议

发布前至少确认：

```powershell
.\tools\validate.ps1
Get-FileHash .\release\IDM-Activation-Script-v1.3.6.zip -Algorithm SHA256
```

并在管理员环境下双击 `开始激活.cmd`，确认：环境检测全绿、能进入菜单、`[1]` 冻结激活成功；把脚本放进含 `(x86)` 的目录再试一次，确认不再报"此时不应有 \Internet"。
