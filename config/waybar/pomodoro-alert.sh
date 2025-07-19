#!/bin/bash

# 番茄计时器强制提示脚本
# 在时间到达时显示全屏提示

show_alert() {
    local title="$1"
    local message="$2"
    local type="$3"  # work_end, break_end
    
    # 播放更强烈的提示音序列
    for i in {1..3}; do
        pactl load-module module-sine frequency=1000 > /dev/null 2>&1
        sleep 0.3
        pactl unload-module module-sine > /dev/null 2>&1
        sleep 0.1
        pactl load-module module-sine frequency=800 > /dev/null 2>&1
        sleep 0.3
        pactl unload-module module-sine > /dev/null 2>&1
        sleep 0.2
    done
    
    # 显示大型通知并闪烁屏幕
    notify-send -u critical -t 15000 -i appointment-soon "$title" "$message\n\n点击选择下一步操作"
    
    # 屏幕闪烁效果
    for i in {1..5}; do
        brightnessctl set 100% > /dev/null 2>&1
        sleep 0.1
        brightnessctl set 50% > /dev/null 2>&1
        sleep 0.1
    done
    brightnessctl set 100% > /dev/null 2>&1
    
    # 使用 wofi 显示全屏选择
    case "$type" in
        "work_end")
            choice=$(echo -e "开始休息\n继续工作\n跳过休息" | wofi --dmenu --prompt="🍅 工作时间结束！" --width=400 --height=200)
            case "$choice" in
                "开始休息")
                    # 自动进入休息模式（已经在主脚本中处理）
                    ;;
                "继续工作")
                    ~/.config/waybar/pomodoro-control.sh skip
                    ~/.config/waybar/pomodoro-control.sh toggle
                    ;;
                "跳过休息")
                    ~/.config/waybar/pomodoro-control.sh skip
                    ;;
            esac
            ;;
        "break_end")
            choice=$(echo -e "开始工作\n延长休息" | wofi --dmenu --prompt="😴 休息结束！" --width=400 --height=200)
            case "$choice" in
                "开始工作")
                    # 自动进入工作模式（已经在主脚本中处理）
                    ;;
                "延长休息")
                    ~/.config/waybar/pomodoro-control.sh stop
                    ;;
            esac
            ;;
    esac
}

# 根据参数调用相应的提示
case "$1" in
    "work_end")
        show_alert "🍅 番茄计时" "工作时间结束！是时候休息了" "work_end"
        ;;
    "break_end")
        show_alert "😴 休息时间" "休息结束！准备开始新的番茄" "break_end"
        ;;
    *)
        echo "用法: $0 {work_end|break_end}"
        exit 1
        ;;
esac