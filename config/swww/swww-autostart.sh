#!/bin/bash

# swww 自动启动脚本
# 适用于 Hyprland 或其他 Wayland 桌面环境

# 等待桌面环境完全启动
sleep 3

# 启动 swww daemon
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "启动 swww daemon..."
    swww-daemon &
    sleep 2
fi

# 等待 daemon 完全启动
sleep 2

# 设置初始壁纸
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SCRIPT_DIR="$HOME/.config/swww"

# 如果存在随机壁纸脚本，使用它
if [[ -x "$SCRIPT_DIR/swww-random.sh" ]]; then
    "$SCRIPT_DIR/swww-random.sh"
else
    # 回退到简单设置
    if [[ -d "$WALLPAPER_DIR" ]]; then
        FIRST_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -1)
        if [[ -n "$FIRST_WALLPAPER" ]]; then
            swww img "$FIRST_WALLPAPER" --transition-type fade --transition-duration 2000 --fill crop --resize lanczos3
        fi
    fi
fi

echo "swww 自动启动完成"