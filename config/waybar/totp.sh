#!/bin/bash

# TOTP script for waybar display
# Uses shared TOTP library for common functionality

set -euo pipefail

# Load TOTP common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/totp-common.sh"

# Initialize TOTP configuration
if ! init_totp_config; then
    totp_error_message 1
    exit 1
fi

# Validate configuration
if ! validate_totp_config; then
    totp_error_message 1
    exit 0
fi

# Get current service information
current_index=$(get_current_index)
service_info=$(get_service_info "$current_index")

if [[ -z "$service_info" ]]; then
    totp_error_message 3
    exit 0
fi

service_name=$(echo "$service_info" | cut -d':' -f1)
secret_key=$(echo "$service_info" | cut -d':' -f2)

# Generate TOTP code
totp_code=$(generate_totp_code "$secret_key")
case $? in
    0)
        # Success - display the code
        remaining=$(get_totp_remaining_time)
        color_class=$(get_time_color_class "$remaining")
        
        # Get service information for tooltip
        total_services=$(get_totp_services | wc -l)
        services_list=$(generate_services_list "$current_index")
        
        # Display current service and verification code
        printf '{"text": "🔐 %s", "tooltip": "%s TOTP: %s\\nRemaining: %d seconds\\n\\nAvailable services (%d/%d):\\n%s\\nLeft click: Copy code\\nRight click: Switch service", "class": "%s"}\n' \
            "$service_name" "$service_name" "$totp_code" "$remaining" "$current_index" "$total_services" "$services_list" "$color_class"
        ;;
    2)
        totp_error_message 2
        ;;
    3)
        totp_error_message 3
        ;;
    *)
        totp_error_message 4
        ;;
esac