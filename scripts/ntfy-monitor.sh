#!/bin/bash

# ntfy监听器 - 监听dbus通知并推送到手机
# 这个脚本会在后台运行，监听所有通知

NTFY_TOPIC="${NTFY_TOPIC:-your_notify_topic}"
NTFY_URL="${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC"

# 不推送的应用列表
EXCLUDED_APPS=(
    "feishu"
    "weixin" 
    "wechat"
    "com.tencent.weixin"
    "bytedance.feishu"
    "lark"
    "volume"
    "brightness"
)

is_excluded() {
    local app_name="$1"
    for excluded in "${EXCLUDED_APPS[@]}"; do
        if [[ "${app_name,,}" =~ $excluded ]]; then
            return 0
        fi
    done
    return 1
}

# 监听D-Bus通知
dbus-monitor --session "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null | 
while read -r line; do
    if [[ $line =~ string ]]; then
        # 解析通知内容
        if [[ $line =~ \"([^\"]+)\" ]]; then
            content="${BASH_REMATCH[1]}"
            
            # 简单的状态机来解析通知参数
            case "$content" in
                *"kitty"*|*"notify-send"*)
                    # 收集后续的summary和body
                    read -r summary_line
                    read -r body_line
                    
                    if [[ $summary_line =~ \"([^\"]+)\" ]]; then
                        summary="${BASH_REMATCH[1]}"
                    fi
                    
                    if [[ $body_line =~ \"([^\"]+)\" ]]; then
                        body="${BASH_REMATCH[1]}"
                    fi
                    
                    # 检查是否排除
                    if ! is_excluded "$content"; then
                        # 构造消息
                        message="$summary"
                        if [[ -n "$body" && "$body" != "$summary" ]]; then
                            message="$summary: $body"
                        fi
                        
                        # 推送到ntfy
                        curl -s \
                            -H "Title: 🖥️ Arch Linux" \
                            -H "Priority: default" \
                            -H "Tags: desktop,notification" \
                            -d "$message" \
                            "$NTFY_URL" &
                    fi
                    ;;
            esac
        fi
    fi
done