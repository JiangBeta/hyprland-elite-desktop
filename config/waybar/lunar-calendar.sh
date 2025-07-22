#!/bin/bash

# Lunar Calendar Display Script
# Combine GNOME Calendar and lunar information

# Launch GNOME Calendar
gnome-calendar &

# Display lunar information notification
if command -v lunar &> /dev/null; then
    TODAY=$(date +%Y-%m-%d)
    LUNAR_INFO=$(lunar -d "$TODAY" 2>/dev/null | head -5)
    
    if [ -n "$LUNAR_INFO" ]; then
        notify-send "Lunar Calendar" "$LUNAR_INFO" --icon=calendar --urgency=low
    fi
fi