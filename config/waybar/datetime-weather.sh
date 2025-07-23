#!/bin/bash

# Combined DateTime and Weather script for Waybar
# Displays: 🌤️ 15°C  14:25  Fri Jan 20
# Author: Hyprland Elite Desktop

set -euo pipefail

WEATHER_CACHE_FILE="/tmp/waybar_weather_cache"
CITY_CACHE_FILE="/tmp/waybar_city_cache"
WEATHER_CACHE_DURATION=1800  # 30 minutes
CITY_CACHE_DURATION=86400    # 24 hours
MANUAL_CITY=""  # Set your city, leave empty for auto-detect

# Get city name with caching
get_city() {
    if [ -n "$MANUAL_CITY" ]; then
        echo "$MANUAL_CITY"
        return
    fi
    
    # Check city cache first
    if [[ -f "$CITY_CACHE_FILE" ]]; then
        local cache_time=$(stat -c %Y "$CITY_CACHE_FILE" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $CITY_CACHE_DURATION ]]; then
            cat "$CITY_CACHE_FILE" 2>/dev/null && return
        fi
    fi
    
    # Auto-detect via IP (without proxy)
    local ip_info=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
                    curl -s --connect-timeout 5 --noproxy "*" \
                    "http://ip-api.com/json/?lang=en" 2>/dev/null)
    
    local city="Beijing"  # default fallback
    if [ -n "$ip_info" ]; then
        city=$(echo "$ip_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        if [ -z "$city" ]; then
            city="Beijing"
        fi
    fi
    
    # Cache the city for future use
    echo "$city" > "$CITY_CACHE_FILE"
    echo "$city"
}

# Get weather with caching
get_weather() {
    local current_time=$(date +%s)
    local cache_valid=false
    
    # Check if cache exists and is valid
    if [[ -f "$WEATHER_CACHE_FILE" ]]; then
        local cache_time=$(stat -c %Y "$WEATHER_CACHE_FILE" 2>/dev/null || echo 0)
        local cache_age=$((current_time - cache_time))
        
        if [[ $cache_age -lt $WEATHER_CACHE_DURATION ]]; then
            cache_valid=true
        fi
    fi
    
    # Use cache if valid
    if [[ "$cache_valid" == "true" ]]; then
        cat "$WEATHER_CACHE_FILE" 2>/dev/null || echo "🌤️ --°C"
        return
    fi
    
    # Fetch new weather data
    local city=$(get_city)
    local weather_data=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
                        curl -s --connect-timeout 10 --noproxy "*" \
                        "https://wttr.in/${city}?format=%C+%t&m" 2>/dev/null)
    
    if [[ -n "$weather_data" && "$weather_data" != *"Unknown"* ]]; then
        # Parse weather condition and temperature
        local condition=$(echo "$weather_data" | sed 's/+[0-9-]*°C//' | xargs)
        local temp=$(echo "$weather_data" | grep -o '+[0-9-]*°C' | sed 's/+//')
        
        # Choose icon based on weather condition
        local icon="🌤️"
        case "$condition" in
            *Clear*|*Sunny*) icon="☀️" ;;
            *"Partly cloudy"*) icon="⛅" ;;
            *Cloudy*|*Overcast*) icon="☁️" ;;
            *Rain*|*Drizzle*|*Shower*) icon="🌧️" ;;
            *Snow*|*Blizzard*) icon="❄️" ;;
            *Fog*|*Mist*) icon="🌫️" ;;
            *Thunder*) icon="⛈️" ;;
        esac
        
        local weather_output="$icon $temp"
        echo "$weather_output" > "$WEATHER_CACHE_FILE"
        echo "$weather_output"
    else
        # Fallback weather
        local fallback="🌤️ --°C"
        echo "$fallback" > "$WEATHER_CACHE_FILE"
        echo "$fallback"
    fi
}

# Get current date and time in English
get_datetime() {
    # Format: HH:MM  Day Mon DD
    # Force English locale for date formatting
    local time=$(LC_TIME=C date "+%H:%M")
    local date=$(LC_TIME=C date "+%a %b %d")
    echo "$time  $date"
}

# Main function
main() {
    local weather=$(get_weather)
    local datetime=$(get_datetime)
    
    # Combined output: 🌤️ 15°C  14:25  Fri Jan 20
    local combined="$weather  $datetime"
    
    # Create JSON output for waybar
    local tooltip="Weather: $(get_city)\\nClick: Calendar\\nRight-click: Weather details\\nMiddle-click: Lunar calendar"
    
    echo "{\"text\":\"$combined\", \"tooltip\":\"$tooltip\", \"class\":\"datetime-weather\"}"
}

# Handle different actions
case "${1:-}" in
    "--weather-details")
        # Show detailed weather
        city=$(get_city)
        echo "=== Weather Details for $city ==="
        echo ""
        env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
            curl -s --noproxy "*" "https://wttr.in/${city}?M" 2>/dev/null | head -n 25
        ;;
    "--lunar")
        # Show lunar calendar info
        if command -v lunar &> /dev/null; then
            TODAY=$(date +%Y-%m-%d)
            LUNAR_INFO=$(lunar -d "$TODAY" 2>/dev/null | head -5)
            
            if [ -n "$LUNAR_INFO" ]; then
                notify-send "Lunar Calendar" "$LUNAR_INFO" --icon=calendar --urgency=low -t 8000
            else
                notify-send "Lunar Calendar" "Lunar calendar information not available" --icon=calendar --urgency=low -t 3000
            fi
        else
            notify-send "Lunar Calendar" "Please install 'lunar' package for lunar calendar support" --icon=calendar --urgency=normal -t 5000
        fi
        ;;
    "--calendar")
        # Open calendar application
        if command -v gnome-calendar &> /dev/null; then
            gnome-calendar &
        elif command -v korganizer &> /dev/null; then
            korganizer &
        elif command -v evolution &> /dev/null; then
            evolution --component=calendar &
        else
            notify-send "Calendar" "No calendar application found" --icon=calendar --urgency=normal -t 3000
        fi
        ;;
    *)
        # Default: return formatted datetime-weather
        main
        ;;
esac