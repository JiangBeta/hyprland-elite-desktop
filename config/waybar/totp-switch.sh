#!/bin/bash

# TOTP服务切换脚本
CONFIG_FILE="$HOME/.config/totp/secrets.conf"
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "TOTP" "配置文件不存在: $CONFIG_FILE" -u critical
    exit 1
fi

# 获取所有服务
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    notify-send "TOTP" "未找到有效配置" -u critical
    exit 1
fi

# 获取总服务数量
total_services=$(echo "$all_services" | wc -l)

# 获取当前索引
if [ -f "$CURRENT_INDEX_FILE" ]; then
    current_index=$(cat "$CURRENT_INDEX_FILE")
else
    current_index=1
fi

# 切换到下一个服务
next_index=$((current_index + 1))
if [ "$next_index" -gt "$total_services" ]; then
    next_index=1
fi

# 保存新索引
echo "$next_index" > "$CURRENT_INDEX_FILE"

# 获取新服务名称
new_service=$(echo "$all_services" | sed -n "${next_index}p" | cut -d':' -f1)

# 发送通知
notify-send "TOTP" "已切换到: $new_service ($next_index/$total_services)" -t 2000

# 刷新waybar显示
pkill -RTMIN+8 waybar