---
name: /daily-report
id: daily-report
category: Git
description: 扫描多个项目，生成今日工作日报
---

生成工作日报。

**Input**: 可选参数：`详细` 使用详细版模板；`--date YYYY-MM-DD` 指定日期。不指定则默认生成今天的精简版日报。

**Steps**

1. 读取 Skill 文件 `.cursor/skills/daily-report-skill/SKILL.md`，严格按照其中定义的工作流执行
2. 按顺序完成 6 个步骤：读取配置 → 发现活跃仓库 → 收集提交 → 分析归类 → 生成日报 → 输出
3. 遇到终止条件时立即停止，不要跳过

**Guardrails**
- 必须先读取 SKILL.md 再执行，不要凭记忆操作
- 配置文件不存在时引导用户创建，不要自行编造配置
- 发现仓库时必须按三层过滤策略执行，不要全量遍历
- 日报内容需经用户确认后再保存文件
