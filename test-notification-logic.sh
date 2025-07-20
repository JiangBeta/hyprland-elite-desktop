#!/bin/bash

echo "=== 通知控制逻辑测试 ==="

# 检查 mako 是否运行
if ! pgrep -x mako > /dev/null; then
    echo "❌ mako 未运行，请先启动 mako"
    exit 1
fi

echo "✅ mako 运行中"

# 显示当前状态
echo ""
echo "📊 当前状态:"
./config/waybar/notification.sh

echo ""
echo "🧪 测试场景:"
echo "1. 发送测试通知"
notify-send "测试" "这是一条测试通知" -t 5000

sleep 1
echo "   状态:" 
./config/waybar/notification.sh

echo ""
echo "2. 测试左键操作（有通知时关闭）"
./config/waybar/notification-control.sh left

sleep 1
echo "   状态:" 
./config/waybar/notification.sh

echo ""
echo "3. 测试左键操作（无通知时恢复）"
./config/waybar/notification-control.sh left

sleep 1
echo "   状态:" 
./config/waybar/notification.sh

echo ""
echo "4. 测试右键操作（清空所有）"
./config/waybar/notification-control.sh right

sleep 1
echo "   状态:" 
./config/waybar/notification.sh

echo ""
echo "=== 测试完成 ==="
