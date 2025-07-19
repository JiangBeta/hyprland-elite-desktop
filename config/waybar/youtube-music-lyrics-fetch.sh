#!/bin/bash

# YouTube Music 歌词获取脚本
# 通过检查浏览器 DOM 来获取歌词

# 获取 YouTube Music 的窗口ID
get_youtube_music_window() {
    # 查找 YouTube Music 窗口
    xdotool search --name "YouTube Music" 2>/dev/null | head -1
}

# 从 YouTube Music 页面获取歌词
get_lyrics_from_page() {
    local window_id="$1"
    
    if [[ -z "$window_id" ]]; then
        return 1
    fi
    
    # 尝试通过开发者工具获取歌词
    # 这需要 YouTube Music 页面有歌词显示
    
    # 先尝试按下歌词按钮 (通常是页面右下角的歌词图标)
    xdotool windowfocus "$window_id" 2>/dev/null
    sleep 0.5
    
    # YouTube Music 的歌词按钮通常可以通过快捷键打开
    # 尝试按 'l' 键打开歌词面板
    xdotool key --clearmodifiers l 2>/dev/null
    
    return 0
}

# 通过检查剪贴板获取歌词（如果用户复制了歌词）
get_lyrics_from_clipboard() {
    # 检查剪贴板内容是否像歌词
    clipboard_content=$(xclip -o -selection clipboard 2>/dev/null)
    
    # 简单检查：如果内容包含换行且不是太长，可能是歌词
    if [[ -n "$clipboard_content" && $(echo "$clipboard_content" | wc -l) -gt 1 && $(echo "$clipboard_content" | wc -c) -lt 1000 ]]; then
        echo "$clipboard_content"
        return 0
    fi
    
    return 1
}

# 主函数
main() {
    window_id=$(get_youtube_music_window)
    
    if [[ -n "$window_id" ]]; then
        get_lyrics_from_page "$window_id"
        
        # 给一点时间让歌词加载
        sleep 1
        
        # 尝试从剪贴板获取（如果用户手动复制了歌词）
        if lyrics=$(get_lyrics_from_clipboard); then
            echo "$lyrics"
            return 0
        fi
    fi
    
    return 1
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi