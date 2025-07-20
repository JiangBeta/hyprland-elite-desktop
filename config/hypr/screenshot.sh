#!/bin/bash

# Complete screenshot workflow with editing capabilities
# Fast capture + optional editing and saving

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case "$1" in
    "area-edit")
        # Area screenshot with swappy editor
        TEMP_FILE="/tmp/screenshot_$(date +%s).png"
        if grim -c -g "$(slurp)" "$TEMP_FILE"; then
            swappy -f "$TEMP_FILE" && rm -f "$TEMP_FILE"
        fi
        ;;
    "area-save")
        # Area screenshot directly saved
        FILENAME="$SCREENSHOT_DIR/area_$(date +%Y%m%d_%H%M%S).png"
        if grim -c -g "$(slurp)" "$FILENAME"; then
            wl-copy < "$FILENAME"
            notify-send "📸 Screenshot" "Saved: $(basename "$FILENAME")" -t 2000
        fi
        ;;
    "full-edit")
        # Full screenshot with swappy editor
        TEMP_FILE="/tmp/screenshot_$(date +%s).png"
        if grim -c "$TEMP_FILE"; then
            swappy -f "$TEMP_FILE" && rm -f "$TEMP_FILE"
        fi
        ;;
    "full-save")
        # Full screenshot directly saved
        FILENAME="$SCREENSHOT_DIR/full_$(date +%Y%m%d_%H%M%S).png"
        if grim -c "$FILENAME"; then
            wl-copy < "$FILENAME"
            notify-send "📸 Screenshot" "Saved: $(basename "$FILENAME")" -t 2000
        fi
        ;;
    *)
        echo "Usage: $0 {area-edit|area-save|full-edit|full-save}"
        echo "  area-edit  - Select area and edit with swappy"
        echo "  area-save  - Select area and save to file"
        echo "  full-edit  - Full screen and edit with swappy"
        echo "  full-save  - Full screen and save to file"
        ;;
esac