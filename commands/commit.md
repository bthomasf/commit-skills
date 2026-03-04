---
name: /commit
id: commit
category: Git
description: 智能提交代码（分析变更、生成描述、执行提交、记录日志）
---

智能提交代码。

**Steps**

1. 读取 Skill 文件 `.cursor/skills/commit-skill/SKILL.md`，严格按照其中定义的工作流执行
2. 按顺序完成 5 个步骤：变更检测 → 生成描述 → 用户确认/修改 → 执行 Commit → 写入 COMMIT-LOG.md
3. 遇到终止条件时立即停止，不要跳过

**Guardrails**
- 必须先读取 SKILL.md 再执行，不要凭记忆操作
- commit message 的 subject 不超过 12 个中文字
- COMMIT-LOG.md 记录追加到文件末尾
- 用户选择取消时立即终止，不做任何 git 操作
