# Commit Skills

一套 Cursor Agent Skills，帮你自动化代码提交、审查、Bug 追溯和日报生成。

## 包含的 Skills

| Skill | 功能 | 触发方式 |
|-------|------|----------|
| **commit-skill** | 分析变更 → 生成描述（≤30字） → 先写 COMMIT-LOG → 再提交（log 随本次提交）→ 可选一键 Push | `/commit` 或 「帮我提交代码」 |
| **code-review-skill** | 检测逻辑错误和无用代码，生成报告并提供修复方案 | `/review` 或 「帮我审查代码」 |
| **bug-trace-skill** | 搜索 COMMIT-LOG.md 定位可疑变更，分析代码并提供修复建议 | `/bug-trace` 或 「帮我查一下这个 bug」 |
| **daily-report-skill** | 扫描多个项目目录，收集今日提交，自动生成工作日报 | `/daily-report` 或 「帮我生成日报」 |

## 安装

### 1. 安装 Skills

# 安装到当前项目
npx openskills install bthomasf/commit-skills

# 或安装到全局
npx openskills install bthomasf/commit-skills --global
