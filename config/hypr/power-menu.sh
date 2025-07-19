#!/bin/bash

# Hyprland power management menu
# Uses wofi to display power options

# Check if required tools are installed
if ! command -v wofi &> /dev/null; then
    notify-send "Error" "wofi is required" --urgency=critical
    exit 1
fi

# Power options
options="🔒 Lock
😴 Sleep
🔄 Restart
⚡ Shutdown
🚪 Exit Hyprland
❌ Cancel"

# Show menu and get selection
selected=$(echo "$options" | wofi --dmenu --prompt "Power Menu" --width 300 --height 400)

# Execute action based on selection
case $selected in
    "🔒 Lock")
        # Check if lock screen tool is installed
        if command -v swaylock &> /dev/null; then
            swaylock -f -c 000000
        elif command -v hyprlock &> /dev/null; then
            hyprlock
        else
            notify-send "Error" "No lock screen tool installed (swaylock/hyprlock)" --urgency=critical
        fi
        ;;
    "😴 Sleep")
        notify-send "System" "Suspending..." --urgency=normal
        sleep 1
        systemctl suspend
        ;;
    "🔄 Restart")
        notify-send "System" "Restarting..." --urgency=normal
        sleep 1
        systemctl reboot
        ;;
    "⚡ Shutdown")
        notify-send "System" "Shutting down..." --urgency=normal
        sleep 1
        systemctl poweroff
        ;;
    "🚪 Exit Hyprland")
        notify-send "System" "Exiting Hyprland..." --urgency=normal
        sleep 1
        hyprctl dispatch exit
        ;;
    "❌ Cancel")
        # Do nothing
        ;;
esac