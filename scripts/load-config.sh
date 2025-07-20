#!/bin/bash

# 配置文件加载器
# 用于加载用户配置文件 .env.local

# 配置文件路径
CONFIG_FILE="$HOME/dotfiles/.env.local"

# 如果配置文件存在则加载
if [[ -f "$CONFIG_FILE" ]]; then
    # 安全地加载配置文件，只处理格式正确的环境变量
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # 移除引号并设置环境变量
        value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')
        export "$key=$value"
    done < <(grep -E '^[A-Z_][A-Z0-9_]*=' "$CONFIG_FILE")
fi