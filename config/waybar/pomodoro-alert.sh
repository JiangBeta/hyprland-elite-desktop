#!/bin/bash

# Pomodoro Timer Force Alert Script
# Display fullscreen alerts when time is reached

show_alert() {
    local title="$1"
    local message="$2"
    local type="$3"  # work_end, break_end
    
    # Play more intense alert sound sequence
    for i in {1..3}; do
        pactl load-module module-sine frequency=1000 > /dev/null 2>&1
        sleep 0.3
        pactl unload-module module-sine > /dev/null 2>&1
        sleep 0.1
        pactl load-module module-sine frequency=800 > /dev/null 2>&1
        sleep 0.3
        pactl unload-module module-sine > /dev/null 2>&1
        sleep 0.2
    done
    
    # Display large notification and flash screen
    notify-send -u critical -t 15000 -i appointment-soon "$title" "$message\n\nClick to choose next action"
    
    # Screen flash effect
    for i in {1..5}; do
        brightnessctl set 100% > /dev/null 2>&1
        sleep 0.1
        brightnessctl set 50% > /dev/null 2>&1
        sleep 0.1
    done
    brightnessctl set 100% > /dev/null 2>&1
    
    # Use wofi to display fullscreen selection
    case "$type" in
        "work_end")
            choice=$(echo -e "Start Break\nContinue Work\nSkip Break" | wofi --dmenu --prompt="🍅 Work Time Ended!" --width=400 --height=200)
            case "$choice" in
                "Start Break")
                    # Auto enter break mode (already handled in main script)
                    ;;
                "Continue Work")
                    ~/.config/waybar/pomodoro-control.sh skip
                    ~/.config/waybar/pomodoro-control.sh toggle
                    ;;
                "Skip Break")
                    ~/.config/waybar/pomodoro-control.sh skip
                    ;;
            esac
            ;;
        "break_end")
            choice=$(echo -e "Start Work\nExtend Break" | wofi --dmenu --prompt="😴 Break Ended!" --width=400 --height=200)
            case "$choice" in
                "Start Work")
                    # Auto enter work mode (already handled in main script)
                    ;;
                "Extend Break")
                    ~/.config/waybar/pomodoro-control.sh stop
                    ;;
            esac
            ;;
    esac
}

# Call corresponding alert based on parameters
case "$1" in
    "work_end")
        show_alert "🍅 Pomodoro Timer" "Work time ended! Time to take a break" "work_end"
        ;;
    "break_end")
        show_alert "😴 Break Time" "Break ended! Ready to start new pomodoro" "break_end"
        ;;
    *)
        echo "Usage: $0 {work_end|break_end}"
        exit 1
        ;;
esac