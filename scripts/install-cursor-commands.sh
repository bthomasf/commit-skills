#!/usr/bin/env bash
# 将 Cursor 快捷指令（/commit、/review、/bug-trace、/daily-report）安装到当前项目的 .cursor/commands/
# 使用场景：已通过 npx openskills install bthomasf/commit-skills 安装 skills 后，本脚本可补装快捷指令

set -e

REPO_RAW="${COMMIT_SKILLS_RAW:-https://raw.githubusercontent.com/bthomasf/commit-skills/master}"
DEST="${1:-.}"
CMD_DIR="${DEST}/.cursor/commands"
FILES="commit.md review.md bug-trace.md daily-report.md"

if [[ -d "$(dirname "$0")/../commands" ]] && [[ -f "$(dirname "$0")/../commands/commit.md" ]]; then
  # 从本地 commit-skills 仓库复制（开发/克隆本仓库时）
  SRC="$(cd "$(dirname "$0")/.." && pwd)/commands"
  echo "从本地目录安装: $SRC -> $CMD_DIR"
  mkdir -p "$CMD_DIR"
  for f in $FILES; do
    cp "$SRC/$f" "$CMD_DIR/$f"
    echo "  已复制 $f"
  done
else
  # 从 GitHub 拉取（openskills 安装后在其他项目运行）
  echo "从 GitHub 安装到: $CMD_DIR"
  mkdir -p "$CMD_DIR"
  for f in $FILES; do
    curl -sSL "${REPO_RAW}/commands/${f}" -o "${CMD_DIR}/${f}"
    echo "  已下载 $f"
  done
fi

echo "完成。在 Cursor 中输入 / 即可看到 commit、review、bug-trace、daily-report。"
