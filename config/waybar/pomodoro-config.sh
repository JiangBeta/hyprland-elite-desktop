#!/bin/bash

# 番茄计时器配置脚本
CONFIG_FILE="$HOME/.config/waybar/pomodoro_config"

# 默认配置
DEFAULT_WORK_TIME=1500     # 25分钟
DEFAULT_SHORT_BREAK=300    # 5分钟  
DEFAULT_LONG_BREAK=900     # 15分钟

# 初始化配置文件
init_config() {
    cat > "$CONFIG_FILE" << EOF
WORK_TIME=$DEFAULT_WORK_TIME
SHORT_BREAK=$DEFAULT_SHORT_BREAK
LONG_BREAK=$DEFAULT_LONG_BREAK
EOF
}

# 读取配置
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config
    fi
    source "$CONFIG_FILE"
}

# 写入配置
write_config() {
    cat > "$CONFIG_FILE" << EOF
WORK_TIME=$1
SHORT_BREAK=$2
LONG_BREAK=$3
EOF
}

# 调整工作时间
adjust_work_time() {
    read_config
    local direction="$1"  # up 或 down
    local step=60         # 1分钟步长
    
    case "$direction" in
        "up")
            WORK_TIME=$((WORK_TIME + step))
            if [[ $WORK_TIME -gt 3600 ]]; then  # 最大60分钟
                WORK_TIME=3600
            fi
            ;;
        "down")
            WORK_TIME=$((WORK_TIME - step))
            if [[ $WORK_TIME -lt 600 ]]; then   # 最小10分钟
                WORK_TIME=600
            fi
            ;;
    esac
    
    write_config "$WORK_TIME" "$SHORT_BREAK" "$LONG_BREAK"
    
    # 格式化时间显示
    local minutes=$((WORK_TIME / 60))
    local status_msg="工作时间调整为: ${minutes}分钟"
    
    # 检查当前状态并添加额外信息
    local STATE_FILE="$HOME/.config/waybar/pomodoro_state"
    if [[ -f "$STATE_FILE" ]]; then
        local state=$(cat "$STATE_FILE")
        IFS=',' read -r mode cycle start_time duration paused <<< "$state"
        if [[ "$mode" == "work" ]]; then
            status_msg="$status_msg\n当前工作周期已同步更新"
        fi
    fi
    
    notify-send "🍅 番茄计时器" "$status_msg" -t 3000
    
    # 如果当前正在工作状态，需要更新当前计时器的持续时间
    local STATE_FILE="$HOME/.config/waybar/pomodoro_state"
    if [[ -f "$STATE_FILE" ]]; then
        local state=$(cat "$STATE_FILE")
        IFS=',' read -r mode cycle start_time duration paused <<< "$state"
        
        # 只在工作模式下更新持续时间
        if [[ "$mode" == "work" ]]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            local new_duration="$WORK_TIME"
            
            # 如果新时间小于已经过去的时间，立即结束
            if [[ $new_duration -le $elapsed ]]; then
                new_duration=$elapsed
            fi
            
            echo "$mode,$cycle,$start_time,$new_duration,$paused" > "$STATE_FILE"
        fi
    fi
    
    # 更新waybar
    pkill -SIGRTMIN+8 waybar
}

# 重置为默认值
reset_config() {
    write_config "$DEFAULT_WORK_TIME" "$DEFAULT_SHORT_BREAK" "$DEFAULT_LONG_BREAK"
    notify-send "🍅 番茄计时器" "已重置为默认配置: 25/5/15分钟" -t 2000
    pkill -SIGRTMIN+8 waybar
}

case "$1" in
    "up")
        adjust_work_time "up"
        ;;
    "down")
        adjust_work_time "down"
        ;;
    "reset")
        reset_config
        ;;
    *)
        echo "用法: $0 {up|down|reset}"
        echo "  up    - 增加工作时间（+1分钟）"
        echo "  down  - 减少工作时间（-1分钟）"
        echo "  reset - 重置为默认配置"
        exit 1
        ;;
esac