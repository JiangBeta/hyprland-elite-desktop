#!/bin/bash

# 番茄计时器脚本
STATE_FILE="$HOME/.config/waybar/pomodoro_state"
CONFIG_FILE="$HOME/.config/waybar/pomodoro_config"

# 读取配置
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
WORK_TIME=1500
SHORT_BREAK=300
LONG_BREAK=900
EOF
    fi
    source "$CONFIG_FILE"
}

# 初始化状态文件
init_state() {
    echo "idle,1,0,0,false" > "$STATE_FILE"
}

# 读取状态
read_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        init_state
    fi
    cat "$STATE_FILE"
}

# 写入状态
write_state() {
    echo "$1" > "$STATE_FILE"
}

# 获取当前时间戳
current_time() {
    date +%s
}

# 计算剩余时间
get_remaining_time() {
    local state=$(read_state)
    IFS=',' read -r mode cycle start_time duration paused <<< "$state"
    
    if [[ "$paused" == "true" || "$start_time" == "0" ]]; then
        echo "$duration"
        return
    fi
    
    local current=$(current_time)
    local elapsed=$((current - start_time))
    local remaining=$((duration - elapsed))
    
    if [[ $remaining -lt 0 ]]; then
        remaining=0
    fi
    
    echo "$remaining"
}

# 格式化时间显示
format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d" "$minutes" "$secs"
}

# 发送通知
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    notify-send -u "$urgency" "$title" "$message"
}

# 番茄计时器逻辑主函数
main() {
    # 每次运行时重新读取配置
    read_config
    
    local state=$(read_state)
    IFS=',' read -r mode cycle start_time duration paused <<< "$state"
    local remaining=$(get_remaining_time)
    
    # 检查是否时间到了
    if [[ "$mode" != "idle" && $remaining -le 0 ]]; then
        case "$mode" in
            "work")
                if [[ $((cycle % 4)) -eq 0 ]]; then
                    # 第4个番茄后长休息
                    write_state "long_break,$cycle,$(current_time),$LONG_BREAK,false"
                    send_notification "🍅 番茄计时" "工作时间结束！休息15分钟" "critical"
                    ~/.config/waybar/pomodoro-alert.sh work_end &
                else
                    # 短休息
                    write_state "short_break,$cycle,$(current_time),$SHORT_BREAK,false"
                    send_notification "🍅 番茄计时" "工作时间结束！休息5分钟" "critical"
                    ~/.config/waybar/pomodoro-alert.sh work_end &
                fi
                ;;
            "short_break"|"long_break")
                # 休息结束，开始新的工作周期
                new_cycle=$((cycle + 1))
                write_state "work,$new_cycle,$(current_time),$WORK_TIME,false"
                send_notification "🍅 番茄计时" "休息结束！开始第${new_cycle}个番茄" "critical"
                ~/.config/waybar/pomodoro-alert.sh break_end &
                ;;
        esac
        state=$(read_state)
        IFS=',' read -r mode cycle start_time duration paused <<< "$state"
        remaining=$(get_remaining_time)
    fi
    
    # 生成显示内容
    local text=""
    local tooltip=""
    local class=""
    
    case "$mode" in
        "idle")
            text="🍅"
            tooltip="番茄计时器\\n点击开始工作"
            class="idle"
            ;;
        "work")
            text="🍅 $(format_time $remaining)"
            tooltip="工作中 - 第${cycle}个番茄\\n剩余: $(format_time $remaining)\\n左键: 暂停/继续\\n右键: 停止"
            class="working"
            ;;
        "short_break")
            text="☕ $(format_time $remaining)"
            tooltip="短休息\\n剩余: $(format_time $remaining)\\n左键: 暂停/继续\\n右键: 停止"
            class="break"
            ;;
        "long_break")
            text="🛌 $(format_time $remaining)"
            tooltip="长休息\\n剩余: $(format_time $remaining)\\n左键: 暂停/继续\\n右键: 停止"
            class="break"
            ;;
    esac
    
    # 输出JSON格式
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
}

main