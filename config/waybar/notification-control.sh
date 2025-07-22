#!/bin/bash

# Notification Center Control Script
# Handle various notification operations

if ! command -v makoctl &>/dev/null; then
    notify-send "Error" "mako not installed or unavailable"
    exit 1
fi

# Check if mako is running
if ! pgrep -x mako > /dev/null; then
    notify-send "Error" "mako is not running"
    exit 1
fi

case "$1" in
    "left"|"restore")
        # Left click: restore recent notifications (only when history exists and no visible notifications)
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        
        if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
            # If there are visible notifications, close them first
            makoctl dismiss --all
            notify-send "Notification" "Closed $VISIBLE_COUNT notifications" -t 2000
        else
            # When no visible notifications, try to restore history notifications
            # Get history notification count, filter system control notifications
            HISTORY_COUNT=$(makoctl history 2>/dev/null | grep -A2 "^Notification" | grep -v "Cleared" | grep -v "No recoverable" | grep -v "Closed" | grep -v "No notifications" | grep -v "Notification mode" | grep -v "Clearing" | grep "^Notification" | wc -l)
            STATE_FILE="$HOME/.cache/mako_restore_state"
            
            if [[ "$HISTORY_COUNT" -gt 0 ]]; then
                # Check if same number of notifications have been restored
                LAST_RESTORED_COUNT=0
                if [[ -f "$STATE_FILE" ]]; then
                    LAST_RESTORED_COUNT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
                fi
                
                if [[ "$HISTORY_COUNT" != "$LAST_RESTORED_COUNT" ]]; then
                makoctl restore
                    echo "$HISTORY_COUNT" > "$STATE_FILE"
                    notify-send "Notification" "Restored recent notifications" -t 2000
                else
                    notify-send "Notification" "No new notifications to restore" -t 2000
                fi
            else
                # Clean state file
                [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
                notify-send "Notification" "No notifications to restore" -t 2000
            fi
        fi
        ;;
    "middle"|"dismiss")
        # Middle click: close all current notifications (does not affect history)
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        
        if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
            makoctl dismiss --all
            notify-send "Notification" "Closed $VISIBLE_COUNT notifications" -t 2000
        else
            notify-send "Notification" "No visible notifications to close" -t 2000
        fi
        ;;
    "right"|"clear")
        # Right click: clear all (current + history)
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        # Get history notification count, filter system control notifications
        HISTORY_COUNT=$(makoctl history 2>/dev/null | grep -A2 "^Notification" | grep -v "已清空" | grep -v "没有可恢复" | grep -v "已关闭" | grep -v "没有通知" | grep -v "通知模式" | grep -v "正在清空" | grep "^Notification" | wc -l)
        
        TOTAL_COUNT=$((VISIBLE_COUNT + HISTORY_COUNT))
        if [[ "$TOTAL_COUNT" -gt 0 ]]; then
            makoctl dismiss --all
            
            # Method to clear history: use temporary config to disable history
            if [[ "$HISTORY_COUNT" -gt 0 ]]; then
                # Create temporary config file to disable history
                TEMP_CONFIG="/tmp/mako_no_history_$$.conf"
                # Add global config at the beginning of config file
                echo "max-history=0" > "$TEMP_CONFIG"
                cat "$HOME/.config/mako/config" >> "$TEMP_CONFIG"
                
                # Reload configuration
                pkill mako
                sleep 0.3
                mako -c "$TEMP_CONFIG" &
                sleep 0.5
                
                # Restore original configuration
                pkill mako
                sleep 0.3
                mako &
                sleep 0.3
                
                # Clean temporary files
                rm -f "$TEMP_CONFIG"
                
                # No longer show notifications to avoid infinite loop
                echo "Cleared all notifications ($TOTAL_COUNT items)" >&2
            else
                notify-send "Notification" "Closed all notifications ($VISIBLE_COUNT items)" -t 2000
            fi
            
            # 清理状态文件
            STATE_FILE="$HOME/.cache/mako_restore_state"
            [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
        else
            notify-send "Notification" "No notifications to clear" -t 2000
        fi
        ;;
    "toggle_mode")
        # Toggle notification mode (do not disturb/normal)
        if [[ -f "$HOME/.config/mako/do_not_disturb" ]]; then
            rm "$HOME/.config/mako/do_not_disturb"
            makoctl reload
            notify-send "Notification Mode" "Normal mode" -t 2000
        else
            touch "$HOME/.config/mako/do_not_disturb"
            makoctl reload
            notify-send "Notification Mode" "Do not disturb mode" -t 2000
        fi
        ;;
    *)
        echo "Usage: $0 {left|middle|right|toggle_mode}"
        echo "  left   - Smart operation: close if notifications exist, restore if none"
        echo "  middle - Close current visible notifications"
        echo "  right  - Clear all notifications (current + history)"
        echo "  toggle_mode - Toggle do not disturb mode"
        exit 1
        ;;
esac

# Update waybar display
pkill -SIGRTMIN+7 waybar 2>/dev/null || true
