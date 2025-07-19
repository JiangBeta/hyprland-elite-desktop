#!/bin/bash

# TOTP复制脚本
CONFIG_FILE="$HOME/.config/totp/secrets.conf"
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "TOTP" "配置文件不存在: $CONFIG_FILE" -u critical
    exit 1
fi

# 获取所有配置的服务
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    notify-send "TOTP" "未找到有效配置" -u critical
    exit 1
fi

# 获取当前选中的服务索引
if [ -f "$CURRENT_INDEX_FILE" ]; then
    current_index=$(cat "$CURRENT_INDEX_FILE")
else
    current_index=1
fi

# 获取总服务数量
total_services=$(echo "$all_services" | wc -l)

# 确保索引在有效范围内
if [ "$current_index" -gt "$total_services" ] || [ "$current_index" -lt 1 ]; then
    current_index=1
fi

# 获取当前服务
service_line=$(echo "$all_services" | sed -n "${current_index}p")
service_name=$(echo "$service_line" | cut -d':' -f1)
secret_key=$(echo "$service_line" | cut -d':' -f2)

# 生成TOTP代码并复制到剪贴板
if command -v oathtool >/dev/null 2>&1; then
    totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$totp_code" ]; then
        # 复制到剪贴板
        echo -n "$totp_code" | wl-copy
        
        # 获取剩余时间
        current_time=$(date +%s)
        remaining=$((30 - (current_time % 30)))
        
        # 发送通知
        notify-send "TOTP已复制" "$service_name: $totp_code\n剩余时间: ${remaining}秒" -t 3000
        
        # 刷新waybar显示
        pkill -RTMIN+8 waybar
    else
        notify-send "TOTP错误" "无法生成验证码" -u critical
    fi
else
    notify-send "TOTP错误" "请安装oath-toolkit" -u critical
fi