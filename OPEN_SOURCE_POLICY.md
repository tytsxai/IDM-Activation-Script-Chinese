# 开源维护策略 / Open Source Policy

本仓库 **必须保持公开开源（public + GPL-3.0）**。它不应被改成 private，也不应被描述成闭源、私有分发或不可再分发项目。

## 固定原则

- 仓库可见性：必须是 `PUBLIC`。
- 许可证：必须保留 `GPL-3.0` 与根目录 `LICENSE`。
- 分发方式：README、Release、`llms.txt`、docs 和 Issue 模板都应按公开可审查、可复制、可再分发的开源项目来写。
- 派生作品：基于本项目二次分发时，应保留 GPL-3.0 许可证文本、版权声明和修改记录，并使用相同或兼容的 GPL 许可证。

## 不允许的变更

- 不要把仓库改成 private。
- 不要删除 `LICENSE` 或把项目改成闭源许可证。
- 不要在 README、docs、Release 或 Issue 模板中暗示本项目是私有工具、内部工具或闭源交付物。
- 不要创建不存在的运行时发布包链接，例如把文档专项版本写成新的 ZIP 产物。

## 已加的技术保障

`.github/workflows/ci.yml` 中包含 `Guard public repository visibility` 步骤。它会读取 GitHub Actions 事件里的 `repository.private` 字段：

- 如果仓库是 public，CI 继续运行。
- 如果仓库被改成 private，CI 会直接失败，并提示必须恢复 public。

这个守卫不能阻止拥有者在 GitHub 设置里手动改可见性，但能在后续 push、PR 或手动 CI 时立刻暴露问题，避免私有化状态被静默带过。

## 误改后的处理

如果发现仓库被改成 private，应立即执行：

```bash
gh repo edit tytsxai/IDM-Activation-Script-Chinese \
  --visibility public \
  --accept-visibility-change-consequences
```

恢复后检查：

```bash
gh repo view tytsxai/IDM-Activation-Script-Chinese \
  --json visibility,isArchived,description,repositoryTopics,url
```

预期结果：`visibility` 为 `PUBLIC`，`isArchived` 为 `false`，Topics 中包含 `open-source` / `gpl-3`。
