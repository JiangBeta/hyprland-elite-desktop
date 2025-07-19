#!/bin/bash

# SDDM Sugar Candy壁纸同步脚本
# 从桌面壁纸目录随机选择一张图片作为SDDM背景

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SDDM_THEME_DIR="/usr/share/sddm/themes/sugar-candy"
SDDM_THEME_CONFIG="$SDDM_THEME_DIR/theme.conf"
SDDM_BG_DIR="$SDDM_THEME_DIR/Backgrounds"

# 检查壁纸目录是否存在
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "壁纸目录不存在: $WALLPAPER_DIR"
    exit 1
fi

# 检查SDDM主题目录是否存在
if [[ ! -d "$SDDM_THEME_DIR" ]]; then
    echo "SDDM主题目录不存在: $SDDM_THEME_DIR"
    exit 1
fi

echo "正在同步壁纸到SDDM主题..."

# 随机选择一张壁纸
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -20))

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "未找到任何壁纸文件"
    exit 1
fi

# 随机选择
RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"
WALLPAPER_NAME=$(basename "$RANDOM_WALLPAPER")

echo "选择的壁纸: $WALLPAPER_NAME"

# 复制壁纸到SDDM主题目录
sudo mkdir -p "$SDDM_BG_DIR"
sudo cp "$RANDOM_WALLPAPER" "$SDDM_BG_DIR/current_wallpaper.jpg"

# 更新主题配置
sudo sed -i 's|^Background=.*|Background="Backgrounds/current_wallpaper.jpg"|' "$SDDM_THEME_CONFIG"

echo "✅ SDDM壁纸已更新为: $WALLPAPER_NAME"
echo "重启后生效，或者切换到登录界面查看效果"