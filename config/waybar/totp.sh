#!/bin/bash

# TOTP脚本用于waybar显示
# 需要先安装: sudo pacman -S oath-toolkit

# 配置文件路径 - 存储TOTP密钥
CONFIG_FILE="$HOME/.config/totp/secrets.conf"

# 确保配置目录存在
mkdir -p "$(dirname "$CONFIG_FILE")"

# 如果配置文件不存在，创建示例文件
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# TOTP密钥配置文件
# 格式: 服务名称:密钥
# 示例:
# Google:JBSWY3DPEHPK3PXP
# GitHub:ABCDEFGHIJKLMNOP
# 请将此处替换为您的实际密钥

EOF
    echo "请编辑 $CONFIG_FILE 添加您的TOTP密钥"
    exit 1
fi

# 读取配置文件
if [ ! -s "$CONFIG_FILE" ]; then
    echo '{"text": "🔐 未配置", "tooltip": "请编辑 ~/.config/totp/secrets.conf 添加TOTP密钥"}'
    exit 0
fi

# 获取所有配置的服务
all_services=$(grep -v "^#" "$CONFIG_FILE" | grep ":")
if [ -z "$all_services" ]; then
    echo '{"text": "🔐 未配置", "tooltip": "请编辑 ~/.config/totp/secrets.conf 添加TOTP密钥"}'
    exit 0
fi

# 获取当前选中的服务索引
CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"
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

# 生成TOTP代码
if command -v oathtool >/dev/null 2>&1; then
    totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$totp_code" ]; then
        # 获取当前时间戳和剩余时间
        current_time=$(date +%s)
        time_window=30
        remaining=$((time_window - (current_time % time_window)))
        
        # 根据剩余时间改变显示颜色
        if [ $remaining -le 5 ]; then
            color_class="critical"
        elif [ $remaining -le 10 ]; then
            color_class="warning"
        else
            color_class="normal"
        fi
        
        # 生成服务列表用于tooltip
        services_list=""
        i=1
        while IFS= read -r line; do
            svc_name=$(echo "$line" | cut -d':' -f1)
            if [ $i -eq $current_index ]; then
                services_list="${services_list}▶ $svc_name (当前)\\n"
            else
                services_list="${services_list}  $svc_name\\n"
            fi
            i=$((i + 1))
        done <<< "$all_services"
        
        # 显示当前服务和验证码，以及所有可用服务
        printf '{"text": "🔐 %s", "tooltip": "%s TOTP: %s\\n剩余时间: %d秒\\n\\n可用服务 (%d/%d):\\n%s\\n左键: 复制验证码\\n右键: 切换服务", "class": "%s"}\n' \
            "$service_name" "$service_name" "$totp_code" "$remaining" "$current_index" "$total_services" "$services_list" "$color_class"
    else
        echo '{"text": "🔐 错误", "tooltip": "TOTP生成失败，请检查密钥配置"}'
    fi
else
    echo '{"text": "🔐 未安装", "tooltip": "请安装oath-toolkit: sudo pacman -S oath-toolkit"}'
fi