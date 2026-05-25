# IDM 激活脚本中文版 v1.3.5 发布说明

- 版本：**v1.3.5**（2026-05-25）
- 类型：运行时修复
- 发布包：`release/IDM-Activation-Script-v1.3.5.zip`

## 修复内容

`测试脚本.cmd` 在解析 `chcp` 输出时没有去掉代码页数字前的空格。部分 Windows 环境会输出类似 ` 936` 的值，导致脚本把已经正确处于 CP936 / GBK 的控制台误判为失败，并提示“建议运行 chcp 936”。

v1.3.5 在比较前规范化代码页字符串，避免 `936` 被误判。

## 文档同步

- README 快速下载区更新到 v1.3.5。
- FAQ 新增“IDM 自己又启动”的说明，区分脚本短暂验证、IDM 自身托盘/启动项行为和需要继续补日志排查的情况。

## 验证建议

发布前至少确认：

```powershell
.\tools\validate.ps1
Get-FileHash .\release\IDM-Activation-Script-v1.3.5.zip -Algorithm SHA256
```
