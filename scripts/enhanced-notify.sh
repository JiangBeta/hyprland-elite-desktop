#!/bin/bash

# 增强型通知脚本 - 支持类别和级别
# 用法: enhanced-notify.sh --category EMAIL --level normal --title "标题" --message "内容"

set -e

# 默认配置
DEFAULT_CATEGORY="General"
DEFAULT_LEVEL="normal"
DEFAULT_TIMEOUT=8000

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --category|-c)
            CATEGORY="$2"
            shift 2
            ;;
        --level|-l)
            LEVEL="$2"
            shift 2
            ;;
        --title|-t)
            TITLE="$2"
            shift 2
            ;;
        --message|-m)
            MESSAGE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --icon|-i)
            ICON="$2"
            shift 2
            ;;
        --ntfy-only)
            NTFY_ONLY="true"
            shift
            ;;
        --local-only)
            LOCAL_ONLY="true"
            shift
            ;;
        --help|-h)
            cat << 'EOF'
增强型通知脚本

用法: enhanced-notify.sh [选项] --title "标题" --message "内容"

选项:
    -c, --category CATEGORY    通知类别 (Email, Social, System, Health, Work, etc.)
    -l, --level LEVEL         通知级别 (low, normal, critical)
    -t, --title TITLE         通知标题
    -m, --message MESSAGE     通知内容
    -i, --icon ICON           图标名称
    --timeout TIMEOUT         显示时间（毫秒）
    --ntfy-only               仅发送到 ntfy
    --local-only              仅本地通知
    -h, --help                显示帮助

类别列表:
    Email, Social, System, Updates, Health, Work, Calendar,
    News, SocialMedia, Errors, Success, Finance, Weather, General

级别列表:
    low, normal, critical

示例:
    enhanced-notify.sh -c Email -l normal -t "新邮件" -m "来自老板的重要邮件"
    enhanced-notify.sh -c System -l critical -t "系统警告" -m "磁盘空间不足"

EOF
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$TITLE" ]] || [[ -z "$MESSAGE" ]]; then
    echo "错误: 必须提供 --title 和 --message 参数"
    echo "使用 --help 查看帮助"
    exit 1
fi

# 设置默认值
CATEGORY="${CATEGORY:-$DEFAULT_CATEGORY}"
LEVEL="${LEVEL:-$DEFAULT_LEVEL}"
TIMEOUT="${TIMEOUT:-$DEFAULT_TIMEOUT}"

# 类别到图标的映射
declare -A CATEGORY_ICONS=(
    ["Email"]="mail-unread"
    ["Social"]="user-available"
    ["System"]="computer"
    ["Updates"]="system-software-update"
    ["Health"]="applications-science"
    ["Work"]="applications-office"
    ["Calendar"]="office-calendar"
    ["News"]="news-feed"
    ["SocialMedia"]="internet-news-reader"
    ["Errors"]="dialog-error"
    ["Success"]="dialog-ok"
    ["Finance"]="applications-office"
    ["Weather"]="weather-clear"
    ["General"]="dialog-information"
)

# 类别到 emoji 的映射
declare -A CATEGORY_EMOJIS=(
    ["Email"]="📧"
    ["Social"]="👥"
    ["System"]="⚙️"
    ["Updates"]="🔄"
    ["Health"]="💊"
    ["Work"]="💼"
    ["Calendar"]="📅"
    ["News"]="📰"
    ["SocialMedia"]="📱"
    ["Errors"]="❌"
    ["Success"]="✅"
    ["Finance"]="💰"
    ["Weather"]="🌤️"
    ["General"]="ℹ️"
)

# 自动选择图标
if [[ -z "$ICON" ]]; then
    ICON="${CATEGORY_ICONS[$CATEGORY]:-dialog-information}"
fi

# 自动添加 emoji 前缀
EMOJI="${CATEGORY_EMOJIS[$CATEGORY]:-ℹ️}"
ENHANCED_TITLE="$EMOJI [$CATEGORY] $TITLE"

# 根据级别设置 urgency
case "$LEVEL" in
    "low")
        URGENCY="low"
        ;;
    "normal")
        URGENCY="normal"
        ;;
    "critical")
        URGENCY="critical"
        TIMEOUT=15000  # 重要通知显示时间更长
        ;;
    *)
        URGENCY="normal"
        ;;
esac

# 本地通知
if [[ "$NTFY_ONLY" != "true" ]]; then
    notify-send "$ENHANCED_TITLE" "$MESSAGE" \
        -i "$ICON" \
        -u "$URGENCY" \
        -t "$TIMEOUT"
fi

# 推送到 ntfy
if [[ "$LOCAL_ONLY" != "true" ]]; then
    # 读取 ntfy 配置
    NTFY_CONFIG="$HOME/.config/ntfy.conf"
    if [[ -f "$NTFY_CONFIG" ]]; then
        source "$NTFY_CONFIG"
    fi
    
    NTFY_TOPIC="${NTFY_TOPIC:-your_notify_topic}"
    NTFY_URL="${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC"
    
    # 设置 ntfy 优先级
    case "$LEVEL" in
        "low")
            NTFY_PRIORITY="low"
            ;;
        "normal")
            NTFY_PRIORITY="default"
            ;;
        "critical")
            NTFY_PRIORITY="urgent"
            ;;
        *)
            NTFY_PRIORITY="default"
            ;;
    esac
    
    # 发送到 ntfy
    curl -s \
        -H "Title: $ENHANCED_TITLE" \
        -H "Priority: $NTFY_PRIORITY" \
        -H "Tags: desktop,notification,$CATEGORY" \
        -H "Category: $CATEGORY" \
        -H "Level: $LEVEL" \
        -d "$MESSAGE" \
        "$NTFY_URL" &>/dev/null &
fi

# 记录到日志
LOG_FILE="$HOME/.local/share/notification-log.txt"
mkdir -p "$(dirname "$LOG_FILE")"
echo "$(date '+%Y-%m-%d %H:%M:%S') [$CATEGORY:$LEVEL] $TITLE: $MESSAGE" >> "$LOG_FILE"
