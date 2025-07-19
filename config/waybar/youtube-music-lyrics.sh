#!/bin/bash

# YouTube Music lyrics display script
# Note: Requires Synced Lyrics plugin to be installed and enabled in YouTube Music

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

PLAYER=$(get_youtube_player)

if [[ -z "$PLAYER" ]]; then
    notify-send "YouTube Music" "YouTube Music not running" -i youtube-music
    exit 1
fi

# Get current playback info
TITLE=$(playerctl -p "$PLAYER" metadata xesam:title 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null)

if [[ -z "$TITLE" ]]; then
    notify-send "YouTube Music" "No song currently playing" -i youtube-music
    exit 1
fi

# Create temporary file with lyrics instructions
LYRICS_FILE="/tmp/youtube-music-lyrics.txt"
cat > "$LYRICS_FILE" << EOF
YouTube Music Lyrics Viewer
==========================

Now Playing: $TITLE
Artist: $ARTIST

Important Notes:
----------------
1. Make sure Synced Lyrics plugin is installed in YouTube Music
2. Lyrics will display directly in the YouTube Music interface
3. If you can't see lyrics, check if the plugin is enabled

Instructions:
-------------
- Click on YouTube Music window to view lyrics
- Use media control buttons to switch songs
- Lyrics sync automatically with playback progress

Tips for better lyrics experience:
1. Enable lyrics feature in YouTube Music settings
2. Install LRClib or other lyrics provider plugins
3. Use YouTube Music's built-in lyrics display

EOF

# Display lyrics info in terminal
kitty --title="YouTube Music Lyrics" -e bash -c "cat '$LYRICS_FILE' && echo -e '\nPress Enter to close...' && read"

# Clean up temporary file
rm -f "$LYRICS_FILE"

# Activate YouTube Music window
# Find and activate YouTube Music window
wmctrl -l | grep -i "youtube music" | head -1 | awk '{print $1}' | xargs -I {} wmctrl -i -a {}