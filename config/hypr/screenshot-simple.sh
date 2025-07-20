#!/bin/bash

# Simple and fast screenshot script
# Optimized for responsiveness

# Kill any existing screenshot processes
pkill -f "slurp\|swappy\|grim" 2>/dev/null

case "$1" in
    "area")
        # Simple area screenshot
        grim -g "$(slurp)" - | wl-copy
        notify-send "Screenshot" "Area copied to clipboard" -t 2000
        ;;
    "full")
        # Simple full screenshot
        grim - | wl-copy
        notify-send "Screenshot" "Screen copied to clipboard" -t 2000
        ;;
    *)
        echo "Usage: $0 {area|full}"
        exit 1
        ;;
esac