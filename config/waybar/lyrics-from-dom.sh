#!/bin/bash

# 从 YouTube Music DOM 获取歌词

get_youtube_player() {
    playerctl -l 2>/dev/null | grep -E "chromium\.|chrome\." | while read -r player; do
        title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null)
        if [[ -n "$title" ]]; then
            pid=$(echo "$player" | grep -oE '[0-9]+')
            if ps -p "$pid" -o cmd= 2>/dev/null | grep -q "youtube-music"; then
                echo "$player"
                return
            fi
        fi
    done
}

# 从 YouTube Music 窗口获取歌词
get_lyrics_from_window() {
    local player="$1"
    local pid=$(echo "$player" | grep -oE '[0-9]+')
    
    # 查找 YouTube Music 窗口
    local window_id=$(xdotool search --pid "$pid" --name "YouTube Music" 2>/dev/null | head -1)
    
    if [[ -n "$window_id" ]]; then
        # 尝试获取当前歌词文本（这需要页面上有歌词显示）
        # 使用 xdotool 来获取窗口内容
        xdotool windowfocus "$window_id" 2>/dev/null
        sleep 0.2
        
        # 模拟选择歌词区域的操作
        # 通常歌词会在特定的 CSS 选择器下
        # 这里我们尝试复制可能的歌词文本到剪贴板
        
        # 先清空剪贴板
        echo -n "" | xclip -selection clipboard 2>/dev/null
        
        # 尝试按 Ctrl+A 全选，然后 Ctrl+C 复制
        # 注意：这会复制整个页面，不理想
        
        # 更好的方法：使用浏览器的开发者工具或者注入 JavaScript
        return 1
    fi
    
    return 1
}

PLAYER=$(get_youtube_player)
if [[ -n "$PLAYER" ]]; then
    get_lyrics_from_window "$PLAYER"
fi