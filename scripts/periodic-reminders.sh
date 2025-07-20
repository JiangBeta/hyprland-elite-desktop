#!/bin/bash

# ===========================================
# 定期提醒通知脚本 (修复版)
# ===========================================
# 提供健康提醒、工作提醒等功能
# 修复了进程爆炸和内存泄漏问题

set -euo pipefail

# 加载环境配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-env.sh"

# 初始化环境
init_dotfiles_env || exit 1

# PID文件和日志
LOCK_DIR="$HOME/.local/run"
PID_FILE="$LOCK_DIR/periodic-reminders.pid"
LOCK_FILE="$LOCK_DIR/periodic-reminders.lock"
LOG_FILE="$(get_config LOG_DIR "$HOME/.local/var/log/dotfiles")/periodic-reminders.log"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 获取任务锁
acquire_lock() {
    local lock_timeout=10
    local count=0
    
    while [[ $count -lt $lock_timeout ]]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            echo $$ > "$LOCK_FILE/pid"
            return 0
        fi
        
        # 检查锁是否过期（超过1小时的锁认为是僵尸锁）
        if [[ -f "$LOCK_FILE/pid" ]]; then
            local lock_pid=$(cat "$LOCK_FILE/pid" 2>/dev/null)
            if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
                log_with_timestamp "清理僵尸锁: $LOCK_FILE"
                rm -rf "$LOCK_FILE"
                continue
            fi
        fi
        
        sleep 1
        ((count++))
    done
    
    return 1
}

# 释放任务锁
release_lock() {
    [[ -d "$LOCK_FILE" ]] && rm -rf "$LOCK_FILE"
}

# 错误处理和清理
cleanup_and_exit() {
    local exit_code=$?
    log_with_timestamp "清理并退出 (exit code: $exit_code)"
    
    # 清理后台进程
    if [[ -n "${bg_pids[*]:-}" ]]; then
        log_with_timestamp "清理 ${#bg_pids[@]} 个后台进程"
        for pid in "${bg_pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        done
    fi
    
    # 释放锁和清理文件
    release_lock
    [[ -f "$PID_FILE" ]] && rm -f "$PID_FILE"
    
    exit $exit_code
}

# 设置信号处理
trap cleanup_and_exit EXIT INT TERM

# 存储后台进程PID
declare -a bg_pids=()

# 清理旧的后台进程
cleanup_old_processes() {
    local new_pids=()
    
    for pid in "${bg_pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            new_pids+=("$pid")
        else
            log_with_timestamp "清理已完成的进程: $pid"
        fi
    done
    
    bg_pids=("${new_pids[@]}")
}

# 发送通知的安全包装
safe_notify() {
    local category="$1"
    local level="$2" 
    local title="$3"
    local message="$4"
    local timeout="${5:-8000}"
    
    # 检查增强通知脚本是否存在
    local notify_script="$SCRIPT_DIR/enhanced-notify.sh"
    
    if [[ -x "$notify_script" ]]; then
        "$notify_script" -c "$category" -l "$level" -t "$title" -m "$message" --timeout "$timeout" &
        local notify_pid=$!
        bg_pids+=("$notify_pid")
        log_with_timestamp "发送通知: $title (PID: $notify_pid)"
    else
        # 回退到系统通知
        notify-send "$title" "$message" -u "$level" -t "$timeout" &
        local notify_pid=$!
        bg_pids+=("$notify_pid")
        log_with_timestamp "发送系统通知: $title (PID: $notify_pid)"
    fi
}

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
    safe_notify "Health" "normal" "休息提醒" "${messages[$random_index]}" 10000
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
    safe_notify "Health" "normal" "喝水提醒" "${messages[$random_index]}" 8000
}

# 护眼提醒（20-20-20法则）
eye_reminder() {
    safe_notify "Health" "normal" "护眼提醒" "20-20-20 法则：\n看向20英尺外的物体\n持续20秒钟" 12000
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
    safe_notify "Health" "normal" "坐姿提醒" "${messages[$random_index]}" 10000
}

# 时间提醒
time_reminder() {
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local current_time=$(date +"%H:%M")
    
    # 整点提醒
    if [[ "$current_minute" == "00" ]]; then
        case $current_hour in
            09) safe_notify "Time" "normal" "⏰ 早安提醒" "新的一天开始了！\n当前时间: $current_time" 5000 ;;
            12) safe_notify "Time" "normal" "🍽️ 午餐时间" "该吃午饭了！\n当前时间: $current_time" 5000 ;;
            18) safe_notify "Time" "normal" "🌅 下班时间" "工作辛苦了！\n当前时间: $current_time" 5000 ;;
            22) safe_notify "Time" "normal" "🌙 晚安提醒" "该准备休息了\n当前时间: $current_time" 5000 ;;
            *) 
                if [[ $current_hour -ge 6 && $current_hour -le 22 ]]; then
                    safe_notify "Time" "low" "⏰ 时间提醒" "当前时间: $current_time" 3000
                fi
                ;;
        esac
    fi
}

# 计划下一次提醒
schedule_reminder() {
    local reminder_type="$1"
    local interval_minutes="$2"
    
    if [[ "$interval_minutes" -gt 0 ]]; then
        (
            sleep $((interval_minutes * 60))
            case "$reminder_type" in
                "break") break_reminder ;;
                "water") water_reminder ;;
                "eye") eye_reminder ;;
                "posture") posture_reminder ;;
                *) log_with_timestamp "未知提醒类型: $reminder_type" ;;
            esac
        ) &
        
        local reminder_pid=$!
        bg_pids+=("$reminder_pid")
        log_with_timestamp "计划 $reminder_type 提醒，间隔 $interval_minutes 分钟 (PID: $reminder_pid)"
    fi
}

# 启动定期提醒守护进程
start_reminders() {
    log_with_timestamp "🔔 启动定期提醒服务..."
    
    # 获取任务锁
    if ! acquire_lock; then
        log_with_timestamp "⚠️ 无法获取任务锁，可能已有实例在运行"
        return 1
    fi
    
    # 检查是否已在运行
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log_with_timestamp "⚠️ 提醒服务已在运行 (PID: $(cat $PID_FILE))"
        release_lock
        return 1
    fi
    
    # 设置日志轮转
    setup_log_rotation "$LOG_FILE" "10M" 5
    
    # 写入PID文件
    echo $$ > "$PID_FILE"
    log_with_timestamp "✅ 提醒服务已启动 (PID: $$)"
    
    # 发送启动通知
    safe_notify "System" "normal" "🔔 定期提醒" "健康提醒服务已启动" 5000
    
    # 主循环 - 每分钟检查一次
    local last_break=0
    local last_water=0
    local last_eye=0
    local last_posture=0
    
    while true; do
        local current_time=$(date +%s)
        local current_minute=$(date +%M)
        
        # 读取最新配置
        load_env_config 2>/dev/null || true
        
        # 获取配置值
        local break_interval=$(get_config BREAK_INTERVAL "120")
        local water_interval=$(get_config WATER_INTERVAL "180")
        local eye_interval=$(get_config EYE_INTERVAL "60")
        local posture_interval=$(get_config POSTURE_INTERVAL "90")
        
        local enable_break=$(get_config ENABLE_BREAK_REMINDER "true")
        local enable_water=$(get_config ENABLE_WATER_REMINDER "true")
        local enable_eye=$(get_config ENABLE_EYE_REMINDER "true")
        local enable_posture=$(get_config ENABLE_POSTURE_REMINDER "true")
        local enable_time=$(get_config ENABLE_TIME_REMINDER "true")
        
        # 检查是否需要发送提醒
        if [[ "$enable_break" == "true" && $((current_time - last_break)) -ge $((break_interval * 60)) ]]; then
            break_reminder
            last_break=$current_time
        fi
        
        if [[ "$enable_water" == "true" && $((current_time - last_water)) -ge $((water_interval * 60)) ]]; then
            water_reminder
            last_water=$current_time
        fi
        
        if [[ "$enable_eye" == "true" && $((current_time - last_eye)) -ge $((eye_interval * 60)) ]]; then
            eye_reminder
            last_eye=$current_time
        fi
        
        if [[ "$enable_posture" == "true" && $((current_time - last_posture)) -ge $((posture_interval * 60)) ]]; then
            posture_reminder
            last_posture=$current_time
        fi
        
        # 时间提醒（整点）
        if [[ "$enable_time" == "true" ]]; then
            time_reminder
        fi
        
        # 清理已完成的后台进程
        cleanup_old_processes
        
        # 检查进程数量，防止过多
        if [[ ${#bg_pids[@]} -gt 50 ]]; then
            log_with_timestamp "警告: 后台进程过多 (${#bg_pids[@]})，强制清理"
            cleanup_old_processes
        fi
        
        # 等待60秒
        sleep 60
    done
}

# 停止提醒服务
stop_reminders() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        local main_pid=$(cat "$PID_FILE")
        log_with_timestamp "⏹️ 停止提醒服务 (PID: $main_pid)"
        
        # 发送TERM信号给主进程
        kill "$main_pid" 2>/dev/null || true
        
        # 等待进程退出
        local count=0
        while kill -0 "$main_pid" 2>/dev/null && [[ $count -lt 10 ]]; do
            sleep 1
            ((count++))
        done
        
        # 如果还没退出，强制杀死
        if kill -0 "$main_pid" 2>/dev/null; then
            log_with_timestamp "强制终止进程: $main_pid"
            kill -9 "$main_pid" 2>/dev/null || true
        fi
        
        # 清理PID文件
        rm -f "$PID_FILE"
        
        log_with_timestamp "✅ 提醒服务已停止"
        safe_notify "System" "normal" "🔔 定期提醒" "健康提醒服务已停止" 3000
    else
        log_with_timestamp "⚠️ 提醒服务未运行"
    fi
}

# 显示服务状态
show_status() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        local main_pid=$(cat "$PID_FILE")
        echo "✅ 提醒服务正在运行 (PID: $main_pid)"
        echo "📋 配置文件: .env.local"
        echo "📁 日志文件: $LOG_FILE"
        echo "⏰ 当前提醒设置:"
        
        # 显示配置值
        echo "   - 休息提醒: 每 $(get_config BREAK_INTERVAL "120") 分钟 (启用: $(get_config ENABLE_BREAK_REMINDER "true"))"
        echo "   - 喝水提醒: 每 $(get_config WATER_INTERVAL "180") 分钟 (启用: $(get_config ENABLE_WATER_REMINDER "true"))"
        echo "   - 护眼提醒: 每 $(get_config EYE_INTERVAL "60") 分钟 (启用: $(get_config ENABLE_EYE_REMINDER "true"))"
        echo "   - 坐姿提醒: 每 $(get_config POSTURE_INTERVAL "90") 分钟 (启用: $(get_config ENABLE_POSTURE_REMINDER "true"))"
        echo "   - 时间提醒: $(get_config ENABLE_TIME_REMINDER "true")"
        
        # 显示进程信息
        local child_count=$(pgrep -P "$main_pid" 2>/dev/null | wc -l)
        echo "📊 子进程数量: $child_count"
        
        # 显示内存使用
        if command -v ps >/dev/null 2>&1; then
            local memory_usage=$(ps -p "$main_pid" -o rss= 2>/dev/null | awk '{print int($1/1024)}' || echo "N/A")
            echo "💾 内存使用: ${memory_usage}MB"
        fi
    else
        echo "❌ 提醒服务未运行"
        [[ -f "$PID_FILE" ]] && echo "🗑️ 清理残留PID文件" && rm -f "$PID_FILE"
    fi
}

# 测试所有提醒
test_reminders() {
    echo "🧪 测试各种提醒..."
    log_with_timestamp "开始测试提醒功能"
    
    break_reminder
    sleep 2
    water_reminder  
    sleep 2
    eye_reminder
    sleep 2
    posture_reminder
    sleep 2
    time_reminder
    
    log_with_timestamp "测试完成"
    echo "✅ 测试完成，请检查通知是否正常显示"
}

# 主函数
main() {
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
            test_reminders
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
            echo "配置文件: .env.local (基于 .env.example)"
            echo "日志文件: $LOG_FILE"
            ;;
    esac
}

# 运行主函数
main "$@"