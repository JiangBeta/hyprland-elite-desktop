#!/bin/bash

# 农历日历显示脚本
# 结合 GNOME Calendar 和农历信息

# 启动 GNOME Calendar
gnome-calendar &

# 显示农历信息通知
if command -v lunar &> /dev/null; then
    TODAY=$(date +%Y-%m-%d)
    LUNAR_INFO=$(lunar -d "$TODAY" 2>/dev/null | head -5)
    
    if [ -n "$LUNAR_INFO" ]; then
        notify-send "农历信息" "$LUNAR_INFO" --icon=calendar --urgency=low
    fi
fi