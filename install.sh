#!/bin/bash

# Dotfiles 安装脚本
# 在新机器上运行此脚本来设置所有配置文件

set -e

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "开始安装 dotfiles..."
echo "备份目录: $BACKUP_DIR"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 配置文件映射
declare -A CONFIG_FILES=(
    ["$DOTFILES_DIR/config/hypr"]="$HOME/.config/hypr"
    ["$DOTFILES_DIR/config/waybar"]="$HOME/.config/waybar"
    ["$DOTFILES_DIR/config/fcitx5"]="$HOME/.config/fcitx5"
    ["$DOTFILES_DIR/config/kitty"]="$HOME/.config/kitty"
    ["$DOTFILES_DIR/config/swww"]="$HOME/.config/swww"
    ["$DOTFILES_DIR/config/mako"]="$HOME/.config/mako"
    ["$DOTFILES_DIR/config/satty"]="$HOME/.config/satty"
    ["$DOTFILES_DIR/config/swappy"]="$HOME/.config/swappy"
)

declare -A SHELL_FILES=(
    ["$DOTFILES_DIR/shell/bashrc"]="$HOME/.bashrc"
    ["$DOTFILES_DIR/shell/zshrc"]="$HOME/.zshrc"
    ["$DOTFILES_DIR/shell/screenrc"]="$HOME/.screenrc"
    ["$DOTFILES_DIR/.Xresources"]="$HOME/.Xresources"
)

# CLAUDE.md 文件（不需要链接，保留在 dotfiles 目录）
CLAUDE_FILE="$DOTFILES_DIR/CLAUDE.md"

# 确保 .config 目录存在
mkdir -p "$HOME/.config"

# 处理配置文件
echo "处理配置文件..."
for src in "${!CONFIG_FILES[@]}"; do
    dst="${CONFIG_FILES[$src]}"
    
    if [[ -e "$dst" ]]; then
        echo "备份: $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi
    
    echo "链接: $src -> $dst"
    ln -sf "$src" "$dst"
done

# 处理 shell 文件
echo "处理 shell 配置文件..."
for src in "${!SHELL_FILES[@]}"; do
    dst="${SHELL_FILES[$src]}"
    
    if [[ -e "$dst" ]]; then
        echo "备份: $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi
    
    echo "链接: $src -> $dst"
    ln -sf "$src" "$dst"
done

# 处理 scripts 目录
echo "处理 scripts 目录..."
if [[ -d "$DOTFILES_DIR/scripts" ]]; then
    mkdir -p "$HOME/.local/bin"
    for script in "$DOTFILES_DIR/scripts"/*; do
        if [[ -f "$script" ]]; then
            basename_file=$(basename "$script")
            dst="$HOME/.local/bin/$basename_file"
            
            if [[ -e "$dst" && ! -L "$dst" ]]; then
                echo "备份脚本: $dst -> $BACKUP_DIR/"
                mv "$dst" "$BACKUP_DIR/"
            fi
            
            echo "链接脚本: $script -> $dst"
            ln -sf "$script" "$dst"
            chmod +x "$script"
        fi
    done
fi

# 处理 desktop 应用程序文件
echo "处理 desktop 应用程序文件..."
mkdir -p "$HOME/.local/share/applications"

if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
    for src in "$DOTFILES_DIR/config/applications"/*.desktop; do
        if [[ -f "$src" ]]; then
            basename_file=$(basename "$src")
            dst="$HOME/.local/share/applications/$basename_file"
            
            if [[ -e "$dst" && ! -L "$dst" ]]; then
                echo "备份desktop文件: $dst -> $BACKUP_DIR/"
                mv "$dst" "$BACKUP_DIR/"
            fi
            
            echo "链接desktop文件: $src -> $dst"
            ln -sf "$src" "$dst"
        fi
    done
    
    # 更新desktop数据库
    echo "更新desktop数据库..."
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
fi

echo "✅ Dotfiles 安装完成!"
echo "备份文件保存在: $BACKUP_DIR"
echo "请重新登录或运行 'source ~/.bashrc' 来应用更改"