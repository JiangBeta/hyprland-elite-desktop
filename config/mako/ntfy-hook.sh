#!/bin/bash

# ntfy推送钩子脚本
# 过滤不需要推送的应用

APP_NAME="$1"
SUMMARY="$2"
BODY="$3"
URGENCY="$4"

# 调试日志
echo "$(date): APP_NAME=$APP_NAME, SUMMARY=$SUMMARY, BODY=$BODY, URGENCY=$URGENCY" >> /tmp/ntfy-debug.log

# 不推送的应用列表（飞书、微信等不需要推送）
EXCLUDED_APPS=(
    "feishu"
    "weixin"
    "wechat"
    "com.tencent.weixin"
    "bytedance.feishu"
    "lark"
    "volume"  # 音量调节通知
    "brightness"  # 亮度调节通知
)

# 检查是否在排除列表中
for excluded in "${EXCLUDED_APPS[@]}"; do
    if [[ "${APP_NAME,,}" =~ $excluded ]]; then
        exit 0  # 不推送
    fi
done

# 只推送重要通知（normal及以上级别）
if [[ "$URGENCY" == "low" ]]; then
    exit 0
fi

# 推送到ntfy - 从环境变量或配置文件加载
NTFY_TOPIC="${NTFY_TOPIC:-your_notify_topic}"
NTFY_URL="${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC"

# 构造消息
MESSAGE="$SUMMARY"
if [[ -n "$BODY" && "$BODY" != "$SUMMARY" ]]; then
    MESSAGE="$SUMMARY: $BODY"
fi

# 根据紧急程度设置优先级
case "$URGENCY" in
    "critical")
        PRIORITY="urgent"
        ;;
    "normal")
        PRIORITY="default"
        ;;
    *)
        PRIORITY="low"
        ;;
esac

# 发送到ntfy
curl -s \
    -H "Title: 🖥️ Arch Linux" \
    -H "Priority: $PRIORITY" \
    -H "Tags: desktop,notification" \
    -d "$MESSAGE" \
    "$NTFY_URL" &

exit 0