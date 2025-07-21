#!/bin/bash

# Obsidian 全局快捷键脚本
# 用于系统级快捷键绑定 (如 Hyprland/i3/Sway 等)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_SCRIPT="$SCRIPT_DIR/obsidian-quick-capture.sh"
WOFI_STYLE="$HOME/dotfiles/config/wofi/obsidian-capture.css"

# 获取剪贴板内容 (如果有的话)
clipboard_content=""
if command -v wl-paste &> /dev/null; then
    # Wayland 剪贴板
    clipboard_content=$(wl-paste 2>/dev/null | head -c 200)
elif command -v xclip &> /dev/null; then
    # X11 剪贴板
    clipboard_content=$(xclip -selection clipboard -o 2>/dev/null | head -c 200)
fi

# 清理剪贴板内容，移除换行符和多余空格
if [ -n "$clipboard_content" ]; then
    clipboard_content=$(echo "$clipboard_content" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# 构建提示文本和默认输入
prompt_text="Quick Capture"
if [ -n "$clipboard_content" ]; then
    default_input="$clipboard_content"
else
    default_input=""
fi

# 创建提示信息
hints="📝 t: task
🔗 l: link  
📚 s: study
👤 c: contact
💡 idea"

if command -v wofi &> /dev/null; then
    # 使用 wofi (优先选择，适合 Wayland) 配合专用样式
    if [ -f "$WOFI_STYLE" ]; then
        # 使用专用样式，剪贴板内容作为初始输入
        input=$(printf "%s\n%s" "$default_input" "$hints" | wofi --dmenu --prompt "$prompt_text" --lines 6 --height 300 --style "$WOFI_STYLE" --cache-file /dev/null)
    else
        # 回退到默认样式
        input=$(printf "%s\n%s" "$default_input" "$hints" | wofi --dmenu --prompt "$prompt_text" --lines 0)
    fi
elif command -v rofi &> /dev/null; then
    # 使用 rofi
    input=$(echo "$default_input" | rofi -dmenu -p "$prompt_text" -lines 0)
elif command -v fuzzel &> /dev/null; then
    # 使用 fuzzel (Wayland)
    input=$(echo "$default_input" | fuzzel --dmenu --prompt "$prompt_text")
elif command -v dmenu &> /dev/null; then
    # 使用 dmenu
    input=$(echo "$default_input" | dmenu -p "$prompt_text")
elif command -v zenity &> /dev/null; then
    # 使用 zenity (图形界面)
    input=$(zenity --entry --title="💡 Obsidian Quick Capture" --text="$hints" --entry-text="$default_input")
else
    # 回退到终端输入
    echo "Quick Capture - Use prefixes:"
    echo "  t: for tasks    (e.g., 't: buy milk')"
    echo "  l: for links    (e.g., 'l: https://...')"
    echo "  s: for study    (e.g., 's: learn git')"
    echo "  c: for contacts (e.g., 'c: call john')"
    echo "  or just type your idea directly"
    if [ -n "$default_input" ]; then
        echo "Clipboard content: $default_input"
        read -p "Input: " -i "$default_input" -e input
    else
        read -p "Input: " input
    fi
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