# IDM 激活脚本中文版 — 文档索引 / Documentation Index

本目录是 IDM 激活脚本中文版（IDM Activation Script Chinese）的完整文档体系入口。
仓库以 **GPL-3.0** 开源发布，文档按公开可审查、可引用、可维护的原则编写：**只写仓库里能自行验证的内容**。

> 只想拿一份结构化的项目摘要（给大语言模型或 AI 搜索引擎用）？读仓库根目录的
> [llms.txt](../llms.txt)（精简版）或 [llms-full.txt](../llms-full.txt)（完整技术参考）。

## 项目概述 / Project Overview

| 项目 | 说明 |
| --- | --- |
| **项目类型** | Windows `.cmd` 批处理工具（Windows batch script toolkit） |
| **核心用途** | 中文 Windows 环境下的 IDM 试用期冻结、激活、试用状态重置、更新提示开关 |
| **适合谁** | 中文 Windows 用户、需要管理 IDM 试用期的个人用户、研究注册表与 GBK 编码的开发者 |
| **技术栈** | Batch/CMD、PowerShell、Windows Registry、WMI/CIM、GBK、GitHub Actions CI |
| **平台** | Windows 7 / 8 / 8.1 / 10 / 11（含 24H2），仅 Windows |
| **许可证** | GPL-3.0 |
| **分发方式** | 仓库内 [`release/`](../release/) 目录的固定文件名 zip + SHA256。**不使用 GitHub Releases，仓库内没有 tag** |
| **上游关系** | 源自已归档的 [WindowsAddict/IDM-Activation-Script](https://github.com/WindowsAddict/IDM-Activation-Script)，由本仓库独立维护 |
| **与 IDM 的关系** | 与 Tonec Inc. 无任何隶属、授权或合作关系，不分发 IDM 安装包 |

## 全部文档

### 用户文档

| 文档 | 内容 |
| --- | --- |
| [README.md](../README.md) | 项目主文档：功能、使用方法、使用场景、19 条 FAQ、技术细节 |
| [使用说明.txt](../使用说明.txt) | 极简上手指南，随发布包分发，记事本可直接打开 |
| [本地部署](deployment/local.md) | 前置条件、下载校验、运行步骤、卸载还原；以及维护者的本地开发环境 |
| [CHANGELOG.md](../CHANGELOG.md) | 唯一的对外版本变更历史 |

### 架构与实现

| 文档 | 内容 |
| --- | --- |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | 仓库结构、目录职责、高风险约束、CI 数据流、发布包一致性守卫 |
| [关键模块与核心逻辑](modules.md) | 两个脚本的分工、启动阶段的每一道关卡、三条业务分支、CLSID 扫描与锁定手法、「看起来能简化实际不能动」的地方 |

### 部署

| 文档 | 内容 |
| --- | --- |
| [本地部署](deployment/local.md) | 终端用户怎么跑起来 + 维护者怎么搭开发环境 |
| [容器化与隔离环境](deployment/container.md) | 为什么运行时不能容器化、该用什么替代（Windows 沙盒 / 虚拟机）、哪部分可以容器化 |
| [服务器 / 批量部署](deployment/server.md) | 无人值守调用、多机编排（计划任务 / Remoting / PsExec）、三条绕不过去的约束、明确不支持的场景 |

### 参考

| 文档 | 内容 |
| --- | --- |
| [配置说明](configuration.md) | 四类可调项：命令行参数、脚本头部变量、运行时环境依赖、仓库级文件约束 |
| [命令行接口契约](reference/cli.md) | 参数、退出码、日志格式、标准输出约定——脚本化调用以此为准 |
| [内部子程序接口](reference/internals.md) | `IAS.cmd` 每个标签的输入、副作用与返回约定 |
| [注册表与文件系统副作用](reference/registry.md) | 脚本读、写、删、锁的每一个键与文件，以及网络与进程行为 |

### 运维与维护

| 文档 | 内容 |
| --- | --- |
| [运维与排错指南](operations.md) | 怎么定位问题、日志怎么读、故障树、回滚、CI 红了怎么办 |
| [文档同步规则](doc-sync.md) | 改了什么必须同步什么，以及 CI 强制的六组断言 |
| [维护 / 发布检查清单](maintenance-checklist.md) | 提交前、PR 合并前、发版前的逐项检查 |
| [Windows 冒烟基线](reports/smoke-win-baseline.md) | CI 覆盖了什么、还有什么必须人工跑，以及记录模板 |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | 贡献规则、编码与换行约束、本地自检命令 |
| [SECURITY.md](../SECURITY.md) | 安全漏洞上报范围与流程 |
| [OPEN_SOURCE_POLICY.md](../OPEN_SOURCE_POLICY.md) | 公开开源策略、禁止私有化规则、CI 可见性守卫 |

## 新用户阅读路径 / Getting Started

1. 先看 [README.md](../README.md)：项目是什么、适合谁、怎么快速开始、使用场景、常见问题和限制。
2. 从 [`release/`](../release/) 目录下载 zip，用同目录的 `.sha256` 校验，再**全部解压**。
3. 以管理员身份双击 `开始激活.cmd`（会先做 9 项环境自检，再弹出菜单）。
4. 推荐选择：
   - `[1]` **冻结试用期**（推荐）— 不写序列号，在较新版 IDM 上最稳
   - `[2]` 激活 — 从未领过试用期、想让 IDM 直接可用时选
   - `[4]` 禁用更新提示 — IDM 频繁弹「发现新版本」时用
5. 高级用法：`IAS.cmd /frz /silent /log=C:\Temp\ias.log`（管理员 CMD），完整契约见 [命令行接口契约](reference/cli.md)。
6. 出问题时先看 [运维与排错指南](operations.md) 的「三件事按顺序做」，再按 Issue 模板反馈。

## 维护者阅读路径 / Maintainer Guide

1. [ARCHITECTURE.md](../ARCHITECTURE.md) — 先建立仓库全貌
2. [关键模块与核心逻辑](modules.md) — 再理解脚本怎么跑，**尤其是最后一节「看起来能简化、实际不能动」**
3. [CONTRIBUTING.md](../CONTRIBUTING.md) + [配置说明](configuration.md) — 编码与行尾约束，改错了在 macOS / Linux 上看不出来
4. [文档同步规则](doc-sync.md) — 改代码时要连带更新哪些文档
5. [维护 / 发布检查清单](maintenance-checklist.md) — 发版前逐项过
6. [Windows 冒烟基线](reports/smoke-win-baseline.md) — 人工验证并回填记录表

## 发布说明 / Release Notes

发布说明的唯一载体是 [CHANGELOG.md](../CHANGELOG.md)，本目录**不再单独保存一份副本**——
同一份内容存两处必然互相漂移。

本项目**不使用 GitHub Releases，仓库内也没有 tag**。版本号由三处标识：`CHANGELOG.md` 顶部的
`## vX.Y.Z` 标题、`IAS.cmd` 头部的 `iasver`（运行时显示在窗口标题与菜单）、README 页首的版本徽章——
三者由 CI 强制一致。历史版本的取法见 [`release/README.md`](../release/README.md)。

## 常见问题速查 / FAQ Quick Reference

完整 FAQ（19 条）见 [README.md#常见问题](../README.md#常见问题)，以下为高频问题跳转：

| 问题 | 跳转 |
| --- | --- |
| IDM 激活后仍提示"未注册" | [Q3](../README.md#q3) |
| 用 `[2]` 激活后弹"假序列号" | [Q13](../README.md#q13) |
| IDM 关闭更新弹窗 | [Q15](../README.md#q15) |
| Windows 11 24H2 兼容性 | [Q7](../README.md#q7) |
| 杀毒软件拦截脚本 | [Q8](../README.md#q8) |
| 浏览器扩展图标变灰 | [Q16](../README.md#q16) |
| 脚本卡在"正在初始化" | [Q12](../README.md#q12) |
| 自检通过后闪退或黑屏 | [Q17](../README.md#q17) · [Q19](../README.md#q19) |
| 过一两天又弹"试用已到期" | [Q18](../README.md#q18) |
