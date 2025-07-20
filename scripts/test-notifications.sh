#!/bin/bash
# 统一通知系统测试脚本

echo "测试统一通知系统..."

# 测试基本通知
notify-send "系统测试" "基本通知功能正常" --app-name="Test"

sleep 2

# 测试系统通知样式
notify-send "系统通知" "这是一个测试通知" --app-name="系统" --icon=dialog-information

sleep 2

# 测试日历通知样式
notify-send "日历提醒" "会议将在15分钟后开始" --app-name="KOrganizer" --icon=appointment-new

sleep 2

# 测试农历日历
if command -v lunarcalendar-bin &> /dev/null; then
    notify-send "农历信息" "今日农历: $(date '+%Y年%m月%d日')" --app-name="Calendar" --icon=x-office-calendar
fi

echo "通知测试完成！检查右上角通知区域。"