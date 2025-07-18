#!/bin/bash

# 定时自动下载壁纸脚本
# 每天自动下载新的高质量壁纸

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
LOG_FILE="$HOME/.config/swww/wallpaper_download.log"
MAX_WALLPAPERS=20  # 最多保存20张壁纸

# 创建目录
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# 记录日志
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "开始自动下载壁纸"

# 检查当前壁纸数量
current_count=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | wc -l)

if [ "$current_count" -ge "$MAX_WALLPAPERS" ]; then
    log_message "壁纸数量已达到上限 ($MAX_WALLPAPERS)，删除最旧的壁纸"
    # 删除最旧的壁纸
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) -printf '%T+ %p\n' | sort | head -5 | cut -d' ' -f2- | while read -r file; do
        rm "$file"
        log_message "删除旧壁纸: $(basename "$file")"
    done
fi

# 随机选择壁纸主题
themes=("landscape" "nature" "mountain" "forest" "ocean" "sky" "minimal" "abstract")
theme=${themes[$RANDOM % ${#themes[@]}]}

# 随机尺寸
sizes=("2560x1440" "1920x1080" "3840x2160")
size=${sizes[$RANDOM % ${#sizes[@]}]}

# 生成文件名
timestamp=$(date +%Y%m%d_%H%M%S)
filename="wallpaper_${theme}_${timestamp}.jpg"

# 下载壁纸
url="https://source.unsplash.com/${size}/?${theme}"
log_message "正在下载壁纸: $url"

if wget -O "$WALLPAPER_DIR/$filename" "$url" 2>/dev/null; then
    log_message "壁纸下载成功: $filename"
    
    # 自动设置为当前壁纸
    if command -v swww &> /dev/null && pgrep -x "swww-daemon" > /dev/null; then
        swww img "$WALLPAPER_DIR/$filename" --transition-type fade --transition-duration 2000 --fill crop --resize lanczos3
        log_message "已设置为当前壁纸: $filename"
    fi
else
    log_message "壁纸下载失败: $url"
fi

log_message "自动下载壁纸任务完成"