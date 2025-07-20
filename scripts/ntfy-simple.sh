#!/bin/bash

# 简单的ntfy推送脚本
# 用法: ntfy-simple.sh "标题" "内容"

TITLE="$1"
CONTENT="$2"
NTFY_TOPIC="${NTFY_TOPIC:-your_notify_topic}"
NTFY_URL="${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC"

# 构造消息
if [[ -n "$CONTENT" && "$CONTENT" != "$TITLE" ]]; then
    MESSAGE="$TITLE: $CONTENT"
else
    MESSAGE="$TITLE"
fi

# 推送到ntfy
curl -s \
    -H "Title: 🖥️ Desktop" \
    -H "Priority: default" \
    -H "Tags: desktop" \
    -d "$MESSAGE" \
    "$NTFY_URL"

echo "推送完成: $MESSAGE"