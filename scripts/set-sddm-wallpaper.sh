#!/bin/bash

# SDDM背景设置脚本 - 同步Hyprland壁纸到登录界面

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

success() {
    echo "[SUCCESS] $1"
}

# 检查是否需要sudo权限
check_permissions() {
    local theme_dir="/usr/share/sddm/themes/sugar-candy-optimized"
    if [ ! -w "$theme_dir/Backgrounds" ] 2>/dev/null; then
        if [ "$EUID" -ne 0 ]; then
            error "需要sudo权限来设置SDDM背景"
            echo "请运行：sudo $0"
            exit 1
        fi
    fi
}

# 设置SDDM背景
set_sddm_wallpaper() {
    local source_wallpaper=""
    local theme_dir="/usr/share/sddm/themes/sugar-candy-optimized"
    local bg_dir="$theme_dir/Backgrounds"
    local target_bg="$bg_dir/current_wallpaper.jpg"
    
    # 如果提供了参数，使用指定的壁纸
    if [ -n "$1" ] && [ -f "$1" ]; then
        source_wallpaper="$1"
        log "使用指定的壁纸: $source_wallpaper"
    else
        # 尝试从swww获取当前壁纸
        if command -v swww >/dev/null 2>&1; then
            # 获取当前显示器
            local monitor=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || echo "")
            
            # 尝试从swww查询当前壁纸
            local current_swww=$(swww query 2>/dev/null | grep "$monitor" | cut -d' ' -f8 2>/dev/null)
            
            if [ -n "$current_swww" ] && [ -f "$current_swww" ]; then
                source_wallpaper="$current_swww"
                log "从swww获取当前壁纸: $source_wallpaper"
            fi
        fi
        
        # 如果还没找到，尝试从常见壁纸目录寻找
        if [ -z "$source_wallpaper" ]; then
            for wallpaper_dir in "$HOME/Pictures/Wallpapers" "$HOME/.config/swww/wallpapers" "/usr/share/backgrounds"; do
                if [ -d "$wallpaper_dir" ]; then
                    local found_wallpaper=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | head -n 1)
                    if [ -n "$found_wallpaper" ]; then
                        source_wallpaper="$found_wallpaper"
                        log "使用找到的壁纸: $source_wallpaper"
                        break
                    fi
                fi
            done
        fi
    fi
    
    # 检查主题目录
    if [ ! -d "$theme_dir" ]; then
        error "SDDM主题目录不存在: $theme_dir"
        echo "请先运行: sudo $HOME/dotfiles/scripts/fix-sddm-config.sh"
        exit 1
    fi
    
    # 确保背景目录存在
    mkdir -p "$bg_dir"
    
    # 设置背景
    if [ -n "$source_wallpaper" ] && [ -f "$source_wallpaper" ]; then
        # 如果是PNG图片，转换为JPEG以减小文件大小
        if [[ "$source_wallpaper" == *.png ]] && command -v convert >/dev/null 2>&1; then
            log "转换PNG到JPEG格式..."
            convert "$source_wallpaper" -quality 85 "$target_bg"
        else
            cp "$source_wallpaper" "$target_bg"
        fi
        
        # 设置权限
        chmod 644 "$target_bg"
        
        success "SDDM背景已设置: $target_bg"
        
        # 显示文件信息
        ls -lh "$target_bg"
        
    else
        log "未找到合适的壁纸，使用默认背景"
        # 使用主题自带的默认背景
        if [ -f "$bg_dir/Mountain.jpg" ]; then
            cp "$bg_dir/Mountain.jpg" "$target_bg"
            log "使用默认Mountain.jpg背景"
        else
            # 创建一个简单的渐变背景
            log "创建默认渐变背景..."
            if command -v convert >/dev/null 2>&1; then
                convert -size 1920x1080 gradient:'#1e222a-#2d3748' "$target_bg"
            else
                # 创建占位符
                touch "$target_bg"
            fi
        fi
    fi
}

# 主函数
main() {
    log "开始设置SDDM背景..."
    
    check_permissions
    set_sddm_wallpaper "$1"
    
    success "SDDM背景设置完成！"
    echo "重启SDDM服务以查看效果: sudo systemctl restart sddm"
}

# 显示帮助
show_help() {
    cat << EOF
SDDM背景设置脚本

用法：
  $0                    # 自动检测当前壁纸
  $0 /path/to/image     # 使用指定图片
  $0 --help            # 显示帮助

功能：
- 自动同步当前Hyprland壁纸到SDDM登录界面
- 支持PNG到JPEG转换（需要ImageMagick）
- 自动设置文件权限

注意：可能需要sudo权限
EOF
}

# 参数处理
case "${1:-}" in
    --help|-h)
        show_help
        ;;
    "")
        main
        ;;
    *)
        if [ -f "$1" ]; then
            main "$1"
        else
            error "文件不存在: $1"
            show_help
            exit 1
        fi
        ;;
esac