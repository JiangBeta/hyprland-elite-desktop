#!/bin/bash

# swww 定时切换壁纸脚本
# 可以设置定时器自动切换壁纸

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
INTERVAL="${1:-3600}"  # 默认60分钟切换一次 (3600秒)
RANDOM_SCRIPT="$HOME/.config/swww/swww-random.sh"

echo "启动 swww 定时切换壁纸服务，间隔: ${INTERVAL} 秒"

# 检查随机壁纸脚本是否存在
if [[ ! -x "$RANDOM_SCRIPT" ]]; then
    echo "错误: 随机壁纸脚本不存在或无执行权限: $RANDOM_SCRIPT"
    exit 1
fi

# 首次设置壁纸
"$RANDOM_SCRIPT"

# 定时切换壁纸
while true; do
    sleep "$INTERVAL"
    "$RANDOM_SCRIPT"
    echo "$(date): 壁纸已切换"
done