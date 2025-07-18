#!/bin/bash

# Hyprland 电源管理菜单
# 使用 wofi 显示电源选项

# 检查是否安装了必要的工具
if ! command -v wofi &> /dev/null; then
    notify-send "错误" "需要安装 wofi" --urgency=critical
    exit 1
fi

# 电源选项
options="🔒 Lock
😴 Sleep
🔄 Restart
⚡ Shutdown
🚪 Exit Hyprland
❌ Cancel"

# 显示菜单并获取选择
selected=$(echo "$options" | wofi --dmenu --prompt "Power Menu" --width 300 --height 400)

# 根据选择执行相应操作
case $selected in
    "🔒 Lock")
        # 检查是否安装了锁屏工具
        if command -v swaylock &> /dev/null; then
            swaylock -f -c 000000
        elif command -v hyprlock &> /dev/null; then
            hyprlock
        else
            notify-send "错误" "未安装锁屏工具 (swaylock/hyprlock)" --urgency=critical
        fi
        ;;
    "😴 Sleep")
        notify-send "系统" "正在休眠..." --urgency=normal
        sleep 1
        systemctl suspend
        ;;
    "🔄 Restart")
        notify-send "系统" "正在重启..." --urgency=normal
        sleep 1
        systemctl reboot
        ;;
    "⚡ Shutdown")
        notify-send "系统" "正在关机..." --urgency=normal
        sleep 1
        systemctl poweroff
        ;;
    "🚪 Exit Hyprland")
        notify-send "系统" "正在退出 Hyprland..." --urgency=normal
        sleep 1
        hyprctl dispatch exit
        ;;
    "❌ Cancel")
        # 什么都不做
        ;;
esac