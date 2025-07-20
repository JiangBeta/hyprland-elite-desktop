#!/bin/bash

# 番茄计时器控制脚本
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

# 读取配置
read_config

# 获取当前时间戳
current_time() {
    date +%s
}

# 读取状态
read_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "idle,1,0,0,false" > "$STATE_FILE"
    fi
    cat "$STATE_FILE"
}

# 写入状态
write_state() {
    echo "$1" > "$STATE_FILE"
}

# 开始/暂停/继续
toggle() {
    local state=$(read_state)
    IFS=',' read -r mode cycle start_time duration paused <<< "$state"
    
    if [[ "$mode" == "idle" ]]; then
        # 开始第一个番茄
        write_state "work,1,$(current_time),$WORK_TIME,false"
        notify-send "🍅 番茄计时" "开始第1个番茄！专注工作25分钟"
    elif [[ "$paused" == "true" ]]; then
        # 继续
        new_start_time=$(current_time)
        write_state "$mode,$cycle,$new_start_time,$duration,false"
        notify-send "🍅 番茄计时" "继续计时"
    else
        # 暂停
        current=$(current_time)
        elapsed=$((current - start_time))
        remaining=$((duration - elapsed))
        write_state "$mode,$cycle,0,$remaining,true"
        notify-send "🍅 番茄计时" "已暂停"
    fi
    
    # 更新waybar
    pkill -SIGRTMIN+8 waybar
}

# 停止/重置
stop() {
    write_state "idle,1,0,0,false"
    notify-send "🍅 番茄计时" "已停止"
    pkill -SIGRTMIN+8 waybar
}

# 跳过当前阶段
skip() {
    local state=$(read_state)
    IFS=',' read -r mode cycle start_time duration paused <<< "$state"
    
    case "$mode" in
        "work")
            if [[ $((cycle % 4)) -eq 0 ]]; then
                write_state "long_break,$cycle,$(current_time),$LONG_BREAK,false"
                notify-send "🍅 番茄计时" "跳过工作时间，开始长休息"
            else
                write_state "short_break,$cycle,$(current_time),$SHORT_BREAK,false"
                notify-send "🍅 番茄计时" "跳过工作时间，开始短休息"
            fi
            ;;
        "short_break"|"long_break")
            new_cycle=$((cycle + 1))
            write_state "work,$new_cycle,$(current_time),$WORK_TIME,false"
            notify-send "🍅 番茄计时" "跳过休息时间，开始第${new_cycle}个番茄"
            ;;
        *)
            echo "当前处于空闲状态，无法跳过"
            exit 0
            ;;
    esac
    
    pkill -SIGRTMIN+8 waybar
}

case "$1" in
    "toggle")
        toggle
        ;;
    "stop")
        stop
        ;;
    "skip")
        skip
        ;;
    *)
        echo "用法: $0 {toggle|stop|skip}"
        echo "  toggle - 开始/暂停/继续"
        echo "  stop   - 停止/重置"
        echo "  skip   - 跳过当前阶段"
        exit 1
        ;;
esac