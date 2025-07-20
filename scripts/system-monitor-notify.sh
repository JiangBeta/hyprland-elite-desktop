#!/bin/bash

# 系统监控通知脚本
# 监控系统资源使用情况并发送通知

CONFIG_FILE="$HOME/.config/system-monitor-notify.conf"

# 默认配置
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
BATTERY_THRESHOLD=20
TEMP_THRESHOLD=70

# 读取配置文件
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    # 创建默认配置文件
    cat > "$CONFIG_FILE" << EOF
# 系统监控通知配置文件

# CPU 使用率阈值 (百分比)
CPU_THRESHOLD=80

# 内存使用率阈值 (百分比)
MEMORY_THRESHOLD=80

# 磁盘使用率阈值 (百分比)
DISK_THRESHOLD=85

# 电池电量阈值 (百分比)
BATTERY_THRESHOLD=20

# CPU 温度阈值 (摄氏度)
TEMP_THRESHOLD=70

# 通知间隔 (秒) - 防止重复通知
NOTIFY_INTERVAL=300
EOF
fi

# 检查 CPU 使用率
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    cpu_usage=${cpu_usage%.*}  # 去除小数部分
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l normal -t "CPU 使用率过高" -m "当前使用率: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)"
        return 1
    fi
    return 0
}

# 检查内存使用率
check_memory() {
    local memory_info=$(free | grep Mem)
    local total=$(echo $memory_info | awk '{print $2}')
    local used=$(echo $memory_info | awk '{print $3}')
    local usage=$(( (used * 100) / total ))
    
    if (( usage > MEMORY_THRESHOLD )); then
        $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l normal -t "内存使用率过高" -m "当前使用率: ${usage}% (阈值: ${MEMORY_THRESHOLD}%)"
        return 1
    fi
    return 0
}

# 检查磁盘使用率
check_disk() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if (( disk_usage > DISK_THRESHOLD )); then
        $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l critical -t "磁盘空间不足" -m "根分区使用率: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)"
        return 1
    fi
    return 0
}

# 检查电池电量
check_battery() {
    if [[ -d "/sys/class/power_supply" ]]; then
        local batteries=(/sys/class/power_supply/BAT*)
        if [[ -e "${batteries[0]}" ]]; then
            local battery_level=$(cat "${batteries[0]}/capacity" 2>/dev/null)
            local battery_status=$(cat "${batteries[0]}/status" 2>/dev/null)
            
            if [[ -n "$battery_level" && "$battery_status" != "Charging" && $battery_level -le $BATTERY_THRESHOLD ]]; then
                $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l critical -t "电池电量过低" -m "当前电量: ${battery_level}% (阈值: ${BATTERY_THRESHOLD}%)"
                return 1
            fi
        fi
    fi
    return 0
}

# 检查 CPU 温度
check_temperature() {
    if command -v sensors &> /dev/null; then
        local temp=$(sensors | grep 'Core 0' | awk '{print $3}' | sed 's/+//' | sed 's/°C//' | cut -d. -f1)
        if [[ -n "$temp" && $temp -gt $TEMP_THRESHOLD ]]; then
            $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l critical -t "CPU 温度过高" -m "当前温度: ${temp}°C (阈值: ${TEMP_THRESHOLD}°C)"
            return 1
        fi
    fi
    return 0
}

# 检查网络连接
check_network() {
    # 设置超时时间为5秒
    if ! timeout 5 ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l critical -t "网络连接异常" -m "无法连接到互联网"
        return 1
    fi
    return 0
}

# 发送正常状态通知
send_status_notification() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local memory_usage=$(free | awk 'FNR==2{printf "%.0f", $3/$2*100}')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    
    $HOME/dotfiles/scripts/enhanced-notify.sh -c System -l low -t "系统状态正常" -m "CPU: ${cpu_usage%.*}% | 内存: ${memory_usage}% | 磁盘: ${disk_usage}"
}

# 主函数
main() {
    local issues=0
    
    check_cpu || ((issues++))
    check_memory || ((issues++))
    check_disk || ((issues++))
    check_battery || ((issues++))
    check_temperature || ((issues++))
    check_network || ((issues++))
    
    # 如果没有问题，发送状态通知 (可选)
    if [[ $issues -eq 0 && "${1:-}" == "--status" ]]; then
        send_status_notification
    fi
    
    return $issues
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
