#!/bin/bash

# 新版番茄计时器 - 更直观的交互和正确的逻辑
STATE_FILE="$HOME/.config/waybar/pomodoro_state.json"
CONFIG_FILE="$HOME/.config/waybar/pomodoro_config.json"

# 默认配置
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "work_time": 1500,
  "short_break": 300,
  "long_break": 900,
  "pomodoros_until_long_break": 4
}
EOF
}

# 默认状态
create_default_state() {
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
}

# 读取配置
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    WORK_TIME=$(jq -r '.work_time' "$CONFIG_FILE")
    SHORT_BREAK=$(jq -r '.short_break' "$CONFIG_FILE")
    LONG_BREAK=$(jq -r '.long_break' "$CONFIG_FILE")
    POMODOROS_UNTIL_LONG=$(jq -r '.pomodoros_until_long_break' "$CONFIG_FILE")
}

# 读取状态
read_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        create_default_state
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

# 获取剩余时间
get_remaining_time() {
    local state=$(read_state)
    local total=$(echo "$state" | jq -r '.total_time')
    local elapsed=$(echo "$state" | jq -r '.elapsed_time')
    local remaining=$((total - elapsed))
    
    if [[ $remaining -lt 0 ]]; then
        remaining=0
    fi
    
    echo $remaining
}

# 格式化时间
format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d" "$minutes" "$secs"
}

# 检查是否时间到了
check_time_up() {
    local remaining=$(get_remaining_time)
    local state=$(read_state)
    local phase=$(echo "$state" | jq -r '.phase')
    
    if [[ $remaining -le 0 && "$phase" != "idle" ]]; then
        # 时间到了，暂停计时并发送通知
        state=$(echo "$state" | jq '.is_running = false')
        write_state "$state"
        
        case "$phase" in
            "work")
                local completed=$(echo "$state" | jq -r '.completed_pomodoros')
                completed=$((completed + 1))
                state=$(echo "$state" | jq ".completed_pomodoros = $completed")
                write_state "$state"
                
                notify-send "🍅 番茄完成" "恭喜！完成第${completed}个番茄\\n\\n左键: 开始休息\\n右键: 继续工作" -u normal -t 10000
                ;;
            "short_break"|"long_break")
                notify-send "😴 休息结束" "休息时间结束\\n\\n左键: 开始工作\\n右键: 继续休息" -u normal -t 10000
                ;;
        esac
        
        return 0
    fi
    return 1
}

# 生成显示内容
generate_output() {
    read_config
    update_elapsed_time
    check_time_up
    
    local state=$(read_state)
    local phase=$(echo "$state" | jq -r '.phase')
    local cycle=$(echo "$state" | jq -r '.cycle')
    local is_running=$(echo "$state" | jq -r '.is_running')
    local completed=$(echo "$state" | jq -r '.completed_pomodoros')
    local remaining=$(get_remaining_time)
    
    local text=""
    local tooltip=""
    local class=""
    
    case "$phase" in
        "idle")
            text="🍅 开始"
            tooltip="番茄计时器\\n已完成: ${completed} 个番茄\\n\\n左键: 开始工作\\n右键: 设置"
            class="idle"
            ;;
        "work")
            if [[ "$is_running" == "true" ]]; then
                text="🍅 $(format_time $remaining)"
                tooltip="工作中 - 第${cycle}个番茄\\n剩余: $(format_time $remaining)\\n已完成: ${completed} 个\\n\\n左键: 暂停\\n右键: 开始休息\\n中键: 重置"
                class="working"
            else
                if [[ $remaining -le 0 ]]; then
                    text="🍅 ✅"
                    tooltip="工作完成！\\n已完成: $((completed)) 个番茄\\n\\n左键: 开始休息\\n右键: 继续工作"
                    class="completed"
                else
                    text="🍅 ⏸ $(format_time $remaining)"
                    tooltip="工作暂停\\n剩余: $(format_time $remaining)\\n\\n左键: 继续\\n右键: 开始休息\\n中键: 重置"
                    class="paused"
                fi
            fi
            ;;
        "short_break")
            if [[ "$is_running" == "true" ]]; then
                text="☕ $(format_time $remaining)"
                tooltip="短休息\\n剩余: $(format_time $remaining)\\n\\n左键: 暂停\\n右键: 开始工作\\n中键: 重置"
                class="break"
            else
                if [[ $remaining -le 0 ]]; then
                    text="☕ ✅"
                    tooltip="休息结束！\\n\\n左键: 开始工作\\n右键: 继续休息"
                    class="completed"
                else
                    text="☕ ⏸ $(format_time $remaining)"
                    tooltip="休息暂停\\n剩余: $(format_time $remaining)\\n\\n左键: 继续\\n右键: 开始工作\\n中键: 重置"
                    class="paused"
                fi
            fi
            ;;
        "long_break")
            if [[ "$is_running" == "true" ]]; then
                text="🛌 $(format_time $remaining)"
                tooltip="长休息\\n剩余: $(format_time $remaining)\\n\\n左键: 暂停\\n右键: 开始工作\\n中键: 重置"
                class="break"
            else
                if [[ $remaining -le 0 ]]; then
                    text="🛌 ✅"
                    tooltip="长休息结束！\\n\\n左键: 开始工作\\n右键: 继续休息"
                    class="completed"
                else
                    text="🛌 ⏸ $(format_time $remaining)"
                    tooltip="长休息暂停\\n剩余: $(format_time $remaining)\\n\\n左键: 继续\\n右键: 开始工作\\n中键: 重置"
                    class="paused"
                fi
            fi
            ;;
    esac
    
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
}

# 执行主逻辑
generate_output