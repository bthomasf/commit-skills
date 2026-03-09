---
name: /commit
id: commit
category: Git
description: 智能提交代码（分析变更、生成描述、执行提交、记录日志）
---

智能提交代码。

**Steps**

1. 读取 Skill 文件 `commit-skill/SKILL.md`（若不存在则读 `.cursor/skills/commit-skill/SKILL.md`），严格按照其中定义的工作流执行
2. 按顺序完成 7 步：**步骤 0 分支检查（必须最先执行）** → 变更检测 → 生成描述 → 用户确认/修改（含是否 Push）→ 写入 COMMIT-LOG.md → 统一暂存并执行 Commit → 登记活跃仓库与完成（按选择执行 Push）
3. 遇到终止条件时立即停止，不要跳过

**Guardrails**
- 必须先读取 SKILL.md 再执行，不要凭记忆操作
- **步骤 3 的 AskQuestion 必须提供四个选项**：确认提交、确认提交并 Push、修改 message、取消（不可只提供三个或合并「确认提交」与「确认提交并 Push」）
- commit message 的 subject 不超过 30 个中文字
- COMMIT-LOG.md 在提交前写入并随本次 commit 一并提交，无需再次提交
- **步骤 0 不可跳过**：当前分支为 main 或 master 时，**必须**立即终止，不执行任何 git add/commit 操作；用户可通过项目根目录 `.commit-skill.json` 的 `protectedBranches` 覆盖
- 用户选择取消时立即终止，不做任何 git 操作
