#!/bin/bash

# TOTP Copy Script - Copy current TOTP code to clipboard
# Uses shared TOTP library for common functionality

set -euo pipefail

# Load TOTP common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/totp-common.sh"

# Validate configuration
if ! validate_totp_config; then
    notify-send "TOTP" "Configuration file not found or empty" -u critical
    exit 1
fi

# Get current service information
current_index=$(get_current_index)
service_info=$(get_service_info "$current_index")

if [[ -z "$service_info" ]]; then
    notify-send "TOTP" "Invalid service configuration" -u critical
    exit 1
fi

service_name=$(echo "$service_info" | cut -d':' -f1)
secret_key=$(echo "$service_info" | cut -d':' -f2)

# Generate TOTP code and copy to clipboard
totp_code=$(generate_totp_code "$secret_key")
case $? in
    0)
        # Success - copy to clipboard
        echo -n "$totp_code" | wl-copy
        
        # Get remaining time and show notification
        remaining=$(get_totp_remaining_time)
        notify-send "TOTP" "$service_name: $totp_code\nRemaining: ${remaining}s\nCopied to clipboard" -t 4000
        ;;
    2)
        notify-send "TOTP" "Please install oath-toolkit: sudo pacman -S oath-toolkit" -u critical
        ;;
    3)
        notify-send "TOTP" "Invalid TOTP key format for $service_name" -u critical
        ;;
    *)
        notify-send "TOTP" "Failed to generate TOTP code for $service_name" -u critical
        ;;
esac