---
name: daily-report-skill
description: 扫描多个项目目录，收集今日 git 提交记录，自动生成工作日报。当用户说「生成日报」「今天做了什么」「daily report」时使用此 Skill。
---

# Daily Report Skill — 智能日报生成

扫描用户配置的多个项目目录，收集今日 git 提交记录，按项目和工作类型归类，生成结构化工作日报。

## 触发条件

当用户需要总结今天的工作时使用此 Skill。典型触发场景：
- 用户说「生成日报」「帮我写日报」「今天做了什么」
- 用户说「daily report」「总结一下今天的工作」

**不适用场景**：提交代码（用 commit-skill）、代码审查（用 code-review-skill）、bug 定位（用 bug-trace-skill）。

## 工作流

```
[1. 读取配置] → [2. 发现活跃仓库] → [3. 收集提交] → [4. 分析归类] → [5. 生成日报] → [6. 输出]
```

---

## 步骤 1：读取配置

读取用户 home 目录下的配置文件 `~/.daily-report.yaml`。

### 1.1 配置文件格式

```yaml
# ~/.daily-report.yaml

# 要扫描的目录（每个目录下的直接子目录为 git 仓库）
scan_dirs:
  - ~/work/frontend
  - ~/work/mobile

# git 作者邮箱（用于筛选提交，支持多个）
author_emails:
  - user@company.com

# 输出路径（可选，不填则只在聊天窗口展示）
output_dir: ~/daily-reports
```

### 1.2 处理逻辑

1. 运行 `cat ~/.daily-report.yaml` 读取配置文件
2. 解析 `scan_dirs`、`author_emails`、`output_dir` 三个字段
3. 将路径中的 `~` 展开为实际 home 目录

### 1.3 配置文件不存在

如果 `~/.daily-report.yaml` 不存在，使用 AskQuestion 工具引导用户创建：

| 需要收集的信息 | 示例 |
|--------------|------|
| 项目扫描目录（支持多个） | `~/work/frontend, ~/work/mobile` |
| git 作者邮箱 | `user@company.com` |
| 日报保存目录（可选） | `~/daily-reports` |

收集完成后，使用 Write 工具创建 `~/.daily-report.yaml`，然后继续流程。

---

## 步骤 2：发现活跃仓库

采用三层过滤策略，从快到慢逐层筛选，避免全量遍历。

### 第一层：读取活跃仓库登记文件（最快）

读取 `~/.daily-active-repos` 文件，提取今天的记录：

```bash
grep "^$(date +%Y-%m-%d)|" ~/.daily-active-repos 2>/dev/null | cut -d'|' -f2 | sort -u
```

此文件由 commit-skill 在每次提交时自动维护（格式：`日期|仓库路径`）。

### 第二层：文件系统时间戳预筛（补充扫描）

对 `scan_dirs` 下的所有仓库目录，检查 `.git/logs/HEAD` 的修改时间是否为今天：

```bash
today=$(date +%Y-%m-%d)
for dir in <scan_dir>/*/.git; do
  if [ -f "$dir/logs/HEAD" ]; then
    mod_date=$(stat -f '%Sm' -t '%Y-%m-%d' "$dir/logs/HEAD" 2>/dev/null)
    if [ "$mod_date" = "$today" ]; then
      echo "${dir%/.git}"
    fi
  fi
done
```

此步仅读取文件元数据，不启动 git 进程，50 个仓库在毫秒级完成。

### 第三层：并行 git log 验证（精确确认）

对前两层筛出的候选仓库，并行执行 git log 确认有当前用户的提交：

```bash
echo "$candidate_repos" | xargs -P 8 -I {} sh -c '
  result=$(git -C "{}" log --oneline \
    --after="'"$today"' 00:00" \
    --before="'"$tomorrow"' 00:00" \
    --author="'"$author_email"'" \
    --max-count=1 2>/dev/null)
  if [ -n "$result" ]; then
    echo "{}"
  fi
'
```

如果配置了多个 `author_emails`，用 `--author` 参数分别匹配（git log 的 `--author` 支持多次指定）。

### 合并去重

将第一层和第二、三层的结果合并去重，得到最终的活跃仓库列表。

### 无活跃仓库

如果最终列表为空，输出「今天暂无提交记录」，**终止流程**。

---

## 步骤 3：收集今天的提交

对每个活跃仓库，收集当前用户今天的所有提交详情。采用 **COMMIT-LOG 优先、git log 兜底** 策略。

### 路径 A：从 COMMIT-LOG.md 提取（优先）

1. 检查仓库根目录是否存在 `COMMIT-LOG.md`
2. 如果存在，读取文件内容
3. 按 `###` 分割为独立记录
4. 筛选条件：
   - `**日期**` 字段匹配今天的日期
   - 记录标题中的邮箱匹配 `author_emails` 中的任一邮箱
5. 提取每条记录的：type、scope、subject、改动摘要、影响范围、行为变化

### 路径 B：从 git log 降级获取

如果 `COMMIT-LOG.md` 不存在，使用 git 命令获取：

```bash
git -C <repo_path> log \
  --after="$today 00:00" --before="$tomorrow 00:00" \
  --author="$author_email" \
  --format="%h|%s|%ai" \
  --name-status
```

从每条 commit 中提取：
- **short hash**：提交哈希
- **subject**：commit message（解析 type、scope）
- **date**：提交时间
- **files**：变更文件列表及操作类型（A/M/D）

#### 是否读取 diff 生成更丰富的描述

| 仓库当日 commit 数 | 策略 |
|-------------------|------|
| ≤ 10 个 | 读取每个 commit 的 `git show <hash> --stat` 获取变更概况 |
| > 10 个 | 只用 commit message + 文件列表，不读 diff |

---

## 步骤 4：分析归类

### 4.1 按项目分组

将所有提交按仓库名分组。仓库名取目录名（如 `/Users/xxx/work/frontend/project-a` → `project-a`）。

### 4.2 按工作类型归类

根据 commit message 的 type 前缀归类：

| 日报分类 | 对应 commit type |
|---------|-----------------|
| 需求开发 | `feat` |
| Bug 修复 | `fix` |
| 代码重构 | `refactor` |
| 性能优化 | `perf` |
| 其他工作 | `docs`, `style`, `test`, `chore` 及无法识别 type 的 |

如果 commit message 不符合 Conventional Commits 格式（无 type 前缀），归入「其他工作」。

### 4.3 生成总览

统计：
- 涉及项目数
- 总提交次数
- 各类型提交数
- **一句话概括今天的主要工作**（AI 根据所有提交内容总结）

---

## 步骤 5：生成日报

### 5.1 确定详细级别

检查用户输入中是否包含以下关键词来决定级别：

| 关键词 | 级别 |
|--------|------|
| 「详细」「详细版」「详细日报」 | 详细版 |
| 默认 / 「精简」「简单」 | 精简版 |

### 5.2 精简版模板（默认）

```markdown
# 日报 — YYYY-MM-DD（周X）

## 总览
- 涉及项目：N 个
- 提交次数：N 次
- 主要工作：<一句话概括>

---

## <项目名>
### 需求开发
- <commit subject 的中文描述>
- <commit subject 的中文描述>

### Bug 修复
- <commit subject 的中文描述>

---

## <项目名>
### 其他工作
- <commit subject 的中文描述>
```

### 5.3 详细版模板

```markdown
# 日报 — YYYY-MM-DD（周X）

## 总览
- 涉及项目：N 个
- 提交次数：N 次
- 主要工作：<一句话概括>

---

## <项目名>
### 需求开发
- **<commit subject>**
  - <改动摘要或 AI 根据 diff 生成的描述>

### Bug 修复
- **<commit subject>**
  - <改动摘要或 AI 根据 diff 生成的描述>

---

## <项目名>
### 其他工作
- **<commit subject>**
  - <改动摘要或 AI 根据 diff 生成的描述>
```

### 5.4 生成规则

- 日期格式 `YYYY-MM-DD`，附带中文星期
- 「总览 → 主要工作」由 AI 根据所有提交内容生成一句话概括，突出最重要的工作
- 每个项目内，只展示有内容的分类（如没有 Bug 修复就不出现该分类）
- 如果一个项目只有一个分类，直接列出不需要分类标题
- commit subject 如果已经是中文则直接使用，如果是英文则翻译为中文

---

## 步骤 6：输出

### 6.1 聊天窗口展示

将生成的日报内容直接展示在聊天窗口中。

### 6.2 询问后续操作

使用 AskQuestion 工具询问：

| 选项 | 行为 |
|------|------|
| 看起来不错 | 结束流程 |
| 保存到文件 | 将日报写入文件，进入 6.3 |
| 复制到剪贴板 | 执行 `pbcopy` 将内容复制到系统剪贴板（macOS） |
| 需要调整 | 用户提出修改意见，修改后重新展示日报，再次询问 |

### 6.3 保存到文件

1. 确定保存路径：
   - 如果配置了 `output_dir`，使用 `<output_dir>/YYYY-MM-DD.md`
   - 如果未配置，使用当前目录 `./daily-report-YYYY-MM-DD.md`
2. 如果目录不存在，自动创建
3. 写入文件
4. 输出保存路径

---

## 参数支持

用户可在触发命令时附带参数：

| 参数 | 作用 | 示例 |
|------|------|------|
| `--date YYYY-MM-DD` | 生成指定日期的日报 | `/daily-report --date 2026-03-03` |
| `详细` / `详细版` | 使用详细版模板 | `/daily-report 详细` |
| `精简` / `简单` | 使用精简版模板（默认） | `/daily-report 精简` |

---

## 依赖说明

- 此 Skill 可独立工作（通过 git log 兜底）
- 与 commit-skill 配合时效果最佳：
  - commit-skill 维护的 `COMMIT-LOG.md` 提供更丰富的变更描述
  - commit-skill 维护的 `~/.daily-active-repos` 加速仓库发现
