---
name: /review
id: review
category: Git
description: 代码审查（检测逻辑错误和无用代码）
---

审查代码质量。

**Input**: 可选参数为指定审查的文件或目录路径。不指定则默认审查 git diff 变更。

**Steps**

1. 读取 Skill 文件 `.cursor/skills/code-review-skill/SKILL.md`，严格按照其中定义的工作流执行
2. 确定审查范围（默认 git diff 或用户指定的文件/目录）
3. 按顺序完成：过滤文件 → 逻辑错误检测 → 无用代码检测 → 生成报告 → 提供修复方案

**Guardrails**
- 必须先读取 SKILL.md 再执行
- 跳过 lock 文件、编译产物等自动生成文件
- 修复方案需经用户确认才能应用
