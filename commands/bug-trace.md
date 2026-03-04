---
name: /bug-trace
id: bug-trace
category: Git
description: Bug 追溯定位（搜索变更日志、分析代码、提供修复建议）
---

根据 bug 描述定位问题并提供修复建议。

**Input**: bug 现象描述。例如 `/bug-trace 登录页面点击提交后白屏`

**Steps**

1. 读取 Skill 文件 `.cursor/skills/bug-trace-skill/SKILL.md`，严格按照其中定义的工作流执行
2. 从用户描述中提取关键词
3. 按顺序完成：搜索 COMMIT-LOG.md → 展示可疑记录 → 代码分析 → 输出修复建议

**Guardrails**
- 必须先读取 SKILL.md 再执行
- 如果 COMMIT-LOG.md 不存在，降级使用 git log 排查
- 修复方案需经用户确认才能应用
