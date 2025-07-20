#!/bin/bash

# 停止浏览器通知桥接服务
PID_FILE="/tmp/browser-notification-bridge.pid"

if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    PID=$(cat "$PID_FILE")
    kill "$PID"
    rm -f "$PID_FILE"
    echo "⏹️  浏览器通知桥接服务已停止 (PID: $PID)"
    
    # 发送停止通知
    notify-send "🔔 通知桥接" "浏览器通知桥接服务已停止" -i dialog-information -u low -t 3000
else
    echo "⚠️  浏览器通知桥接服务未运行"
fi
