#!/bin/bash

# Weather script - Using weather API
# Manually set city, auto-detect if not set
MANUAL_CITY="Zhucheng"  # Set your city, leave empty for auto-detect

# Get city name
get_city() {
    # If city is manually set, use it directly
    if [ -n "$MANUAL_CITY" ]; then
        echo "$MANUAL_CITY"
        return
    fi
    
    # Otherwise auto-detect via IP (without proxy)
    local ip_info=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "http://ip-api.com/json/?lang=en" 2>/dev/null)
    if [ -n "$ip_info" ]; then
        echo "$ip_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4
    else
        echo "Beijing"
    fi
}

# Use free weather API
get_weather_simple() {
    local city=$(get_city)
    
    # Disable proxy in subshell, doesn't affect parent shell
    local backup_weather=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "https://wttr.in/${city}?format=%C+%t&m" 2>/dev/null)
    if [ -n "$backup_weather" ]; then
        # Choose icon based on weather condition
        local icon="🌤️"
        case "$backup_weather" in
            *Clear*|*Sunny*) icon="☀️" ;;
            *Partly*|*Cloudy*) icon="⛅" ;;
            *Overcast*) icon="☁️" ;;
            *Rain*|*Drizzle*) icon="🌧️" ;;
            *Snow*) icon="❄️" ;;
            *Fog*|*Mist*) icon="🌫️" ;;
        esac
        echo "$icon $backup_weather"
    else
        echo "🌤️ Weather unavailable"
    fi
}

# Get detailed weather information
get_weather_detailed() {
    local city=$(get_city)
    echo "=== Weather Details ==="
    echo "Location: $city"
    echo ""
    
    # Disable proxy in subshell, doesn't affect parent shell
    echo "Getting detailed weather information..."
    env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "https://wttr.in/${city}?M" 2>/dev/null | head -n 25
}

if [ "$1" = "--detailed" ]; then
    get_weather_detailed
else
    get_weather_simple
fi