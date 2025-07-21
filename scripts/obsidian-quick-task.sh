#!/bin/bash

# Obsidian 快速添加任务脚本
# 专门用于快速添加任务到 Inbox

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_SCRIPT="$SCRIPT_DIR/obsidian-quick-capture.sh"

# 使用 wofi/rofi 等选择器创建任务输入界面
if command -v wofi &> /dev/null; then
    # 使用 wofi (优先选择，适合 Wayland)
    task=$(echo "" | wofi --dmenu --prompt "🚀 Add Task" --lines 0)
elif command -v rofi &> /dev/null; then
    # 使用 rofi
    task=$(rofi -dmenu -p "🚀 Add Task" -lines 0)
elif command -v fuzzel &> /dev/null; then
    # 使用 fuzzel (Wayland)
    task=$(echo "" | fuzzel --dmenu --prompt "🚀 Add Task: ")
elif command -v dmenu &> /dev/null; then
    # 使用 dmenu
    task=$(echo "" | dmenu -p "🚀 Add Task")
elif command -v zenity &> /dev/null; then
    # 使用 zenity (图形界面)
    task=$(zenity --entry --title="🚀 Obsidian Quick Task" --text="Enter task content:")
else
    # 回退到终端输入
    read -p "🚀 Add Task: " task
fi

# 如果用户取消或输入为空，退出
if [ -z "$task" ]; then
    exit 0
fi

# 调用快速捕获脚本，专门添加任务
"$CAPTURE_SCRIPT" --task "$task"