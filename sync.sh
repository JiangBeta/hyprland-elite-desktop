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
    ["$HOME/.config/swww"]="$DOTFILES_DIR/config/swww"
    ["$HOME/.config/mako"]="$DOTFILES_DIR/config/mako"
    ["$HOME/.config/satty"]="$DOTFILES_DIR/config/satty"
    ["$HOME/.config/swappy"]="$DOTFILES_DIR/config/swappy"
    ["$HOME/.config/wofi"]="$DOTFILES_DIR/config/wofi"
    ["$HOME/.config/Code"]="$DOTFILES_DIR/config/Code"
)

declare -A CLAUDE_FILES=(
    ["$HOME/.claude"]="$DOTFILES_DIR/claude"
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

# 同步 scripts 目录
echo "同步 scripts 目录..."
if [[ -d "$HOME/.local/bin" ]]; then
    mkdir -p "$DOTFILES_DIR/scripts"
    for script in "$HOME/.local/bin"/*; do
        if [[ -L "$script" ]]; then
            # 检查链接是否指向 dotfiles
            link_target=$(readlink -f "$script")
            if [[ "$link_target" == "$DOTFILES_DIR/scripts"/* ]]; then
                echo "跳过指向 dotfiles 的软链接: $script"
            fi
        elif [[ -f "$script" ]]; then
            basename_file=$(basename "$script")
            dst="$DOTFILES_DIR/scripts/$basename_file"
            echo "同步脚本: $script -> $dst"
            cp "$script" "$dst"
            chmod +x "$dst"
        fi
    done
fi

# 同步 desktop 应用程序文件
echo "同步 desktop 应用程序文件..."
mkdir -p "$DOTFILES_DIR/config/applications"

# 同步现有的自定义desktop文件
if [[ -d "$HOME/.local/share/applications" ]]; then
    for desktop_file in "$HOME/.local/share/applications"/*.desktop; do
        if [[ -f "$desktop_file" && ! -L "$desktop_file" ]]; then
            basename_file=$(basename "$desktop_file")
            dst="$DOTFILES_DIR/config/applications/$basename_file"
            
            # 检查是否是自定义的desktop文件（不在系统目录中）
            if [[ ! -f "/usr/share/applications/$basename_file" ]]; then
                echo "同步自定义desktop文件: $desktop_file -> $dst"
                cp "$desktop_file" "$dst"
            else
                # 检查是否被修改过
                if ! diff -q "$desktop_file" "/usr/share/applications/$basename_file" > /dev/null 2>&1; then
                    echo "同步修改过的desktop文件: $desktop_file -> $dst"
                    cp "$desktop_file" "$dst"
                fi
            fi
        fi
    done
fi

# 同步 Claude 配置文件
echo "同步 Claude 配置文件..."
for src in "${!CLAUDE_FILES[@]}"; do
    dst="${CLAUDE_FILES[$src]}"
    
    if [[ -e "$src" ]]; then
        if [[ -L "$src" ]]; then
            echo "跳过软链接: $src"
            continue
        fi
        
        echo "同步: $src -> $dst"
        # 排除敏感文件
        rsync -av --delete --exclude='.credentials.json' "$src/" "$dst/"
    else
        echo "警告: $src 不存在"
    fi
done

# 检查 CLAUDE.md 文件
if [[ -f "$DOTFILES_DIR/CLAUDE.md" ]]; then
    echo "✅ CLAUDE.md 文件已存在于 dotfiles 目录"
else
    echo "⚠️  未找到 CLAUDE.md 文件，可以运行 'claude code /init' 来创建"
fi

echo "✅ 同步完成!"
echo "现在可以提交更改到 git 仓库"