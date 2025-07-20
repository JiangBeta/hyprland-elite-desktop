#!/bin/bash

# notify-send包装器，同时推送到ntfy
# 替换系统的notify-send命令

# 解析参数
SUMMARY=""
BODY=""
URGENCY="normal"

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--urgency)
            URGENCY="$2"
            shift 2
            ;;
        -t|--expire-time)
            # 忽略过期时间参数
            shift 2
            ;;
        -i|--icon)
            # 忽略图标参数
            shift 2
            ;;
        -*)
            # 忽略其他选项
            shift
            ;;
        *)
            if [[ -z "$SUMMARY" ]]; then
                SUMMARY="$1"
            else
                BODY="$1"
            fi
            shift
            ;;
    esac
done

# 发送本地通知
/usr/bin/notify-send "$SUMMARY" "$BODY"

# 不推送的应用（通过进程名判断）
CURRENT_APP=$(ps -o comm= -p $PPID 2>/dev/null || echo "unknown")

EXCLUDED_APPS=(
    "feishu"
    "weixin" 
    "wechat"
    "volume"
    "brightness"
)

# 检查是否排除
for excluded in "${EXCLUDED_APPS[@]}"; do
    if [[ "${CURRENT_APP,,}" =~ $excluded ]]; then
        exit 0
    fi
done

# 只推送normal及以上级别的通知
if [[ "$URGENCY" == "low" ]]; then
    exit 0
fi

# 推送到ntfy - 从环境变量或配置文件加载
NTFY_TOPIC="${NTFY_TOPIC:-your_notify_topic}"
NTFY_URL="${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC"

MESSAGE="$SUMMARY"
if [[ -n "$BODY" && "$BODY" != "$SUMMARY" ]]; then
    MESSAGE="$SUMMARY: $BODY"
fi

curl -s \
    -H "Title: 🖥️ Desktop" \
    -H "Priority: default" \
    -H "Tags: desktop" \
    -d "$MESSAGE" \
    "$NTFY_URL" &