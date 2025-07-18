#!/bin/bash

# 测试通知功能的脚本

echo "测试通知功能..."

# 检查 mako 是否在运行
if ! pgrep -x "mako" > /dev/null; then
    echo "启动 mako 通知服务..."
    mako &
    sleep 2
fi

# 发送测试通知
notify-send "swww 配置完成" "壁纸切换功能已就绪！\n\n快捷键：\n• Super + W: 随机切换\n• Super + Shift + W: 手动选择" --icon=image-x-generic --urgency=normal

echo "已发送测试通知"