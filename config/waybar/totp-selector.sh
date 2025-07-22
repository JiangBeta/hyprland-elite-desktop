#!/bin/bash

# TOTP Service Selector Dialog
CONFIG_FILE="$HOME/.config/totp/secrets.conf"
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"

# Check configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "TOTP" "Configuration file not found" -u critical
    exit 1
fi

# Get all services
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    notify-send "TOTP" "No valid configuration found" -u critical
    exit 1
fi

# Create selection menu with wofi
selected=$(echo "$all_services" | cut -d':' -f1 | wofi \
    --dmenu \
    --prompt "Select TOTP Service:" \
    --height 300 \
    --width 400 \
    --cache-file=/dev/null \
    --style="$HOME/.config/waybar/totp-wofi.css" \
    --location=top_right)

if [ -n "$selected" ]; then
    # Find index of selected service
    service_index=$(echo "$all_services" | cut -d':' -f1 | grep -n "^$selected$" | cut -d':' -f1)
    
    if [ -n "$service_index" ]; then
        # Save new index
        echo "$service_index" > "$CURRENT_INDEX_FILE"
        
        # Get verification code and copy
        secret_key=$(echo "$all_services" | sed -n "${service_index}p" | cut -d':' -f2)
        if command -v oathtool >/dev/null 2>&1; then
            totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$totp_code" ]; then
                echo -n "$totp_code" | wl-copy
                
                # Get remaining time
                current_time=$(date +%s)
                remaining=$((30 - (current_time % 30)))
                
                notify-send "TOTP" "$selected: $totp_code\nRemaining: ${remaining}s\nCopied to clipboard" -t 4000
                
                # Refresh waybar
                pkill -RTMIN+8 waybar
            else
                notify-send "TOTP" "Failed to generate verification code" -u critical
            fi
        else
            notify-send "TOTP" "Please install oath-toolkit" -u critical
        fi
    fi
fi