#!/bin/bash

# Hyprland Power Menu Script - Enhanced Version
# Display elegant power options using menu tools

THEME_DIR="$HOME/.config/wofi"
POWER_MENU_CSS="$THEME_DIR/power-menu.css"

# 创建电源菜单CSS样式
create_power_menu_style() {
    mkdir -p "$THEME_DIR"
    
    cat > "$POWER_MENU_CSS" << 'EOF'
window {
    margin: 0px;
    border: none;
    border-radius: 20px;
    background-color: rgba(40, 44, 52, 0.95);
    backdrop-filter: blur(20px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

#input {
    all: unset;
    margin: 10px;
    padding: 12px 16px;
    color: #abb2bf;
    font-weight: bold;
    background-color: rgba(97, 175, 239, 0.1);
    border: 2px solid rgba(97, 175, 239, 0.3);
    border-radius: 16px;
    font-size: 16px;
}

#inner-box {
    margin: 5px;
    padding: 10px;
    background-color: transparent;
    border: none;
    border-radius: 16px;
}

#outer-box {
    margin: 5px;
    padding: 10px;
    background-color: transparent;
    border: none;
    border-radius: 20px;
}

#scroll {
    margin-top: 5px;
    border: none;
    border-radius: 16px;
    background-color: transparent;
}

#entry {
    margin: 5px;
    padding: 12px 16px;
    border: none;
    border-radius: 16px;
    background-color: rgba(62, 68, 82, 0.6);
    color: #ffffff;
    font-size: 16px;
    font-weight: 600;
    transition: all 0.3s ease;
}

#entry:selected {
    background-color: rgba(97, 175, 239, 0.8);
    color: #ffffff;
    box-shadow: 0 4px 16px rgba(97, 175, 239, 0.3);
}

#entry:hover {
    background-color: rgba(97, 175, 239, 0.6);
    color: #ffffff;
    box-shadow: 0 3px 12px rgba(97, 175, 239, 0.2);
}

#text {
    color: inherit;
    font-size: 16px;
    font-weight: 600;
    margin: 0;
    padding: 0;
}
EOF
}

# 检查可用的菜单工具（不强制要求wofi）
MENU_CMD=""
if command -v wofi &> /dev/null; then
    MENU_CMD="wofi"
elif command -v rofi &> /dev/null; then
    MENU_CMD="rofi"
elif command -v fuzzel &> /dev/null; then
    MENU_CMD="fuzzel"
elif command -v dmenu &> /dev/null; then
    MENU_CMD="dmenu"
elif command -v zenity &> /dev/null; then
    MENU_CMD="zenity"
else
    notify-send "Error" "Need to install a menu tool (wofi/rofi/fuzzel/dmenu/zenity)" --urgency=critical
    exit 1
fi

# Power options
options="🔒 Lock Screen
💤 Suspend
🔄 Reboot
⏹️ Shutdown
🚪 Logout
📴 Hibernate
❌ Cancel"

# 显示菜单并获取选择
case $MENU_CMD in
    "wofi")
        # 确保样式文件存在
        create_power_menu_style
        selected=$(echo "$options" | wofi \
            --dmenu \
            --prompt="Power Options" \
            --width=250 \
            --height=350 \
            --location=center \
            --style="$POWER_MENU_CSS" \
            --hide-scroll \
            --no-actions \
            --insensitive \
            --cache-file=/dev/null)
        ;;
    "rofi")
        selected=$(echo "$options" | rofi -dmenu -p "Power Options" -theme-str 'window {width: 250px;}' -no-custom)
        ;;
    "fuzzel")
        selected=$(echo "$options" | fuzzel --dmenu --prompt="Power Options: " --width=30)
        ;;
    "dmenu")
        selected=$(echo "$options" | dmenu -p "Power Options:")
        ;;
    "zenity")
        selected=$(zenity --list --title="Power Options" --column="Select" --height=400 --width=300 \
            "🔒 Lock Screen" \
            "💤 Suspend" \
            "🔄 Reboot" \
            "⏹️ Shutdown" \
            "🚪 Logout" \
            "📴 Hibernate" \
            "❌ Cancel")
        ;;
esac

# 根据选择执行操作
case $selected in
    "🔒 Lock Screen")
        # 检查锁屏工具是否安装
        if command -v swaylock &> /dev/null; then
            swaylock -f --color 2e3440 --inside-color 3b4252 --ring-color 5e81ac --key-hl-color 88c0d0 --text-color eceff4
        elif command -v hyprlock &> /dev/null; then
            hyprlock
        else
            notify-send "Error" "No lock screen tool installed (swaylock/hyprlock)" --urgency=critical
        fi
        ;;
    "💤 Suspend")
        notify-send "System" "Suspending..." --urgency=normal
        sleep 1
        systemctl suspend
        ;;
    "🔄 Reboot")
        notify-send "System" "Rebooting..." --urgency=normal
        sleep 1
        systemctl reboot
        ;;
    "⏹️ Shutdown")
        notify-send "System" "Shutting down..." --urgency=normal
        sleep 1
        systemctl poweroff
        ;;
    "🚪 Logout")
        notify-send "System" "Logging out..." --urgency=normal
        sleep 1
        hyprctl dispatch exit
        ;;
    "📴 Hibernate")
        notify-send "System" "Hibernating..." --urgency=normal
        sleep 1
        systemctl hibernate
        ;;
    "❌ Cancel")
        # Do nothing
        ;;
esac