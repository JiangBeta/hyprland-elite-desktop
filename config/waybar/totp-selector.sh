#!/bin/bash

# TOTP服务选择器弹窗
CONFIG_FILE="$HOME/.config/totp/secrets.conf"
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "TOTP" "配置文件不存在" -u critical
    exit 1
fi

# 获取所有服务
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    notify-send "TOTP" "未找到有效配置" -u critical
    exit 1
fi

# 使用wofi创建选择菜单
selected=$(echo "$all_services" | cut -d':' -f1 | wofi \
    --dmenu \
    --prompt "选择TOTP服务:" \
    --height 300 \
    --width 400 \
    --cache-file=/dev/null \
    --style="$HOME/.config/waybar/totp-wofi.css" \
    --location=top_right)

if [ -n "$selected" ]; then
    # 找到选中服务的索引
    service_index=$(echo "$all_services" | cut -d':' -f1 | grep -n "^$selected$" | cut -d':' -f1)
    
    if [ -n "$service_index" ]; then
        # 保存新索引
        echo "$service_index" > "$CURRENT_INDEX_FILE"
        
        # 获取验证码并复制
        secret_key=$(echo "$all_services" | sed -n "${service_index}p" | cut -d':' -f2)
        if command -v oathtool >/dev/null 2>&1; then
            totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$totp_code" ]; then
                echo -n "$totp_code" | wl-copy
                
                # 获取剩余时间
                current_time=$(date +%s)
                remaining=$((30 - (current_time % 30)))
                
                notify-send "TOTP" "$selected: $totp_code\n剩余时间: ${remaining}秒\n已复制到剪贴板" -t 4000
                
                # 刷新waybar
                pkill -RTMIN+8 waybar
            else
                notify-send "TOTP" "生成验证码失败" -u critical
            fi
        else
            notify-send "TOTP" "请安装oath-toolkit" -u critical
        fi
    fi
fi