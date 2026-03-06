---
name: commit-skill
description: 分析代码变更，生成 commit 描述，执行提交，并将变更详情记录到 COMMIT-LOG.md。当用户说「提交代码」「commit」「帮我提交」时使用此 Skill。
---

# Commit Skill — 智能代码提交

分析代码变更，生成 commit 描述（用户可修改），执行提交，并将变更详情记录到 `COMMIT-LOG.md`。

## 触发条件

当用户希望提交代码时使用此 Skill。典型触发场景：
- 用户说「提交代码」「commit」「帮我提交」
- 用户完成一组代码修改，准备入库

**不适用场景**：代码审查（用 code-review-skill）、bug 定位（用 bug-trace-skill）、仅执行 git push 不提交（请用终端）、PR 创建、合并分支。

## 工作流

```
[0. 分支检查（含配置）] → [1. 变更检测] → [2. 生成描述] → [3. 用户确认/修改（含是否 Push）] → [4. 写入 COMMIT-LOG] → [5. 统一暂存并执行 Commit] → [6. 登记活跃仓库、完成，并按步骤 3 选择执行 Push]
```

---

## 分支保护与配置文件

**默认**：不允许向 `main`、`master` 分支提交代码，以避免误操作主分支。若当前分支为受保护分支，将提示并**终止流程**。

**用户可通过配置文件覆盖**：在项目根目录（git 仓库根）添加或修改 `.commit-skill.json`：

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `protectedBranches` | `string[]` | 禁止直接提交的分支名列表。若存在则**完全替换**默认值；不配置时默认为 `["main", "master"]`。设为 `[]` 表示不保护任何分支（允许向 main/master 提交）。 |

**示例**：

```json
{
  "protectedBranches": ["main", "master", "production"]
}
```

允许向 main/master 提交（不保护任何分支）：

```json
{
  "protectedBranches": []
}
```

配置文件不存在或未设置 `protectedBranches` 时，使用默认 `["main", "master"]`。

---

## 步骤 0：分支检查

1. 运行 `git branch --show-current` 获取当前分支名。
2. 读取项目根目录的 `.commit-skill.json`（若存在），取其中的 `protectedBranches`；否则使用默认 `["main", "master"]`。
3. 若当前分支在 `protectedBranches` 列表中（分支名完全匹配），则输出以下提示并**终止流程**：

   「当前分支为 `<当前分支>`，commit-skill 默认不允许向 main/master 提交。请切换到功能分支后再提交；若确需在本分支提交，可在项目根目录添加或修改 `.commit-skill.json`，将 `protectedBranches` 设为 `[]` 或从列表中移除该分支。」

4. 通过检查则进入步骤 1。

---

## 步骤 1：变更检测（不在此步暂存）

1. 运行 `git rev-parse --is-inside-work-tree` 检查是否在 git 仓库中
   - 如果不是 git 仓库，提示用户「当前目录不是 git 仓库，请先运行 `git init` 初始化」，**终止流程**
2. 运行 `git diff --cached --stat` 检查已暂存的变更
3. 运行 `git diff --stat` 检查未暂存的变更
4. 根据结果处理：

| 场景 | 处理方式 |
|------|----------|
| 不是 git 仓库 | 提示初始化，**终止流程** |
| `git diff --cached` 非空 | 直接使用已暂存的变更，用 `git diff --cached` 获取完整 diff |
| `git diff --cached` 为空，`git diff` 非空 | **不执行 git add**，用 `git diff` 获取完整 diff（暂存留到步骤 5 与 COMMIT-LOG 一起做） |
| 两者均为空 | 输出「没有可提交的变更」，**终止流程** |

**重要**：本步骤只做检测与取 diff，不在「仅有未暂存变更」时执行 `git add -A`，以免与后续写入 COMMIT-LOG 后的统一暂存产生冲突或重复检测。

---

## 步骤 2：生成 Commit Message

分析 diff 内容，生成**一行**Conventional Commits 格式的 message，不需要 body。

**确定 type**：

| type | 场景 |
|------|------|
| `feat` | 新增功能 |
| `fix` | 修复 bug |
| `refactor` | 重构，不改功能 |
| `docs` | 仅文档变更 |
| `style` | 格式化，不影响逻辑 |
| `test` | 测试相关 |
| `perf` | 性能优化 |
| `chore` | 构建、依赖、配置 |

**确定 scope**：基于变更文件路径推断模块名（英文），多目录时用主目录或省略。

**生成格式**：

```
<type>(<scope>): <中文 subject>
```

**规则**：
- subject 使用中文，**不超过 30 个字**
- 只要一行，不需要 body（详细信息由 COMMIT-LOG.md 记录）
- 精炼概括本次变更的核心意图

---

## 步骤 3：用户确认与修改

展示 commit message 预览，**必须**使用 AskQuestion 工具提供以下**四个**选项（不可省略任一）：

| 选项 | 行为 |
|------|------|
| 确认提交 | 使用该 message 进入步骤 4，提交完成后不执行 Push |
| **确认提交并 Push** | 使用该 message 进入步骤 4，提交完成后自动执行 `git push` |
| 修改 message | 接受用户输入的新 message，使用新 message 进入步骤 4，提交完成后不执行 Push |
| 取消 | **终止流程**，保留暂存区 |

- 若用户选择「确认提交并 Push」，需在步骤 6 完成后执行 Push（见 6.3）。
- 不得将「确认提交」与「确认提交并 Push」合并为单一选项；用户必须能明确选择是否 Push。

---

## 步骤 4：写入 COMMIT-LOG.md

在提交之前，先将本条变更的详情写入项目根目录的 `COMMIT-LOG.md`，以便本次 commit 一并包含 log 文件，无需再次提交。

### 4.1 检测文件

读取项目根目录的 `COMMIT-LOG.md`：
- 不存在 → 创建文件，写入 `# Commit Log\n\n`
- 已存在 → 读取内容

### 4.2 获取本条提交信息（提交前数据）

此时尚未执行 commit，使用以下方式获取信息：

```bash
date +%Y-%m-%d                    # 日期（系统日期）
git config user.email              # 作者邮箱
# 文件变更列表：若已有暂存则用 --cached，否则用工作区 diff（此时尚未写 COMMIT-LOG，故不包含 COMMIT-LOG.md）
git diff --cached --name-status    # 若步骤 1 有已暂存变更
git diff --name-status             # 若步骤 1 仅有未暂存变更（二选一）
```

### 4.3 生成记录

格式如下（不包含 commit hash，因尚未提交）：

```markdown
### <type>(<scope>): <subject> — <author-email>
**日期**: YYYY-MM-DD

**改动摘要**: <一段话描述这次改动的目的和影响>

**影响范围**:
- `<文件路径>`: <该文件的变更说明（描述修改目的，不仅是文件名）>

**行为变化**:
- <描述用户可感知的行为变化或内部逻辑变化>
```

- 文件操作类型从上述 `git diff --cached --name-status` 或 `git diff --name-status` 判断（A=新增，M=修改，D=删除）
- 「改动摘要」描述整体目的和影响
- 「影响范围」逐文件说明修改意图
- 「行为变化」描述这次改动引入的行为/逻辑变化，帮助 bug 追溯时理解影响

### 4.4 追加到文件末尾

使用 StrReplace 或 Write 工具将记录**追加到 `COMMIT-LOG.md` 文件末尾**（不是插入顶部）。追加到末尾可以避免多人协作时的 git 合并冲突。

---

## 步骤 5：统一暂存并执行 Commit

**步骤 4 完成后禁止再次执行变更检测（步骤 1）或重新生成 message（步骤 2），直接执行下方 5.1 与 5.2。**

先写入 COMMIT-LOG.md（步骤 4）已完成，此处**一次性暂存所有变更**（代码 + COMMIT-LOG.md），再执行 commit，避免「先暂存代码、再单独 add COMMIT-LOG」导致工作区与暂存区不一致引发的冲突或重复检测。

### 5.1 统一暂存

```bash
git add .
```

将当前所有变更（含步骤 4 写入的 COMMIT-LOG.md）加入暂存区，确保本次提交包含代码与 COMMIT-LOG 的更新。

### 5.2 执行 Git Commit

```bash
git commit -m "<type>(<scope>): <subject>"
```

| 结果 | 处理 |
|------|------|
| 成功 | 运行 `git log -1 --format="%h %s"` 获取短 hash 和摘要，进入步骤 6 |
| 失败 | 展示错误信息，**终止流程** |

---

## 步骤 6：登记活跃仓库与完成

### 6.1 登记活跃仓库

将当前仓库路径追加到 `~/.daily-active-repos`，供 daily-report-skill 快速定位今日活跃仓库：

```bash
echo "$(date +%Y-%m-%d)|$(git rev-parse --show-toplevel)" >> ~/.daily-active-repos
```

此文件无需去重，daily-report-skill 读取时会自行去重。文件不存在时上述命令会自动创建。

### 6.2 完成

输出摘要（其中 short-hash 通过 `git log -1 --format="%h"` 获取）：

```
提交成功！
- Commit: <short-hash> <type>(<scope>): <subject>
- COMMIT-LOG.md 已纳入本次提交
```

### 6.3 按步骤 3 选择执行 Push

若用户在步骤 3 选择了「确认提交并 Push」，则执行：

```bash
git push
```

- 推送当前分支到已配置的上游（一般为 `origin` 当前分支）。
- 若未配置上游，可执行 `git push -u origin $(git branch --show-current)`；若仍失败则展示错误信息并结束。

| 结果 | 处理 |
|------|------|
| 成功 | 输出「Push 成功」，结束流程 |
| 失败 | 展示错误信息，结束流程 |

若用户在步骤 3 未选择「确认提交并 Push」，则直接结束流程。
