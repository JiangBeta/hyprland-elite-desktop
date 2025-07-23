#!/bin/bash

# ===========================================
# TOTP Common Library
# ===========================================
# 共享TOTP功能函数，减少代码重复

# 配置文件路径
TOTP_CONFIG_FILE="$HOME/.config/totp/secrets.conf"
TOTP_CURRENT_INDEX_FILE="$HOME/.config/totp/current_index"

# 初始化TOTP配置目录
init_totp_config() {
    # 确保配置目录存在且权限正确
    local config_dir=$(dirname "$TOTP_CONFIG_FILE")
    mkdir -p "$config_dir"
    chmod 700 "$config_dir"
    
    # 如果配置文件不存在，创建示例文件
    if [[ ! -f "$TOTP_CONFIG_FILE" ]]; then
        cat > "$TOTP_CONFIG_FILE" << 'EOF'
# TOTP key configuration file
# Format: service_name:key
# Example:
# Google:JBSWY3DPEHPK3PXP
# GitHub:ABCDEFGHIJKLMNOP
# Please replace with your actual keys

EOF
        chmod 600 "$TOTP_CONFIG_FILE"
        return 1  # Indicate config needs to be edited
    fi
    return 0
}

# 验证TOTP配置
validate_totp_config() {
    if [[ ! -f "$TOTP_CONFIG_FILE" ]] || [[ ! -s "$TOTP_CONFIG_FILE" ]]; then
        return 1
    fi
    
    # 检查是否有有效的服务配置
    local services=$(grep -v "^#" "$TOTP_CONFIG_FILE" | grep ":")
    [[ -n "$services" ]]
}

# 获取所有TOTP服务
get_totp_services() {
    if ! validate_totp_config; then
        return 1
    fi
    
    grep -v "^#" "$TOTP_CONFIG_FILE" | grep ":"
}

# 获取当前选中的服务索引
get_current_index() {
    local current_index=1
    
    if [[ -f "$TOTP_CURRENT_INDEX_FILE" ]]; then
        current_index=$(cat "$TOTP_CURRENT_INDEX_FILE" 2>/dev/null || echo 1)
    fi
    
    # 验证索引范围
    local total_services=$(get_totp_services | wc -l)
    if [[ "$current_index" -gt "$total_services" ]] || [[ "$current_index" -lt 1 ]]; then
        current_index=1
        echo "$current_index" > "$TOTP_CURRENT_INDEX_FILE"
    fi
    
    echo "$current_index"
}

# 设置当前服务索引
set_current_index() {
    local index="$1"
    local total_services=$(get_totp_services | wc -l)
    
    # 验证索引范围
    if [[ "$index" -gt "$total_services" ]] || [[ "$index" -lt 1 ]]; then
        return 1
    fi
    
    echo "$index" > "$TOTP_CURRENT_INDEX_FILE"
    return 0
}

# 获取指定索引的服务信息
get_service_info() {
    local index="$1"
    local services=$(get_totp_services)
    
    if [[ -z "$services" ]]; then
        return 1
    fi
    
    local service_line=$(echo "$services" | sed -n "${index}p")
    if [[ -z "$service_line" ]]; then
        return 1
    fi
    
    local service_name=$(echo "$service_line" | cut -d':' -f1)
    local secret_key=$(echo "$service_line" | cut -d':' -f2)
    
    # 验证密钥格式（Base32）
    if ! validate_totp_key "$secret_key"; then
        return 1
    fi
    
    echo "$service_name:$secret_key"
}

# 验证TOTP密钥格式
validate_totp_key() {
    local key="$1"
    # 验证Base32格式：只包含A-Z和2-7，可能以=结尾
    [[ "$key" =~ ^[A-Z2-7]+=*$ ]] && [[ ${#key} -ge 16 ]]
}

# 生成TOTP代码
generate_totp_code() {
    local secret_key="$1"
    
    if ! command -v oathtool >/dev/null 2>&1; then
        return 2  # oathtool not installed
    fi
    
    if ! validate_totp_key "$secret_key"; then
        return 3  # invalid key format
    fi
    
    local totp_code=$(oathtool --totp -b "$secret_key" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$totp_code" ]]; then
        echo "$totp_code"
        return 0
    else
        return 1  # generation failed
    fi
}

# 获取TOTP代码剩余时间
get_totp_remaining_time() {
    local current_time=$(date +%s)
    local time_window=30
    echo $((time_window - (current_time % time_window)))
}

# 获取时间颜色类别
get_time_color_class() {
    local remaining="$1"
    
    if [[ $remaining -le 5 ]]; then
        echo "critical"
    elif [[ $remaining -le 10 ]]; then
        echo "warning"
    else
        echo "normal"
    fi
}

# 生成服务列表（用于tooltip）
generate_services_list() {
    local current_index="$1"
    local services=$(get_totp_services)
    local services_list=""
    local i=1
    
    while IFS= read -r line; do
        local svc_name=$(echo "$line" | cut -d':' -f1)
        if [[ $i -eq $current_index ]]; then
            services_list="${services_list}▶ $svc_name (current)\\n"
        else
            services_list="${services_list}  $svc_name\\n"
        fi
        i=$((i + 1))
    done <<< "$services"
    
    echo "$services_list"
}

# 切换到下一个服务
switch_to_next_service() {
    local current_index=$(get_current_index)
    local total_services=$(get_totp_services | wc -l)
    local next_index=$((current_index + 1))
    
    if [[ "$next_index" -gt "$total_services" ]]; then
        next_index=1
    fi
    
    set_current_index "$next_index"
    echo "$next_index"
}

# 刷新waybar
refresh_waybar() {
    pkill -RTMIN+8 waybar 2>/dev/null
}

# 错误处理函数
totp_error_message() {
    local error_code="$1"
    local context="$2"
    
    case "$error_code" in
        1) echo '{"text": "🔐 Not Configured", "tooltip": "Please edit ~/.config/totp/secrets.conf to add TOTP keys"}';;
        2) echo '{"text": "🔐 Not Installed", "tooltip": "Please install oath-toolkit: sudo pacman -S oath-toolkit"}';;
        3) echo '{"text": "🔐 Invalid Key", "tooltip": "Invalid TOTP key format in configuration"}';;
        *) echo '{"text": "🔐 Error", "tooltip": "TOTP generation failed, please check configuration"}';;
    esac
}