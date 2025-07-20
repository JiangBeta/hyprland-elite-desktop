#!/bin/bash

# 定期提醒通知脚本
# 提供健康提醒、工作提醒等功能

REMINDERS_CONFIG="$HOME/.config/periodic-reminders.conf"

# 默认配置
BREAK_INTERVAL=30     # 休息提醒间隔（分钟）
WATER_INTERVAL=60     # 喝水提醒间隔（分钟）
EYE_INTERVAL=20       # 护眼提醒间隔（分钟）
POSTURE_INTERVAL=45   # 坐姿提醒间隔（分钟）

# 读取配置文件
if [[ -f "$REMINDERS_CONFIG" ]]; then
    source "$REMINDERS_CONFIG"
else
    # 创建默认配置文件
    cat > "$REMINDERS_CONFIG" << 'EOF'
# 定期提醒配置文件

# 休息提醒间隔（分钟）
BREAK_INTERVAL=30

# 喝水提醒间隔（分钟）
WATER_INTERVAL=60

# 护眼提醒间隔（分钟）- 20-20-20 法则
EYE_INTERVAL=20

# 坐姿提醒间隔（分钟）
POSTURE_INTERVAL=45

# 启用的提醒类型
ENABLE_BREAK_REMINDER=true
ENABLE_WATER_REMINDER=true
ENABLE_EYE_REMINDER=true
ENABLE_POSTURE_REMINDER=true
ENABLE_TIME_REMINDER=true
EOF
    echo "创建了默认配置文件: $REMINDERS_CONFIG"
fi

# 休息提醒
break_reminder() {
    local messages=(
        "💻 该休息一下了！\n离开电脑，活动筋骨，放松一下"
        "🚶‍♂️ 起来走动走动\n长时间坐着对健康不好"
        "🧘‍♀️ 深呼吸，放松心情\n工作效率会更高"
        "🌱 看看远方的绿色植物\n让眼睛得到休息"
        "☕ 喝杯茶或咖啡\n补充水分，恢复精神"
    )
    
    local random_index=$((RANDOM % ${#messages[@]}))
    $HOME/dotfiles/scripts/enhanced-notify.sh -c Health -l normal -t "休息提醒" -m "${messages[$random_index]}" --timeout 10000
}

# 喝水提醒
water_reminder() {
    local messages=(
        "💧 该喝水了！\n保持身体水分充足"
        "🥤 补充水分\n建议每天喝8杯水"
        "💦 喝口水吧\n大脑需要充足的水分"
        "🌊 水是生命之源\n不要等到渴了才喝"
        "💧 定时喝水很重要\n有助于新陈代谢"
    )
    
    local random_index=$((RANDOM % ${#messages[@]}))
    $HOME/dotfiles/scripts/enhanced-notify.sh -c Health -l normal -t "喝水提醒" -m "${messages[$random_index]}" --timeout 8000
}

# 护眼提醒（20-20-20法则）
eye_reminder() {
    $HOME/dotfiles/scripts/enhanced-notify.sh -c Health -l normal -t "护眼提醒" -m "20-20-20 法则：\n看向20英尺外的物体\n持续20秒钟" --timeout 12000
}

# 坐姿提醒
posture_reminder() {
    local messages=(
        "🪑 检查你的坐姿\n保持背部挺直，双脚平放"
        "📐 调整显示器高度\n视线应平视屏幕上端"
        "💺 椅子高度合适吗？\n大腿应与地面平行"
        "🖱️ 鼠标和键盘位置\n手腕应保持自然状态"
    )
    
    local random_index=$((RANDOM % ${#messages[@]}))
    $HOME/dotfiles/scripts/enhanced-notify.sh -c Health -l normal -t "坐姿提醒" -m "${messages[$random_index]}" --timeout 10000
}

# 时间提醒
time_reminder() {
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local current_time=$(date +"%H:%M")
    
    # 整点提醒
    if [[ "$current_minute" == "00" ]]; then
        case $current_hour in
            09) notify-send "⏰ 早安提醒" "新的一天开始了！\n当前时间: $current_time" -i dialog-information -u normal -t 5000 ;;
            12) notify-send "🍽️ 午餐时间" "该吃午饭了！\n当前时间: $current_time" -i dialog-information -u normal -t 5000 ;;
            18) notify-send "🌅 下班时间" "工作辛苦了！\n当前时间: $current_time" -i dialog-information -u normal -t 5000 ;;
            22) notify-send "🌙 晚安提醒" "该准备休息了\n当前时间: $current_time" -i dialog-information -u normal -t 5000 ;;
            *) 
                if [[ $current_hour -ge 6 && $current_hour -le 22 ]]; then
                    notify-send "⏰ 时间提醒" "当前时间: $current_time" -i chronometer -u low -t 3000
                fi
                ;;
        esac
    fi
}

# 启动定期提醒守护进程
start_reminders() {
    echo "🔔 启动定期提醒服务..."
    
    # 创建PID文件目录
    local pid_dir="$HOME/.local/run"
    mkdir -p "$pid_dir"
    local pid_file="$pid_dir/periodic-reminders.pid"
    
    # 检查是否已在运行
    if [[ -f "$pid_file" ]] && kill -0 $(cat "$pid_file") 2>/dev/null; then
        echo "⚠️ 提醒服务已在运行 (PID: $(cat $pid_file))"
        return 1
    fi
    
    # 后台运行提醒服务
    (
        while true; do
            # 读取最新配置
            source "$REMINDERS_CONFIG" 2>/dev/null || true
            
            # 检查并发送各种提醒
            if [[ "${ENABLE_BREAK_REMINDER:-true}" == "true" ]]; then
                sleep $((BREAK_INTERVAL * 60)) && break_reminder &
            fi
            
            if [[ "${ENABLE_WATER_REMINDER:-true}" == "true" ]]; then
                sleep $((WATER_INTERVAL * 60)) && water_reminder &
            fi
            
            if [[ "${ENABLE_EYE_REMINDER:-true}" == "true" ]]; then
                sleep $((EYE_INTERVAL * 60)) && eye_reminder &
            fi
            
            if [[ "${ENABLE_POSTURE_REMINDER:-true}" == "true" ]]; then
                sleep $((POSTURE_INTERVAL * 60)) && posture_reminder &
            fi
            
            if [[ "${ENABLE_TIME_REMINDER:-true}" == "true" ]]; then
                sleep 60 && time_reminder &
            fi
            
            sleep 60  # 检查间隔
        done
    ) &
    
    echo $! > "$pid_file"
    echo "✅ 提醒服务已启动 (PID: $(cat $pid_file))"
    
    notify-send "🔔 定期提醒" "健康提醒服务已启动" -i dialog-information -u normal -t 5000
}

# 停止提醒服务
stop_reminders() {
    local pid_file="$HOME/.local/run/periodic-reminders.pid"
    
    if [[ -f "$pid_file" ]] && kill -0 $(cat "$pid_file") 2>/dev/null; then
        kill $(cat "$pid_file")
        rm -f "$pid_file"
        echo "⏹️ 提醒服务已停止"
        notify-send "🔔 定期提醒" "健康提醒服务已停止" -i dialog-information -u normal -t 3000
    else
        echo "⚠️ 提醒服务未运行"
    fi
}

# 显示服务状态
show_status() {
    local pid_file="$HOME/.local/run/periodic-reminders.pid"
    
    if [[ -f "$pid_file" ]] && kill -0 $(cat "$pid_file") 2>/dev/null; then
        echo "✅ 提醒服务正在运行 (PID: $(cat $pid_file))"
        echo "📋 配置文件: $REMINDERS_CONFIG"
        echo "⏰ 当前提醒设置:"
        [[ "${ENABLE_BREAK_REMINDER:-true}" == "true" ]] && echo "   - 休息提醒: 每 $BREAK_INTERVAL 分钟"
        [[ "${ENABLE_WATER_REMINDER:-true}" == "true" ]] && echo "   - 喝水提醒: 每 $WATER_INTERVAL 分钟"
        [[ "${ENABLE_EYE_REMINDER:-true}" == "true" ]] && echo "   - 护眼提醒: 每 $EYE_INTERVAL 分钟"
        [[ "${ENABLE_POSTURE_REMINDER:-true}" == "true" ]] && echo "   - 坐姿提醒: 每 $POSTURE_INTERVAL 分钟"
    else
        echo "❌ 提醒服务未运行"
    fi
}

# 主函数
case "${1:-}" in
    "start")
        start_reminders
        ;;
    "stop")
        stop_reminders
        ;;
    "restart")
        stop_reminders
        sleep 2
        start_reminders
        ;;
    "status")
        show_status
        ;;
    "test")
        echo "🧪 测试各种提醒..."
        break_reminder
        sleep 2
        water_reminder
        sleep 2
        eye_reminder
        sleep 2
        posture_reminder
        sleep 2
        time_reminder
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|test}"
        echo ""
        echo "命令："
        echo "  start   - 启动定期提醒服务"
        echo "  stop    - 停止定期提醒服务"
        echo "  restart - 重启定期提醒服务"
        echo "  status  - 查看服务状态"
        echo "  test    - 测试各种提醒"
        echo ""
        echo "配置文件: $REMINDERS_CONFIG"
        ;;
esac
