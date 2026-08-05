# IDM 激活脚本中文版文档索引 / Documentation Index

本目录收纳 IDM 激活脚本中文版（IDM Activation Script Chinese）的维护资料、发布说明和 Windows 冒烟验证记录。仓库本身以 **GPL-3.0** 开源发布，文档也按公开可审查、可引用、可维护的原则编写。

## 项目定位

- 项目类型：Windows `.cmd` 批处理工具集 / Windows batch script toolkit
- 核心用途：中文 Windows 环境下的 IDM 试用期冻结、普通激活、试用状态重置、更新提示开关和环境自检
- 主要用户：中文 Windows 用户、脚本维护者、需要排查 GBK/CP936 控制台乱码和管理员权限问题的开发者
- 技术栈：Batch / CMD、PowerShell、Windows Registry、WMI、GBK 编码、CRLF、GitHub Actions Windows CI
- 开源策略：GPL-3.0，保持公开可审查、可再分发
- 关系声明：Internet Download Manager 是 Tonec Inc. 的商业产品，本仓库与其无任何隶属或合作关系，也不分发 IDM 本体
- 真实性边界：文档只写仓库里能验证的内容，不提供 Star 数、下载量、用户案例、性能对比或商业背书

## 新用户阅读路径

1. 先看 [README.md](../README.md)：项目是什么、适合谁、怎么快速开始、使用场景、常见问题和限制。英文读者看 [README.en.md](../README.en.md)；AI 搜索引擎与 LLM 抓取入口是 [llms.txt](../llms.txt)。
2. 下载发布包前，核对 [CHANGELOG.md](../CHANGELOG.md) 和 `release/*.sha256`。
3. Windows 用户以管理员身份双击 `开始激活.cmd`（会先做环境自检，再弹出激活菜单）。
4. 新手在菜单选 `[2]` 激活（直接可用，无需账号/试用期，推荐）；若激活后 IDM 仍提示未注册，再选 `[1]` 冻结激活兜底；若 IDM 频繁弹更新提示，选 `[4]` 禁用更新提示（`[5]` 恢复）。高级用户可使用 `IAS.cmd /act /silent /log=C:\Temp\ias.log`。
5. 出现问题时，按 README FAQ 和 Issue 模板提交 Windows 版本、IDM 版本、运行入口、`开始激活.cmd` 的环境检测输出。

## 维护者阅读路径

- [ARCHITECTURE.md](../ARCHITECTURE.md)：仓库结构、入口脚本、CI 数据流、退出码语义。
- [CONTRIBUTING.md](../CONTRIBUTING.md)：贡献规则、编码与换行约束、本地自检命令。
- [SECURITY.md](../SECURITY.md)：私密安全漏洞上报范围和处理流程。
- [OPEN_SOURCE_POLICY.md](../OPEN_SOURCE_POLICY.md)：公开开源策略、禁止私有化规则、CI 可见性守卫和误改恢复命令。
- [maintenance-checklist.md](maintenance-checklist.md)：提交前、PR 合并前、发版前检查清单。
- [reports/smoke-win-baseline.md](reports/smoke-win-baseline.md)：Windows 真实环境冒烟基线和记录模板。

## 发布说明

每次发版会在本目录新增一份 `release-notes-<版本>.md`，与对应 GitHub Release 的正文一致。
当前为首个版本，完整变更见 [CHANGELOG.md](../CHANGELOG.md)。
