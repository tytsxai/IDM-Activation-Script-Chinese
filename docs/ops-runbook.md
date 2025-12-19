# 运行与回滚手册（生产就绪）

本手册用于把脚本运行过程标准化，确保出现问题时可快速定位、回滚、复盘。

## 生产执行建议

- **执行环境**：Windows 10/11 x64，管理员 CMD，IDM 已安装，网络可直连 `internetdownloadmanager.com`。
- **执行前自检**：管理员运行 `测试脚本.cmd`，确保 10/10 全绿且退出码为 `0`。
- **推荐命令（无人值守 + 留痕）**：

```cmd
IAS.cmd /frz /silent /log="C:\Temp\ias-frz.log"
```

> 说明：`/silent` 会自动开启日志；如不指定 `/log=`，默认写入 `%SystemRoot%\Temp\IAS-[时间戳].log`。

## 日志与退出码

| 退出码 | 含义 | 处理建议 |
| --- | --- | --- |
| `0` | 成功 | 无需处理 |
| `1` | 运行失败或部分步骤失败 | 保留日志与备份，按下方回滚步骤处理 |
| `2` | 环境/参数/权限不满足 | 先修复环境（管理员/PowerShell/WMI/网络/代码页）后再运行 |

**日志位置**
- 默认：`%SystemRoot%\Temp\IAS-[时间戳].log`
- 指定：`/log="C:\Temp\ias-frz.log"`

**问题上报建议**
- 贴出 `测试脚本.cmd` 的输出与退出码。
- 提供运行命令与对应日志文件。

## 备份与回滚（关键）

脚本执行前会自动导出注册表备份，默认路径如下：

```
C:\Windows\Temp\_Backup_HKCU_CLSID_[时间戳].reg
C:\Windows\Temp\_Backup_HKU-[SID]_CLSID_[时间戳].reg
C:\Windows\Temp\_Backup_HKCU_DownloadManager_[时间戳].reg
C:\Windows\Temp\_Backup_HKU-[SID]_DownloadManager_[时间戳].reg
C:\Windows\Temp\_Backup_HKLM_IDM_[时间戳].reg
```

**回滚步骤（推荐）**
1. 关闭 IDM（必要时 `taskkill /f /im idman.exe`）。
2. 找到同一时间戳的 `.reg` 备份文件。
3. 管理员 CMD 依次执行（示例）：

```cmd
reg import "C:\Windows\Temp\_Backup_HKCU_CLSID_YYYYMMDD-HHMMSSmmm.reg"
reg import "C:\Windows\Temp\_Backup_HKCU_DownloadManager_YYYYMMDD-HHMMSSmmm.reg"
reg import "C:\Windows\Temp\_Backup_HKLM_IDM_YYYYMMDD-HHMMSSmmm.reg"
```

> 如果存在 `HKU-[SID]` 的备份文件，也请一并导入。

**替代方案**
- 只需恢复试用期状态时，可使用 `IAS.cmd /res`（重置激活/试用期）。

## 异常处置建议

- 如果运行失败但已生成备份，优先回滚后再排障。
- 若网络不可达（公司代理/VPN/防火墙），先恢复网络可用性再重试。
- 若 PowerShell/WMI 被策略限制，需先由管理员解除限制。
