#!/bin/bash

# swww 随机壁纸脚本
# 高质量配置，支持多种图片格式

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONFIG_FILE="$HOME/.config/swww/swww.conf"

# 检查 swww daemon 是否运行
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "启动 swww daemon..."
    swww-daemon &
    sleep 2
fi

# 检查壁纸目录是否存在
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "错误: 壁纸目录 $WALLPAPER_DIR 不存在"
    exit 1
fi

# 支持的图片格式
EXTENSIONS=("jpg" "jpeg" "png" "webp" "bmp" "tiff" "gif")

# 查找所有支持的图片文件
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
        --transition-duration 2000 \
        --transition-step 20 \
        --transition-fps 60 \
        --fill crop \
        --resize lanczos3
else
    # 回退到基本高质量设置
    swww img "$RANDOM_WALLPAPER" \
        --transition-type fade \
        --transition-duration 2000 \
        --fill crop \
        --resize lanczos3
fi

echo "壁纸设置完成"