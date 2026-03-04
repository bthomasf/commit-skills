# Commit Skills

一套 Cursor Agent Skills，帮你自动化代码提交、审查、Bug 追溯和日报生成。

## 包含的 Skills

| Skill | 功能 | 触发方式 |
|-------|------|----------|
| **commit-skill** | 分析变更 → 生成描述（≤30字） → 先写 COMMIT-LOG → 再提交（log 随本次提交）→ 可选一键 Push | `/commit` 或 「帮我提交代码」 |
| **code-review-skill** | 检测逻辑错误和无用代码，生成报告并提供修复方案 | `/review` 或 「帮我审查代码」 |
| **bug-trace-skill** | 搜索 COMMIT-LOG.md 定位可疑变更，分析代码并提供修复建议 | `/bug-trace` 或 「帮我查一下这个 bug」 |
| **daily-report-skill** | 扫描多个项目目录，收集今日提交，自动生成工作日报 | `/daily-report` 或 「帮我生成日报」 |

## 快捷指令配置

用以下任一方式即可在 Cursor 里使用 `/commit`、`/review`、`/bug-trace`、`/daily-report`，**选一种即可**。

### 方式一：在本仓库使用（零配置）

直接打开或克隆本仓库作为工作区，快捷指令已放在 `.cursor/commands/` 下，无需额外配置：

- 在 Cursor 输入框输入 `/`，即可看到 **commit**、**review**、**bug-trace**、**daily-report**
- 选择对应指令并回车即可执行

### 方式二：安装到其他项目

**说明**：`npx openskills install` 只会安装 Skills（SKILL.md），**不会**安装 Cursor 的快捷指令（`.cursor/commands/`）。因此需要两步：

**步骤 1**：安装 Skills

```bash
# 安装到当前项目（仅当前仓库生效）
npx openskills install bthomasf/commit-skills

# 或安装到全局（所有项目可用）
npx openskills install bthomasf/commit-skills --global
```

**步骤 2**：补装快捷指令（在要使用 `/commit` 等指令的项目根目录执行）

```bash
# 一键安装：从 GitHub 下载 4 个 command 到当前项目的 .cursor/commands/
curl -sSL https://raw.githubusercontent.com/bthomasf/commit-skills/master/scripts/install-cursor-commands.sh | bash
```

若已克隆本仓库，也可在仓库内执行脚本并指定目标项目路径：

```bash
./scripts/install-cursor-commands.sh /path/to/your/project
```

完成后，在该项目（或全局）中即可使用 `/commit`、`/review`、`/bug-trace`、`/daily-report`。

### 方式三：为常用指令绑定快捷键（可选）

若希望用键盘快捷键触发某个指令：

1. 打开 Cursor：**Cmd + Shift + P**（Mac）或 **Ctrl + Shift + P**（Windows/Linux）
2. 输入 `Preferences: Open Keyboard Shortcuts (JSON)`
3. 在 `keybindings.json` 中为对应 command 添加快捷键（具体 command 名可在「键盘快捷方式」界面搜索「chat」或「command」查看）

---

## 安装（Skills 本体）

通过 openskills 安装时，仅会安装 Skills；快捷指令需按上文「方式二」再执行一步。

```bash
# 安装到当前项目
npx openskills install bthomasf/commit-skills

# 或安装到全局
npx openskills install bthomasf/commit-skills --global

# 然后在该项目根目录补装快捷指令
curl -sSL https://raw.githubusercontent.com/bthomasf/commit-skills/master/scripts/install-cursor-commands.sh | bash
```
