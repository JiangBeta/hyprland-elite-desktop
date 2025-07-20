#!/bin/bash

# 配置文件生成脚本
# 将模板配置和个人配置合并生成最终的配置文件

set -e

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_FILE="$HOME/dotfiles/.env.local"

echo "生成个性化配置文件..."

# 加载用户配置
if [[ -f "$CONFIG_FILE" ]]; then
    source "$DOTFILES_DIR/scripts/load-config.sh"
    echo "✅ 已加载用户配置: $CONFIG_FILE"
else
    echo "⚠️ 未找到用户配置文件: $CONFIG_FILE"
    echo "请先创建 .env.local 文件"
    exit 1
fi

# 生成 .zshrc 文件
generate_zshrc() {
    local template="$DOTFILES_DIR/shell/zshrc"
    local local_config="$HOME/.zshrc.local"
    local output="$HOME/.zshrc"
    
    echo "生成 zsh 配置文件..."
    
    # 复制模板内容
    cp "$template" "$output"
    
    # 如果存在本地配置，追加到文件末尾
    if [[ -f "$local_config" ]]; then
        echo "" >> "$output"
        echo "# ========================================" >> "$output"
        echo "# 本地个性化配置 (自动生成)" >> "$output"
        echo "# ========================================" >> "$output"
        cat "$local_config" >> "$output"
        echo "✅ 已合并本地配置: $local_config"
    fi
    
    echo "✅ zsh 配置文件已生成: $output"
}

# 生成其他可能需要个性化的配置文件
generate_other_configs() {
    # 天气脚本个性化
    local weather_script="$HOME/.config/waybar/weather.sh"
    if [[ -f "$DOTFILES_DIR/config/waybar/weather.sh" ]]; then
        # 如果是软链接，先删除
        if [[ -L "$weather_script" ]]; then
            rm "$weather_script"
            echo "✅ 已移除天气脚本软链接"
        fi
        
        # 复制天气脚本并应用个人城市设置
        cp "$DOTFILES_DIR/config/waybar/weather.sh" "$weather_script"
        
        # 如果设置了天气城市，替换脚本中的设置
        if [[ -n "$WEATHER_CITY" ]]; then
            sed -i "s/MANUAL_CITY=\"\"/MANUAL_CITY=\"$WEATHER_CITY\"/" "$weather_script"
            echo "✅ 天气城市已设置为: $WEATHER_CITY"
        fi
        
        chmod +x "$weather_script"
    fi
    
    # 其他需要个性化的配置文件可以在这里添加
}

# 主函数
main() {
    echo "========================================="
    echo "正在生成个性化配置文件..."
    echo "========================================="
    
    # 备份现有的 .zshrc（如果不是软链接）
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ 已备份现有 .zshrc"
    fi
    
    # 如果是软链接，先删除
    if [[ -L "$HOME/.zshrc" ]]; then
        rm "$HOME/.zshrc"
        echo "✅ 已移除 .zshrc 软链接"
    fi
    
    generate_zshrc
    generate_other_configs
    
    echo "========================================="
    echo "配置文件生成完成！"
    echo "========================================="
    echo "现在可以运行: source ~/.zshrc"
    echo ""
    echo "注意："
    echo "- ~/.zshrc 现在是独立的配置文件（不再是软链接）"
    echo "- 个人配置通过 .env.local 和 .zshrc.local 管理"
    echo "- 模板更新时需要重新运行此脚本"
}

main "$@"
