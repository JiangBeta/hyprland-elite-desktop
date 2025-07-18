#!/bin/bash

# Screenshot script for Hyprland with swappy
# Similar to WeChat screenshot experience

TEMP_FILE="/tmp/screenshot_$(date +%Y%m%d_%H%M%S).png"

case "$1" in
    "area")
        # Take area screenshot
        grim -g "$(slurp)" "$TEMP_FILE"
        ;;
    "full")
        # Take full screen screenshot
        grim "$TEMP_FILE"
        ;;
    *)
        echo "Usage: $0 {area|full}"
        exit 1
        ;;
esac

# Check if screenshot was taken successfully
if [ -f "$TEMP_FILE" ]; then
    # Open with swappy for editing
    swappy -f "$TEMP_FILE" -o "$TEMP_FILE"
    
    # If swappy saved the file, copy to clipboard
    if [ -f "$TEMP_FILE" ]; then
        wl-copy < "$TEMP_FILE"
        notify-send "Screenshot" "Screenshot copied to clipboard" -i "$TEMP_FILE"
        # Clean up temp file after 10 seconds
        (sleep 10 && rm -f "$TEMP_FILE") &
    fi
else
    notify-send "Screenshot" "Failed to take screenshot" -u critical
fi