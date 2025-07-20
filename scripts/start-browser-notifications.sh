#!/bin/bash

# 启动浏览器通知桥接服务
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPE="/tmp/browser-notifications.pipe"
PID_FILE="/tmp/browser-notification-bridge.pid"

# 创建命名管道
if [[ ! -p "$PIPE" ]]; then
    mkfifo "$PIPE"
fi

# 检查是否已在运行
if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "⚠️  浏览器通知桥接服务已在运行 (PID: $(cat $PID_FILE))"
    exit 1
fi

echo "🚀 启动浏览器通知桥接服务..."

# 后台运行监听进程
{
    while true; do
        if read -r line < "$PIPE"; then
            if [[ -n "$line" ]]; then
                # 解析格式: source|title|message|urgency
                IFS='|' read -r source title message urgency <<< "$line"
                
                # 记录到日志
                echo "$(date '+%Y-%m-%d %H:%M:%S') - $source: $title - $message" >> "$HOME/.local/share/browser-notifications.log"
                
                # 发送系统通知
                case "$source" in
                    *claude*|*anthropic*)
                        "$SCRIPT_DIR/enhanced-notify.sh" \
                            -c AI -l "${urgency:-normal}" \
                            -t "🤖 Claude" \
                            -m "$title\n\n$message" \
                            --timeout 12000
                        ;;
                    *github*)
                        "$SCRIPT_DIR/enhanced-notify.sh" \
                            -c Development -l "${urgency:-normal}" \
                            -t "🐙 GitHub" \
                            -m "$title\n\n$message" \
                            --timeout 10000
                        ;;
                    *)
                        "$SCRIPT_DIR/enhanced-notify.sh" \
                            -c Web -l "${urgency:-normal}" \
                            -t "🌐 $source" \
                            -m "$title\n\n$message" \
                            --timeout 8000
                        ;;
                esac
            fi
        fi
    done
} &

# 记录PID
echo $! > "$PID_FILE"

echo "✅ 浏览器通知桥接服务已启动 (PID: $(cat $PID_FILE))"
echo "📡 监听管道: $PIPE"
echo ""
echo "💡 测试命令:"
echo "   echo 'claude.ai|需要确认|请确认操作|urgent' > $PIPE"
echo "   echo 'github.com|新PR|有新的合并请求|normal' > $PIPE"

# 发送启动通知
"$SCRIPT_DIR/enhanced-notify.sh" \
    -c System -l low \
    -t "🔔 通知桥接" \
    -m "浏览器通知桥接服务已启动\n\n现在可以接收网页通知了" \
    --timeout 5000
