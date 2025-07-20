#!/bin/bash

# Hyprland电源菜单脚本 - 增强版
# 使用wofi显示美观的电源选项

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

# 检查必要工具
if ! command -v wofi &> /dev/null; then
    notify-send "错误" "需要安装wofi" --urgency=critical
    exit 1
fi

# 电源选项
options="🔒 锁定屏幕
💤 休眠
🔄 重启
⏹️ 关机
🚪 注销
📴 睡眠
❌ 取消"

# 确保样式文件存在
create_power_menu_style

# 显示菜单并获取选择
selected=$(echo "$options" | wofi \
    --dmenu \
    --prompt="电源选项" \
    --width=250 \
    --height=350 \
    --location=center \
    --style="$POWER_MENU_CSS" \
    --hide-scroll \
    --no-actions \
    --insensitive \
    --cache-file=/dev/null)

# 根据选择执行操作
case $selected in
    "🔒 锁定屏幕")
        # 检查锁屏工具是否安装
        if command -v swaylock &> /dev/null; then
            swaylock -f --color 2e3440 --inside-color 3b4252 --ring-color 5e81ac --key-hl-color 88c0d0 --text-color eceff4
        elif command -v hyprlock &> /dev/null; then
            hyprlock
        else
            notify-send "错误" "未安装锁屏工具 (swaylock/hyprlock)" --urgency=critical
        fi
        ;;
    "💤 休眠")
        notify-send "系统" "正在休眠..." --urgency=normal
        sleep 1
        systemctl suspend
        ;;
    "🔄 重启")
        notify-send "系统" "正在重启..." --urgency=normal
        sleep 1
        systemctl reboot
        ;;
    "⏹️ 关机")
        notify-send "系统" "正在关机..." --urgency=normal
        sleep 1
        systemctl poweroff
        ;;
    "🚪 注销")
        notify-send "系统" "正在注销..." --urgency=normal
        sleep 1
        hyprctl dispatch exit
        ;;
    "📴 睡眠")
        notify-send "系统" "正在进入睡眠..." --urgency=normal
        sleep 1
        systemctl hibernate
        ;;
    "❌ 取消")
        # 什么都不做
        ;;
esac