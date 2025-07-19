#!/bin/bash

echo "=== YouTube Music 歌词调试 ==="

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
    echo "❌ YouTube Music 未运行"
    exit 1
fi

echo "✅ 找到播放器: $PLAYER"

TITLE=$(playerctl -p "$PLAYER" metadata xesam:title 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null)

echo "🎵 当前播放: $ARTIST - $TITLE"
echo ""

echo "=== 测试歌词获取方法 ==="

# 方法1: MPRIS lyrics
echo "1️⃣ MPRIS lyrics:"
MPRIS_LYRICS=$(playerctl -p "$PLAYER" metadata --format '{{mpris:lyrics}}' 2>/dev/null)
if [[ -n "$MPRIS_LYRICS" && "$MPRIS_LYRICS" != "{"* ]]; then
    echo "✅ 找到: $(echo "$MPRIS_LYRICS" | head -1)"
else
    echo "❌ 无数据"
fi

# 方法2: 其他 MPRIS 字段
echo ""
echo "2️⃣ 其他 MPRIS 字段:"
for field in lyric text comment subtitle lrc syncedLyrics; do
    value=$(playerctl -p "$PLAYER" metadata --format "{{mpris:$field}}" 2>/dev/null)
    if [[ -n "$value" && "$value" != "{"* && "$value" != "" ]]; then
        echo "✅ mpris:$field: $(echo "$value" | head -1)"
    else
        echo "❌ mpris:$field: 无数据"
    fi
done

# 方法3: xesam 字段
echo ""
echo "3️⃣ xesam 字段:"
for field in lyrics lyric comment; do
    value=$(playerctl -p "$PLAYER" metadata --format "{{xesam:$field}}" 2>/dev/null)
    if [[ -n "$value" && "$value" != "{"* && "$value" != "" ]]; then
        echo "✅ xesam:$field: $(echo "$value" | head -1)"
    else
        echo "❌ xesam:$field: 无数据"
    fi
done

# 方法4: 所有 metadata
echo ""
echo "4️⃣ 所有可用 metadata:"
playerctl -p "$PLAYER" metadata 2>/dev/null

# 方法5: 测试外部 API
echo ""
echo "5️⃣ 测试外部 API (lyrics.ovh):"
if [[ -n "$ARTIST" && -n "$TITLE" ]] && command -v curl >/dev/null 2>&1; then
    encoded_artist=$(echo "$ARTIST" | sed 's/ /%20/g')
    encoded_title=$(echo "$TITLE" | sed 's/ /%20/g')
    url="https://api.lyrics.ovh/v1/${encoded_artist}/${encoded_title}"
    
    echo "📡 请求: $url"
    
    api_response=$(curl -s --max-time 5 "$url" 2>/dev/null)
    if [[ -n "$api_response" ]] && echo "$api_response" | grep -q '"lyrics"'; then
        lyrics_preview=$(echo "$api_response" | grep -o '"lyrics":"[^"]*"' | sed 's/"lyrics":"//; s/"$//' | sed 's/\\n/\n/g' | head -2)
        echo "✅ API 返回歌词:"
        echo "$lyrics_preview"
        echo "..."
    else
        echo "❌ API 无歌词数据"
        echo "响应: $api_response"
    fi
else
    echo "❌ 缺少必要信息或 curl 不可用"
fi

echo ""
echo "=== 配置检查 ==="
echo "synced-lyrics 插件状态:"
if grep -q '"synced-lyrics".*"enabled": true' ~/.config/YouTube\ Music/config.json 2>/dev/null; then
    echo "✅ synced-lyrics 插件已启用"
else
    echo "❌ synced-lyrics 插件未启用或配置文件不存在"
fi