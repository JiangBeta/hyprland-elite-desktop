#!/bin/bash

# 测试不同的歌词获取方法

# 获取播放器
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

PLAYER=$(get_youtube_player)

if [[ -z "$PLAYER" ]]; then
    echo "YouTube Music not running"
    exit 1
fi

echo "Testing lyrics retrieval methods..."
echo "=================================="

# 方法1: 标准 MPRIS 歌词字段
echo "1. Standard MPRIS lyrics:"
playerctl -p "$PLAYER" metadata --format '{{mpris:lyrics}}' 2>/dev/null | head -3

# 方法2: 扩展 MPRIS 字段
echo -e "\n2. Extended MPRIS fields:"
for field in lyrics lyric text caption subtitle lrc; do
    echo "  mpris:$field:"
    playerctl -p "$PLAYER" metadata --format "{{mpris:$field}}" 2>/dev/null | head -1
done

# 方法3: xesam 字段
echo -e "\n3. xesam fields:"
for field in lyrics lyric comment; do
    echo "  xesam:$field:"
    playerctl -p "$PLAYER" metadata --format "{{xesam:$field}}" 2>/dev/null | head -1
done

# 方法4: 所有可用的 metadata
echo -e "\n4. All available metadata:"
playerctl -p "$PLAYER" metadata 2>/dev/null

# 方法5: 检查是否有自定义字段
echo -e "\n5. Custom fields test:"
for field in youtubeLyrics syncedLyrics currentLyrics lrcLyrics; do
    echo "  $field:"
    playerctl -p "$PLAYER" metadata --format "{{$field}}" 2>/dev/null | head -1
done

echo -e "\n6. Current track info:"
echo "Title: $(playerctl -p "$PLAYER" metadata xesam:title 2>/dev/null)"
echo "Artist: $(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null)"