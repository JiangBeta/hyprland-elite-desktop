#!/bin/bash

# YouTube Music media control script

# Get YouTube Music playerctl instance
get_youtube_player() {
    playerctl -l 2>/dev/null | grep -E "chromium\.|chrome\." | while read -r player; do
        # Check if it's YouTube Music
        title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null)
        if [[ -n "$title" ]]; then
            # Check if process contains youtube-music
            pid=$(echo "$player" | grep -oE '[0-9]+')
            if ps -p "$pid" -o cmd= 2>/dev/null | grep -q "youtube-music"; then
                echo "$player"
                return
            fi
        fi
    done
    
    # Fallback: if no specific YouTube Music process found, use first chromium player
    playerctl -l 2>/dev/null | grep -E "chromium\.|chrome\." | head -n 1
}

PLAYER=$(get_youtube_player)

if [[ -z "$PLAYER" ]]; then
    echo '{"text": "󰎇", "class": "inactive", "tooltip": "YouTube Music not running"}'
    exit 0
fi

# Get playback status
STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
TITLE=$(playerctl -p "$PLAYER" metadata xesam:title 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null)
ALBUM=$(playerctl -p "$PLAYER" metadata xesam:album 2>/dev/null)

# Truncate long text
truncate_text() {
    local text="$1"
    local max_length="$2"
    if [[ ${#text} -gt $max_length ]]; then
        echo "${text:0:$((max_length-3))}..."
    else
        echo "$text"
    fi
}

# Build display icon
if [[ "$STATUS" == "Playing" ]]; then
    ICON="󰏤"
    CLASS="playing"
elif [[ "$STATUS" == "Paused" ]]; then
    ICON="󰐊"
    CLASS="paused"
else
    ICON="󰓛"
    CLASS="stopped"
fi

# Build display text
if [[ -n "$TITLE" ]]; then
    DISPLAY_TITLE=$(truncate_text "$TITLE" 30)
    DISPLAY_ARTIST=$(truncate_text "$ARTIST" 20)
    TEXT="$ICON $DISPLAY_ARTIST - $DISPLAY_TITLE"
    
    # Build complete tooltip
    TOOLTIP="$TITLE"
    if [[ -n "$ARTIST" ]]; then
        TOOLTIP="$TOOLTIP\nArtist: $ARTIST"
    fi
    if [[ -n "$ALBUM" ]]; then
        TOOLTIP="$TOOLTIP\nAlbum: $ALBUM"
    fi
    TOOLTIP="$TOOLTIP\nStatus: $STATUS"
else
    TEXT="$ICON YouTube Music"
    TOOLTIP="YouTube Music\nStatus: $STATUS"
fi

# Output JSON (without jq dependency)
printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"