#!/bin/bash

# Dotfiles 同步脚本
# 用于同步配置文件更改到 dotfiles 目录

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "开始同步 dotfiles..."

# 配置文件映射
declare -A CONFIG_FILES=(
    ["$HOME/.config/hypr"]="$DOTFILES_DIR/config/hypr"
    ["$HOME/.config/waybar"]="$DOTFILES_DIR/config/waybar"
    ["$HOME/.config/fcitx5"]="$DOTFILES_DIR/config/fcitx5"
    ["$HOME/.config/kitty"]="$DOTFILES_DIR/config/kitty"
)

declare -A SHELL_FILES=(
    ["$HOME/.bashrc"]="$DOTFILES_DIR/shell/bashrc"
    ["$HOME/.zshrc"]="$DOTFILES_DIR/shell/zshrc"
    ["$HOME/.screenrc"]="$DOTFILES_DIR/shell/screenrc"
)

# 同步配置文件
echo "同步配置文件..."
for src in "${!CONFIG_FILES[@]}"; do
    dst="${CONFIG_FILES[$src]}"
    
    if [[ -e "$src" ]]; then
        if [[ -L "$src" ]]; then
            echo "跳过软链接: $src"
            continue
        fi
        
        echo "同步: $src -> $dst"
        rsync -av --delete "$src/" "$dst/"
    else
        echo "警告: $src 不存在"
    fi
done

# 同步 shell 文件
echo "同步 shell 配置文件..."
for src in "${!SHELL_FILES[@]}"; do
    dst="${SHELL_FILES[$src]}"
    
    if [[ -e "$src" ]]; then
        if [[ -L "$src" ]]; then
            echo "跳过软链接: $src"
            continue
        fi
        
        echo "同步: $src -> $dst"
        cp "$src" "$dst"
    else
        echo "警告: $src 不存在"
    fi
done

echo "✅ 同步完成!"
echo "现在可以提交更改到 git 仓库"