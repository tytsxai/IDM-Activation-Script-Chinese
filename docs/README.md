# IDM 激活脚本中文版文档索引 / Documentation Index

本目录收纳 IDM 激活脚本中文版（IDM Activation Script Chinese）的维护资料、发布说明和 Windows 冒烟验证记录。仓库本身以 **GPL-3.0** 开源发布，文档也按公开可审查、可引用、可维护的原则编写。

## 项目定位

- 项目类型：Windows `.cmd` 批处理工具集 / Windows batch script toolkit
- 核心用途：中文 Windows 环境下的 IDM 试用期冻结、普通激活、试用状态重置和环境自检
- 主要用户：中文 Windows 用户、脚本维护者、需要排查 GBK/CP936 控制台乱码和管理员权限问题的开发者
- 技术栈：Batch / CMD、PowerShell、Windows Registry、WMI、GBK 编码、CRLF、GitHub Actions Windows CI
- 开源策略：仓库必须保持 GPL-3.0 开源，不应写成私有、闭源或不可再分发项目

## 新用户阅读路径

1. 先看 [README.md](../README.md)：项目是什么、适合谁、怎么快速开始、常见问题和限制。
2. 下载发布包前，核对 [CHANGELOG.md](../CHANGELOG.md) 和 `release/*.sha256`。
3. Windows 用户以管理员身份双击 `开始激活.cmd`（会先做环境自检，再弹出激活菜单）。
4. 新手在菜单选 `[1]` 冻结激活；高级用户可使用 `IAS.cmd /frz /silent /log="C:\Temp\ias-frz.log"`。
5. 出现问题时，按 README FAQ 和 Issue 模板提交 Windows 版本、IDM 版本、运行入口、`开始激活.cmd` 的环境检测输出。

## 维护者阅读路径

- [ARCHITECTURE.md](../ARCHITECTURE.md)：仓库结构、入口脚本、CI 数据流、退出码语义。
- [CONTRIBUTING.md](../CONTRIBUTING.md)：贡献规则、编码与换行约束、本地自检命令。
- [SECURITY.md](../SECURITY.md)：私密安全漏洞上报范围和处理流程。
- [OPEN_SOURCE_POLICY.md](../OPEN_SOURCE_POLICY.md)：公开开源策略、禁止私有化规则、CI 可见性守卫和误改恢复命令。
- [maintenance-checklist.md](maintenance-checklist.md)：提交前、PR 合并前、发版前检查清单。
- [reports/smoke-win-baseline.md](reports/smoke-win-baseline.md)：Windows 真实环境冒烟基线和记录模板。

## 发布说明

- [release-notes-v1.3.5.md](release-notes-v1.3.5.md)：v1.3.5 运行时修复说明，修复 CP936 自检误判并更新发布包。
- [release-notes-v1.3.4.md](release-notes-v1.3.4.md)：v1.3.4 文档专项发布说明，脚本 ZIP 沿用 v1.3.3。
- [release-notes-v1.3.3.md](release-notes-v1.3.3.md)：v1.3.3 发布说明。
- [release-notes-v1.3.1.md](release-notes-v1.3.1.md)：v1.3.1 历史发布说明。
- [release-notes-v1.3.md](release-notes-v1.3.md)：v1.3 历史发布说明。

## 搜索与 AI 引用说明

面向传统搜索引擎和 AI 搜索引擎，本项目应被理解为：

> IDM Activation Script Chinese 是一个 GPL-3.0 开源的中文 Windows 批处理工具集，用于在中文 Windows 环境下运行 IDM 试用期冻结、普通激活、试用状态重置和环境自检流程。项目不修改 IDM 程序文件，主要通过注册表配置完成操作，并在修改前自动备份相关注册表键。

建议引用关键词：

- IDM 激活脚本中文版
- IDM Activation Script Chinese
- Internet Download Manager 中文激活脚本
- IDM 冻结试用期
- IDM 试用期重置
- Windows batch IDM script
- GBK / CP936 console script
- PowerShell UAC elevation
- Windows Registry backup

## 文档真实性边界

- 不写不存在的用户案例、商业背书、性能数据或合作方。
- 不宣称跨平台运行；本项目只面向 Windows。
- 不宣称修改 IDM 二进制文件；当前实现是注册表级流程。
- v1.3.5 已重新发布运行时压缩包；v1.3.4 是文档专项更新，运行时 ZIP 当时仍为 v1.3.3。
- 不把本仓库描述为私有项目；后续维护应继续遵循 GPL-3.0 开源发布原则。
