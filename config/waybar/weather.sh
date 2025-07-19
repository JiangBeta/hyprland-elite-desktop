#!/bin/bash

# 天气脚本 - 使用中国天气API
# 手动设置城市，如果不设置则自动获取
MANUAL_CITY="诸城"  # 设置你的城市，留空则自动获取

# 获取城市名称
get_city() {
    # 如果手动设置了城市，直接使用
    if [ -n "$MANUAL_CITY" ]; then
        echo "$MANUAL_CITY"
        return
    fi
    
    # 否则通过IP自动获取（不使用代理）
    local ip_info=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "http://ip-api.com/json/?lang=zh-CN" 2>/dev/null)
    if [ -n "$ip_info" ]; then
        echo "$ip_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4
    else
        echo "北京"
    fi
}

# 使用免费的天气API
get_weather_simple() {
    local city=$(get_city)
    
    # 在子shell中禁用代理，不影响父shell
    local backup_weather=$(env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "https://wttr.in/${city}?lang=zh&format=%C+%t&m" 2>/dev/null)
    if [ -n "$backup_weather" ]; then
        # 根据天气状况选择图标
        local icon="🌤️"
        case "$backup_weather" in
            *晴*|*Sunny*) icon="☀️" ;;
            *多云*|*Cloudy*) icon="⛅" ;;
            *阴*|*Overcast*) icon="☁️" ;;
            *雨*|*Rain*) icon="🌧️" ;;
            *雪*|*Snow*) icon="❄️" ;;
            *雾*|*Fog*) icon="🌫️" ;;
        esac
        echo "$icon $backup_weather"
    else
        echo "🌤️ 获取天气失败"
    fi
}

# 获取详细天气信息
get_weather_detailed() {
    local city=$(get_city)
    echo "=== 天气详情 ==="
    echo "位置: $city"
    echo ""
    
    # 在子shell中禁用代理，不影响父shell
    echo "获取详细天气信息..."
    env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY curl -s --noproxy "*" "https://wttr.in/${city}?lang=zh&M" 2>/dev/null | head -n 25
}

if [ "$1" = "--detailed" ]; then
    get_weather_detailed
else
    get_weather_simple
fi