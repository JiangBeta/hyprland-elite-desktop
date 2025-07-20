#!/bin/bash

# 新版番茄计时器控制脚本
STATE_FILE="$HOME/.config/waybar/pomodoro_state.json"
CONFIG_FILE="$HOME/.config/waybar/pomodoro_config.json"

# 读取配置
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
  "work_time": 1500,
  "short_break": 300,
  "long_break": 900,
  "pomodoros_until_long_break": 4
}
EOF
    fi
    
    WORK_TIME=$(jq -r '.work_time' "$CONFIG_FILE")
    SHORT_BREAK=$(jq -r '.short_break' "$CONFIG_FILE")
    LONG_BREAK=$(jq -r '.long_break' "$CONFIG_FILE")
    POMODOROS_UNTIL_LONG=$(jq -r '.pomodoros_until_long_break' "$CONFIG_FILE")
}

# 读取状态
read_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "phase": "idle",
  "cycle": 1,
  "elapsed_time": 0,
  "total_time": 1500,
  "is_running": false,
  "last_update": 0,
  "completed_pomodoros": 0
}
EOF
    fi
    cat "$STATE_FILE"
}

# 写入状态
write_state() {
    echo "$1" > "$STATE_FILE"
}

# 获取当前时间
current_time() {
    date +%s
}

# 更新已消耗时间
update_elapsed_time() {
    local state=$(read_state)
    local is_running=$(echo "$state" | jq -r '.is_running')
    
    if [[ "$is_running" == "true" ]]; then
        local last_update=$(echo "$state" | jq -r '.last_update')
        local elapsed=$(echo "$state" | jq -r '.elapsed_time')
        local current=$(current_time)
        local new_elapsed=$((elapsed + current - last_update))
        
        state=$(echo "$state" | jq ".elapsed_time = $new_elapsed | .last_update = $current")
        write_state "$state"
    fi
}

# 开始新阶段
start_phase() {
    local phase="$1"
    local duration="$2"
    local cycle="$3"
    
    local state=$(read_state)
    state=$(echo "$state" | jq "
        .phase = \"$phase\" |
        .elapsed_time = 0 |
        .total_time = $duration |
        .is_running = true |
        .last_update = $(current_time) |
        .cycle = $cycle
    ")
    write_state "$state"
}

# 左键操作 - 开始/暂停/继续
left_click() {
    read_config
    update_elapsed_time
    
    local state=$(read_state)
    local phase=$(echo "$state" | jq -r '.phase')
    local is_running=$(echo "$state" | jq -r '.is_running')
    local cycle=$(echo "$state" | jq -r '.cycle')
    local elapsed=$(echo "$state" | jq -r '.elapsed_time')
    local total=$(echo "$state" | jq -r '.total_time')
    
    case "$phase" in
        "idle")
            # 开始第一个番茄
            start_phase "work" $WORK_TIME 1
            notify-send "🍅 番茄开始" "开始第1个番茄！专注工作25分钟" -t 3000
            ;;
        "work"|"short_break"|"long_break")
            if [[ $((total - elapsed)) -le 0 ]]; then
                # 时间已经到了，根据当前阶段决定下一步
                case "$phase" in
                    "work")
                        # 工作完成，建议休息
                        local completed=$(echo "$state" | jq -r '.completed_pomodoros')
                        if [[ $((completed % POMODOROS_UNTIL_LONG)) -eq 0 && $completed -gt 0 ]]; then
                            start_phase "long_break" $LONG_BREAK $cycle
                            notify-send "🛌 长休息" "开始长休息15分钟！" -t 3000
                        else
                            start_phase "short_break" $SHORT_BREAK $cycle
                            notify-send "☕ 短休息" "开始短休息5分钟！" -t 3000
                        fi
                        ;;
                    "short_break"|"long_break")
                        # 休息完成，开始新番茄
                        local new_cycle=$((cycle + 1))
                        start_phase "work" $WORK_TIME $new_cycle
                        notify-send "🍅 新番茄" "开始第${new_cycle}个番茄！" -t 3000
                        ;;
                esac
            else
                # 正常的暂停/继续
                if [[ "$is_running" == "true" ]]; then
                    # 暂停
                    state=$(echo "$state" | jq '.is_running = false')
                    write_state "$state"
                    notify-send "⏸ 暂停" "计时已暂停" -t 2000
                else
                    # 继续
                    state=$(echo "$state" | jq ".is_running = true | .last_update = $(current_time)")
                    write_state "$state"
                    notify-send "▶ 继续" "计时继续" -t 2000
                fi
            fi
            ;;
    esac
}

# 右键操作 - 下一阶段
right_click() {
    read_config
    update_elapsed_time
    
    local state=$(read_state)
    local phase=$(echo "$state" | jq -r '.phase')
    local cycle=$(echo "$state" | jq -r '.cycle')
    local completed=$(echo "$state" | jq -r '.completed_pomodoros')
    
    case "$phase" in
        "idle")
            # 从空闲状态，打开设置或统计
            notify-send "📊 番茄统计" "今日已完成: ${completed} 个番茄" -t 5000
            ;;
        "work")
            # 从工作切换到休息
            # 标记当前番茄为完成
            completed=$((completed + 1))
            state=$(echo "$state" | jq ".completed_pomodoros = $completed")
            write_state "$state"
            
            if [[ $((completed % POMODOROS_UNTIL_LONG)) -eq 0 ]]; then
                start_phase "long_break" $LONG_BREAK $cycle
                notify-send "🛌 长休息" "跳过工作，开始长休息15分钟！" -t 3000
            else
                start_phase "short_break" $SHORT_BREAK $cycle
                notify-send "☕ 短休息" "跳过工作，开始短休息5分钟！" -t 3000
            fi
            ;;
        "short_break"|"long_break")
            # 从休息切换到工作
            local new_cycle=$((cycle + 1))
            start_phase "work" $WORK_TIME $new_cycle
            notify-send "🍅 新番茄" "跳过休息，开始第${new_cycle}个番茄！" -t 3000
            ;;
    esac
}

# 中键操作 - 重置
middle_click() {
    local state=$(read_state)
    local completed=$(echo "$state" | jq -r '.completed_pomodoros')
    
    state=$(echo "$state" | jq "
        .phase = \"idle\" |
        .cycle = 1 |
        .elapsed_time = 0 |
        .total_time = 1500 |
        .is_running = false |
        .last_update = 0
    ")
    write_state "$state"
    
    notify-send "🔄 重置" "番茄计时器已重置\\n今日完成: ${completed} 个番茄" -t 3000
}

# 更新waybar显示
update_waybar() {
    pkill -SIGRTMIN+8 waybar 2>/dev/null || true
}

# 主逻辑
case "$1" in
    "left"|"toggle")
        left_click
        ;;
    "right"|"next")
        right_click
        ;;
    "middle"|"reset")
        middle_click
        ;;
    *)
        echo "用法: $0 {left|right|middle}"
        echo "  left   - 开始/暂停/继续"
        echo "  right  - 下一阶段"
        echo "  middle - 重置"
        exit 1
        ;;
esac

update_waybar