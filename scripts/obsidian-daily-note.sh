#!/bin/bash

# Obsidian Daily Note 创建脚本
# 正确处理日期模板，避免标题重复

# 加载环境变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# 默认配置
VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/vaults/second-brain}"
DAILY_DIR="$VAULT_PATH/10_daily"
TEMPLATE_DIR="$VAULT_PATH/_meta/templates"

# 获取今天的日期
TODAY=$(date '+%Y-%m-%d')
TODAY_FORMATTED=$(date '+%A, %B %d, %Y')
TODAY_SHORT=$(date '+%m-%d')
WEEK_NUM=$(date '+%W')
DAY_NUM=$(date '+%j')
YEAR=$(date '+%Y')
MONTH=$(date '+%Y-%m')

# 创建daily目录如果不存在
mkdir -p "$DAILY_DIR"

# 目标文件路径
DAILY_FILE="$DAILY_DIR/$TODAY.md"

# 如果文件已存在，直接打开
if [ -f "$DAILY_FILE" ]; then
    echo "今日笔记已存在，正在打开..."
    if command -v obsidian &> /dev/null; then
        obsidian "obsidian://open?vault=$(basename "$VAULT_PATH")&file=10_daily/$TODAY"
    fi
    exit 0
fi

# 创建日记内容（不使用H1标题，避免与文件名重复）
cat > "$DAILY_FILE" << EOF
---
tags: [daily]
created: $(date '+%Y-%m-%d %H:%M')
---

> $TODAY_FORMATTED

## Goals
- [ ] 
- [ ] 

## Notes

## Review
- **Done:** 
- **Tomorrow:** 

EOF

echo "已创建今日笔记: $DAILY_FILE"

# 打开Obsidian到今日笔记
if command -v obsidian &> /dev/null; then
    echo "正在打开Obsidian..."
    obsidian "obsidian://open?vault=$(basename "$VAULT_PATH")&file=10_daily/$TODAY" &
    
    # 发送桌面通知
    if command -v notify-send &> /dev/null; then
        notify-send "📝 Daily Note" "已创建并打开今日笔记\n$TODAY_FORMATTED" --icon=document-new
    fi
else
    echo "请安装Obsidian或手动打开文件: $DAILY_FILE"
fi