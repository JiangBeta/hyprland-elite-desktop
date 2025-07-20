#!/bin/bash

# Dotfiles 安装脚本
# 支持多发行版的配置文件安装脚本

set -e

# 检查是否有模块化安装参数
if [[ $# -gt 0 ]]; then
    # 如果有参数，使用模块化安装脚本
    exec "$(dirname "$0")/scripts/modular-install.sh" "$@"
fi

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "开始安装 dotfiles..."
echo "备份目录: $BACKUP_DIR"

# 备份清理函数
cleanup_old_backups() {
    local backup_pattern="$HOME/dotfiles_backup_*"
    local max_backups=5
    
    echo "检查旧备份文件..."
    
    # 获取所有备份目录，按时间排序
    local backup_dirs=($(ls -dt $backup_pattern 2>/dev/null | head -20))
    local backup_count=${#backup_dirs[@]}
    
    if [[ $backup_count -gt $max_backups ]]; then
        echo "发现 $backup_count 个备份，保留最新的 $max_backups 个..."
        
        # 删除多余的备份
        for ((i=$max_backups; i<$backup_count; i++)); do
            local old_backup="${backup_dirs[$i]}"
            if [[ -d "$old_backup" ]]; then
                echo "删除旧备份: $old_backup"
                rm -rf "$old_backup"
            fi
        done
        
        echo "✅ 备份清理完成"
    else
        echo "备份数量正常 ($backup_count/$max_backups)"
    fi
}

# 清理旧备份
cleanup_old_backups

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
    ["$DOTFILES_DIR/config/wofi"]="$HOME/.config/wofi"
    ["$DOTFILES_DIR/config/Code"]="$HOME/.config/Code"
    ["$DOTFILES_DIR/config/totp"]="$HOME/.config/totp"
    ["$DOTFILES_DIR/config/gtk-3.0"]="$HOME/.config/gtk-3.0"
    ["$DOTFILES_DIR/config/gtk-4.0"]="$HOME/.config/gtk-4.0"
    ["$DOTFILES_DIR/config/qt5ct"]="$HOME/.config/qt5ct"
)

declare -A CLAUDE_FILES=(
    ["$DOTFILES_DIR/claude"]="$HOME/.claude"
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

# 处理 Claude 配置文件
echo "处理 Claude 配置文件..."
for src in "${!CLAUDE_FILES[@]}"; do
    dst="${CLAUDE_FILES[$src]}"
    
    if [[ -e "$dst" ]]; then
        echo "备份: $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi
    
    echo "链接: $src -> $dst"
    ln -sf "$src" "$dst"
done

# 处理 fcitx5 用户词库和主题
echo "处理 fcitx5 用户数据..."
mkdir -p "$HOME/.local/share/fcitx5"

# 处理 fcitx5 用户词库
if [[ -d "$DOTFILES_DIR/config/fcitx5/pinyin" ]]; then
    if [[ -e "$HOME/.local/share/fcitx5/pinyin" ]]; then
        echo "备份: $HOME/.local/share/fcitx5/pinyin -> $BACKUP_DIR/"
        mv "$HOME/.local/share/fcitx5/pinyin" "$BACKUP_DIR/"
    fi
    echo "链接: $DOTFILES_DIR/config/fcitx5/pinyin -> $HOME/.local/share/fcitx5/pinyin"
    ln -sf "$DOTFILES_DIR/config/fcitx5/pinyin" "$HOME/.local/share/fcitx5/pinyin"
fi

# 处理 fcitx5 主题
mkdir -p "$HOME/.local/share/fcitx5/themes"
if [[ -d "$DOTFILES_DIR/config/fcitx5/themes/modern" ]]; then
    echo "链接: $DOTFILES_DIR/config/fcitx5/themes/modern -> $HOME/.local/share/fcitx5/themes/modern"
    ln -sf "$DOTFILES_DIR/config/fcitx5/themes/modern" "$HOME/.local/share/fcitx5/themes/modern"
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

# 初始化TOTP配置
echo "初始化TOTP配置..."
if [[ ! -f "$HOME/.config/totp/secrets.conf" && -f "$DOTFILES_DIR/config/totp/secrets.conf.template" ]]; then
    echo "创建TOTP配置文件: $HOME/.config/totp/secrets.conf"
    cp "$DOTFILES_DIR/config/totp/secrets.conf.template" "$HOME/.config/totp/secrets.conf"
    echo "⚠️  请编辑 ~/.config/totp/secrets.conf 添加您的TOTP密钥"
fi

# 验证关键链接
echo "🔍 验证安装..."
MISSING_LINKS=()

# 检查重要的脚本链接
if [[ ! -L "$HOME/.local/bin/youtube-music-wrapper.sh" ]]; then
    MISSING_LINKS+=("YouTube Music wrapper script")
fi

if [[ ! -L "$HOME/.local/share/fcitx5/themes/modern" ]]; then
    MISSING_LINKS+=("fcitx5 modern theme")
fi

if [[ ! -L "$HOME/.config/wofi" ]]; then
    MISSING_LINKS+=("wofi configuration")
fi

if [[ ${#MISSING_LINKS[@]} -gt 0 ]]; then
    echo "⚠️  发现缺失的链接:"
    for link in "${MISSING_LINKS[@]}"; do
        echo "   - $link"
    done
    echo "   请重新运行安装脚本或手动创建链接"
else
    echo "✅ 所有关键链接验证通过"
fi

echo ""
echo "✅ Dotfiles 安装完成!"
echo "备份文件保存在: $BACKUP_DIR"
echo ""
# 检测发行版和包管理器
if command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
    PKG_INSTALL="sudo pacman -S"
    AUR_INSTALL="yay -S"
elif command -v apt >/dev/null 2>&1; then
    DISTRO="debian"
    PKG_INSTALL="sudo apt install"
    AUR_INSTALL="echo '需要手动编译安装:'"
elif command -v dnf >/dev/null 2>&1; then
    DISTRO="fedora"
    PKG_INSTALL="sudo dnf install"
    AUR_INSTALL="echo '需要手动编译安装:'"
else
    DISTRO="unknown"
    PKG_INSTALL="echo '请手动安装:'"
    AUR_INSTALL="echo '请手动安装:'"
fi

echo ""
echo "📋 后续步骤:"
echo "1. 编辑 ~/.config/totp/secrets.conf 添加TOTP密钥"
echo "2. 安装TOTP依赖: $PKG_INSTALL oath-toolkit"
echo "3. 重新登录或运行 'source ~/.bashrc' 来应用更改"
echo "4. 使用 Super+W 切换壁纸，Super+T 查看TOTP验证码"
echo ""
echo "🎨 可选功能:"
echo "5. 登录管理器: $PKG_INSTALL sddm"
echo "6. Sugar Candy主题: $AUR_INSTALL sddm-sugar-candy-git"
echo "8. 日历管理: $PKG_INSTALL kontact korganizer"  
echo "9. 手机协作: $PKG_INSTALL scrcpy"