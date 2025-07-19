#!/bin/bash

# YouTube Music control script
# Responds to waybar click events

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
}

ACTION="$1"
PLAYER=$(get_youtube_player)

if [[ -z "$PLAYER" ]]; then
    # If not running, start YouTube Music
    if [[ "$ACTION" == "play-pause" ]]; then
        youtube-music &
    fi
    exit 0
fi

case "$ACTION" in
    "play-pause")
        playerctl -p "$PLAYER" play-pause
        ;;
    "next")
        playerctl -p "$PLAYER" next
        ;;
    "previous")
        playerctl -p "$PLAYER" previous
        ;;
    "stop")
        playerctl -p "$PLAYER" stop
        ;;
    "lyrics")
        ~/.config/waybar/youtube-music-lyrics.sh
        ;;
    *)
        echo "Usage: $0 {play-pause|next|previous|stop|lyrics}"
        exit 1
        ;;
esac

# Trigger waybar update
pkill -RTMIN+11 waybar