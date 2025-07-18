#!/bin/bash

# swww 手动设置壁纸脚本
# 用法: swww-set.sh [wallpaper_path]

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# 检查 swww daemon 是否运行
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "启动 swww daemon..."
    swww-daemon &
    sleep 2
fi

# 如果提供了壁纸路径参数
if [[ -n "$1" ]]; then
    WALLPAPER="$1"
    
    # 检查文件是否存在
    if [[ ! -f "$WALLPAPER" ]]; then
        echo "错误: 壁纸文件不存在: $WALLPAPER"
        exit 1
    fi
    
    echo "设置壁纸: $(basename "$WALLPAPER")"
    
    # 设置指定的壁纸
    swww img "$WALLPAPER" \
        --transition-type fade \
        --transition-duration 2 \
        --transition-step 20 \
        --transition-fps 60 \
         \
        --resize crop --filter Lanczos3
    
    echo "壁纸设置完成"
    
else
    # 没有提供参数，使用文件选择器选择壁纸
    if command -v zenity &> /dev/null; then
        WALLPAPER=$(zenity --file-selection --title="选择壁纸" --file-filter="图片 | *.jpg *.jpeg *.png *.webp *.bmp *.tiff *.gif")
        
        if [[ -n "$WALLPAPER" ]]; then
            echo "设置壁纸: $(basename "$WALLPAPER")"
            
            swww img "$WALLPAPER" \
                --transition-type fade \
                --transition-duration 2 \
                --transition-step 20 \
                --transition-fps 60 \
                 \
                --resize crop --filter Lanczos3
            
            echo "壁纸设置完成"
        else
            echo "未选择壁纸"
        fi
    elif command -v wofi &> /dev/null; then
        # 使用 wofi 选择器
        WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.gif" \) 2>/dev/null)
        
        if [[ -n "$WALLPAPERS" ]]; then
            WALLPAPER=$(echo "$WALLPAPERS" | wofi --dmenu --prompt "选择壁纸")
            
            if [[ -n "$WALLPAPER" ]]; then
                echo "设置壁纸: $(basename "$WALLPAPER")"
                
                swww img "$WALLPAPER" \
                    --transition-type fade \
                    --transition-duration 2 \
                    --transition-step 20 \
                    --transition-fps 60 \
                     \
                    --resize crop --filter Lanczos3
                
                echo "壁纸设置完成"
            else
                echo "未选择壁纸"
            fi
        else
            echo "在 $WALLPAPER_DIR 中未找到支持的壁纸文件"
        fi
    else
        echo "用法: $0 [壁纸路径]"
        echo "或者安装 zenity 或 wofi 来使用文件选择器"
        exit 1
    fi
fi