#!/bin/bash

# SDDM Sugar Candy主题一键美化脚本
# 统一桌面风格配置

set -e

DOTFILES_DIR="$HOME/dotfiles"
SDDM_THEME_DIR="/usr/share/sddm/themes/sugar-candy"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

echo "🎨 开始配置SDDM Sugar Candy主题..."

# 检查必要目录
if [[ ! -d "$SDDM_THEME_DIR" ]]; then
    echo "❌ Sugar Candy主题未安装，请先安装: yay -S sddm-sugar-candy-git"
    exit 1
fi

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "❌ 壁纸目录不存在: $WALLPAPER_DIR"
    exit 1
fi

echo "✅ 检查完成，开始配置..."

# 1. 选择随机壁纸并复制到SDDM主题
echo "📸 选择随机壁纸..."
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -20))

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "❌ 未找到任何壁纸文件"
    exit 1
fi

RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"
WALLPAPER_NAME=$(basename "$RANDOM_WALLPAPER")

echo "📷 选择的壁纸: $WALLPAPER_NAME"

sudo mkdir -p "$SDDM_THEME_DIR/Backgrounds"
sudo cp "$RANDOM_WALLPAPER" "$SDDM_THEME_DIR/Backgrounds/current_wallpaper.jpg"

# 2. 应用统一风格的主题配置
echo "🎨 应用Hyprland风格配置..."
sudo cp "$DOTFILES_DIR/config/sddm/sugar-candy-custom.conf" "$SDDM_THEME_DIR/theme.conf"

# 3. 创建壁纸同步服务
echo "🔄 创建壁纸同步服务..."
sudo tee /etc/systemd/system/sddm-wallpaper-sync.service > /dev/null << EOF
[Unit]
Description=Sync desktop wallpaper to SDDM
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$DOTFILES_DIR/scripts/sddm-wallpaper-sync.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

# 4. 启用服务
sudo systemctl enable sddm-wallpaper-sync.service

# 5. 创建手动同步壁纸的快捷命令
echo "⚡ 创建快捷命令..."
sudo ln -sf "$DOTFILES_DIR/scripts/sddm-wallpaper-sync.sh" /usr/local/bin/sync-sddm-wallpaper
sudo chmod +x /usr/local/bin/sync-sddm-wallpaper

echo ""
echo "✅ SDDM Sugar Candy主题配置完成！"
echo ""
echo "🎯 配置特点："
echo "   • 使用与Waybar统一的配色方案 (#abb2bf, #61afef)"
echo "   • JetBrainsMono字体保持一致性"
echo "   • 20px圆角与Waybar匹配"
echo "   • 半透明背景与桌面风格统一"
echo "   • 随机壁纸同步功能"
echo ""
echo "🔧 使用方法："
echo "   • 重启查看效果: sudo reboot"
echo "   • 手动同步壁纸: sync-sddm-wallpaper"
echo "   • 测试登录界面: sudo systemctl restart sddm"
echo ""
echo "⚠️  注意：重启后需要输入密码登录"