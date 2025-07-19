#!/bin/bash

# swww random wallpaper script
# High-quality configuration with multi-format support

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONFIG_FILE="$HOME/.config/swww/swww.conf"

# Check if swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "Starting swww daemon..."
    swww-daemon &
    sleep 2
fi

# Check if wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Error: Wallpaper directory $WALLPAPER_DIR does not exist"
    exit 1
fi

# Supported image formats
EXTENSIONS=("jpg" "jpeg" "png" "webp" "bmp" "tiff" "gif")

# Find all supported image files
WALLPAPERS=()
for ext in "${EXTENSIONS[@]}"; do
    while IFS= read -r -d '' file; do
        WALLPAPERS+=("$file")
    done < <(find "$WALLPAPER_DIR" -type f -iname "*.${ext}" -print0 2>/dev/null)
done

# 检查是否找到壁纸
if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "错误: 在 $WALLPAPER_DIR 中没有找到支持的图片文件"
    echo "支持的格式: ${EXTENSIONS[*]}"
    exit 1
fi

# 随机选择一张壁纸
RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

echo "设置壁纸: $(basename "$RANDOM_WALLPAPER")"

# 使用配置文件设置壁纸
if [[ -f "$CONFIG_FILE" ]]; then
    swww img "$RANDOM_WALLPAPER" \
        --transition-type fade \
        --transition-duration 2 \
        --transition-step 20 \
        --transition-fps 60 \
        --resize crop \
        --filter Lanczos3
else
    # 回退到基本高质量设置
    swww img "$RANDOM_WALLPAPER" \
        --transition-type fade \
        --transition-duration 2 \
        --resize crop \
        --filter Lanczos3
fi

echo "壁纸设置完成"