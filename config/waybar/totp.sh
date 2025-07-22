#!/bin/bash

# TOTP script for waybar display
# Install first: sudo pacman -S oath-toolkit

# Configuration file path - store TOTP keys
CONFIG_FILE="$HOME/.config/totp/secrets.conf"

# Ensure configuration directory exists
mkdir -p "$(dirname "$CONFIG_FILE")"

# If config file doesn't exist, create sample file
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# TOTP key configuration file
# Format: service_name:key
# Example:
# Google:JBSWY3DPEHPK3PXP
# GitHub:ABCDEFGHIJKLMNOP
# Please replace with your actual keys

EOF
    echo "Please edit $CONFIG_FILE to add your TOTP keys"
    exit 1
fi

# Read configuration file
if [ ! -s "$CONFIG_FILE" ]; then
    echo '{"text": "🔐 Not Configured", "tooltip": "Please edit ~/.config/totp/secrets.conf to add TOTP keys"}'
    exit 0
fi

# Get all configured services
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    echo '{"text": "🔐 Not Configured", "tooltip": "Please edit ~/.config/totp/secrets.conf to add TOTP keys"}'
    exit 0
fi

# Get current selected service index
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"
if [ -f "$CURRENT_INDEX_FILE" ]; then
    current_index=$(cat "$CURRENT_INDEX_FILE")
else
    current_index=1
fi

# Get total service count
total_services=$(echo "$all_services" | wc -l)

# Ensure index is within valid range
if [ "$current_index" -gt "$total_services" ] || [ "$current_index" -lt 1 ]; then
    current_index=1
fi

# Get current service
service_line=$(echo "$all_services" | sed -n "${current_index}p")
service_name=$(echo "$service_line" | cut -d':' -f1)
secret_key=$(echo "$service_line" | cut -d':' -f2)

# Generate TOTP code
if command -v oathtool >/dev/null 2>&1; then
    totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$totp_code" ]; then
        # Get current timestamp and remaining time
        current_time=$(date +%s)
        time_window=30
        remaining=$((time_window - (current_time % time_window)))
        
        # Change display color based on remaining time
        if [ $remaining -le 5 ]; then
            color_class="critical"
        elif [ $remaining -le 10 ]; then
            color_class="warning"
        else
            color_class="normal"
        fi
        
        # Generate service list for tooltip
        services_list=""
        i=1
        while IFS= read -r line; do
            svc_name=$(echo "$line" | cut -d':' -f1)
            if [ $i -eq $current_index ]; then
                services_list="${services_list}▶ $svc_name (current)\\n"
            else
                services_list="${services_list}  $svc_name\\n"
            fi
            i=$((i + 1))
        done <<< "$all_services"
        
        # Display current service and verification code, and all available services
        printf '{"text": "🔐 %s", "tooltip": "%s TOTP: %s\\nRemaining: %d seconds\\n\\nAvailable services (%d/%d):\\n%s\\nLeft click: Copy code\\nRight click: Switch service", "class": "%s"}\n' \
            "$service_name" "$service_name" "$totp_code" "$remaining" "$current_index" "$total_services" "$services_list" "$color_class"
    else
        echo '{"text": "🔐 Error", "tooltip": "TOTP generation failed, please check key configuration"}'
    fi
else
    echo '{"text": "🔐 Not Installed", "tooltip": "Please install oath-toolkit: sudo pacman -S oath-toolkit"}'
fi