#!/bin/bash

# ==============================================================================
# 动态代理环境变量生成脚本
# ==============================================================================
# 根据.env.local配置动态生成Hyprland代理环境变量配置
# ==============================================================================

set -e

# 获取脚本目录和dotfiles根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_LOCAL_FILE="$DOTFILES_DIR/.env.local"
PROXY_ENV_FILE="$HOME/.config/hypr/proxy-env.conf"

# 加载.env.local配置
if [[ -f "$ENV_LOCAL_FILE" ]]; then
    source "$ENV_LOCAL_FILE"
else
    echo "错误: 未找到 .env.local 配置文件" >&2
    exit 1
fi

# 生成代理环境变量配置文件
generate_proxy_config() {
    local config_content=""
    
    if [[ "${ENABLE_PROXY:-false}" == "true" ]]; then
        local proxy_url="http://${PROXY_HOST:-127.0.0.1}:${PROXY_PORT:-7897}"
        local no_proxy_list="${NO_PROXY:-localhost,127.0.0.1}"
        
        config_content="# 代理环境变量 (动态生成)
# 生成时间: $(date)

env = http_proxy,$proxy_url
env = https_proxy,$proxy_url
env = HTTP_PROXY,$proxy_url
env = HTTPS_PROXY,$proxy_url
env = no_proxy,$no_proxy_list
env = NO_PROXY,$no_proxy_list
"
        echo "代理已启用: $proxy_url"
    else
        config_content="# 代理环境变量 (动态生成)
# 生成时间: $(date)
# 代理功能已禁用

# env = http_proxy,
# env = https_proxy,
# env = HTTP_PROXY,
# env = HTTPS_PROXY,
# env = no_proxy,
# env = NO_PROXY,
"
        echo "代理已禁用"
    fi
    
    echo "$config_content" > "$PROXY_ENV_FILE"
    echo "代理配置已生成: $PROXY_ENV_FILE"
}

# 主函数
main() {
    echo "正在根据 .env.local 生成代理环境变量配置..."
    generate_proxy_config
    echo "完成！"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi