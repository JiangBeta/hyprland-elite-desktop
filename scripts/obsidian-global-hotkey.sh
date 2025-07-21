#!/bin/bash

# Obsidian 全局快捷键脚本
# 用于系统级快捷键绑定 (如 Hyprland/i3/Sway 等)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_SCRIPT="$SCRIPT_DIR/obsidian-quick-capture.sh"

# 一个弹窗完成所有操作：使用前缀来选择类型
# 提示用户可以用前缀或直接输入
prompt_text="💡 Quick Capture [t: l: s: c:] or idea"

if command -v wofi &> /dev/null; then
    # 使用 wofi (优先选择，适合 Wayland)
    input=$(echo "" | wofi --dmenu --prompt "$prompt_text" --lines 0)
elif command -v rofi &> /dev/null; then
    # 使用 rofi
    input=$(rofi -dmenu -p "$prompt_text" -lines 0)
elif command -v fuzzel &> /dev/null; then
    # 使用 fuzzel (Wayland)
    input=$(echo "" | fuzzel --dmenu --prompt "$prompt_text")
elif command -v dmenu &> /dev/null; then
    # 使用 dmenu
    input=$(echo "" | dmenu -p "$prompt_text")
elif command -v zenity &> /dev/null; then
    # 使用 zenity (图形界面)
    input=$(zenity --entry --title="💡 Obsidian Quick Capture" --text="Enter content (use t:, l:, s:, c: prefixes or just type):")
else
    # 回退到终端输入
    echo "Quick Capture - Use prefixes:"
    echo "  t: for tasks    (e.g., 't: buy milk')"
    echo "  l: for links    (e.g., 'l: https://...')"
    echo "  s: for study    (e.g., 's: learn git')"
    echo "  c: for contacts (e.g., 'c: call john')"
    echo "  or just type your idea directly"
    read -p "Input: " input
fi

# 如果用户取消或输入为空，退出
if [ -z "$input" ]; then
    exit 0
fi

# 解析输入，检查前缀
if [[ "$input" =~ ^t:\ *(.+)$ ]]; then
    # 任务前缀
    content="${BASH_REMATCH[1]}"
    "$CAPTURE_SCRIPT" --task "$content"
elif [[ "$input" =~ ^l:\ *(.+)$ ]]; then
    # 链接前缀
    content="${BASH_REMATCH[1]}"
    "$CAPTURE_SCRIPT" --link "$content"
elif [[ "$input" =~ ^s:\ *(.+)$ ]]; then
    # 学习前缀
    content="${BASH_REMATCH[1]}"
    "$CAPTURE_SCRIPT" --learn "$content"
elif [[ "$input" =~ ^c:\ *(.+)$ ]]; then
    # 联系人前缀
    content="${BASH_REMATCH[1]}"
    "$CAPTURE_SCRIPT" --contact "$content"
else
    # 没有前缀，默认为想法
    "$CAPTURE_SCRIPT" "$input"
fi