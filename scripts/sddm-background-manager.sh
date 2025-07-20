#!/bin/bash

# SDDM背景管理脚本
# 功能：设置SDDM背景图片，支持随机选择、桌面一致性和默认图片下载

SDDM_BACKGROUND_DIR="/usr/share/sddm/themes/sugar-candy/Backgrounds"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
HYPR_WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
DEFAULT_WALLPAPER_URL="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
DEFAULT_GRADIENT_CSS="linear-gradient(135deg, #667eea 0%, #764ba2 100%)"

# 默认背景色配置（CSS格式渐变）
DEFAULT_BACKGROUNDS=(
    "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
    "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)"
    "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)"
    "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)"
    "linear-gradient(135deg, #fa709a 0%, #fee140 100%)"
    "linear-gradient(135deg, #30cfd0 0%, #91a7ff 100%)"
    "linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)"
    "linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)"
)

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 检查sudo权限
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log "错误：需要sudo权限来更新SDDM背景"
        echo "请运行：sudo $0 $@"
        exit 1
    fi
}

# 创建背景目录
create_background_dir() {
    if [ ! -d "$SDDM_BACKGROUND_DIR" ]; then
        mkdir -p "$SDDM_BACKGROUND_DIR"
        log "创建SDDM背景目录: $SDDM_BACKGROUND_DIR"
    fi
}

# 下载默认壁纸
download_default_wallpaper() {
    local default_path="$SDDM_BACKGROUND_DIR/default_mountain.jpg"
    
    if [ ! -f "$default_path" ]; then
        log "下载默认壁纸..."
        if command -v curl >/dev/null 2>&1; then
            curl -L "$DEFAULT_WALLPAPER_URL" -o "$default_path" || {
                log "下载失败，使用系统默认图片"
                return 1
            }
        elif command -v wget >/dev/null 2>&1; then
            wget "$DEFAULT_WALLPAPER_URL" -O "$default_path" || {
                log "下载失败，使用系统默认图片"
                return 1
            }
        else
            log "未找到curl或wget，无法下载默认壁纸"
            return 1
        fi
        log "默认壁纸下载完成: $default_path"
    fi
    echo "$default_path"
}

# 创建渐变背景图片
create_gradient_background() {
    local gradient="$1"
    local output_path="$2"
    
    if command -v convert >/dev/null 2>&1; then
        # 使用ImageMagick创建渐变背景
        convert -size 1920x1080 gradient:"$gradient" "$output_path"
        log "创建渐变背景: $output_path"
        return 0
    else
        log "未安装ImageMagick，无法创建渐变背景"
        return 1
    fi
}

# 获取当前Hyprland壁纸
get_current_hyprland_wallpaper() {
    if [ -f "$HOME/.config/hypr/current_wallpaper" ]; then
        cat "$HOME/.config/hypr/current_wallpaper"
    elif [ -d "$HYPR_WALLPAPER_DIR" ] && [ "$(ls -A $HYPR_WALLPAPER_DIR)" ]; then
        find "$HYPR_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | head -1
    fi
}

# 随机选择壁纸
get_random_wallpaper() {
    local search_dirs=("$WALLPAPER_DIR" "$HYPR_WALLPAPER_DIR" "$HOME/Pictures")
    local wallpapers=()
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r -d '' file; do
                wallpapers+=("$file")
            done < <(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 2>/dev/null)
        fi
    done
    
    if [ ${#wallpapers[@]} -gt 0 ]; then
        echo "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    fi
}

# 设置SDDM背景
set_sddm_background() {
    local source_image="$1"
    local target_path="$SDDM_BACKGROUND_DIR/current_wallpaper.jpg"
    
    if [ -f "$source_image" ]; then
        cp "$source_image" "$target_path"
        log "设置SDDM背景: $source_image -> $target_path"
        return 0
    else
        log "源图片不存在: $source_image"
        return 1
    fi
}

# 主要功能函数
main() {
    local mode="${1:-auto}"
    local custom_image="$2"
    
    log "SDDM背景管理器启动 - 模式: $mode"
    
    check_sudo
    create_background_dir
    
    case "$mode" in
        "desktop"|"hyprland")
            log "使用当前桌面壁纸"
            current_wallpaper=$(get_current_hyprland_wallpaper)
            if [ -n "$current_wallpaper" ] && [ -f "$current_wallpaper" ]; then
                set_sddm_background "$current_wallpaper"
            else
                log "未找到当前桌面壁纸，使用随机模式"
                main "random"
            fi
            ;;
        "random")
            log "随机选择壁纸"
            random_wallpaper=$(get_random_wallpaper)
            if [ -n "$random_wallpaper" ]; then
                set_sddm_background "$random_wallpaper"
            else
                log "未找到壁纸，使用默认模式"
                main "default"
            fi
            ;;
        "default")
            log "使用默认壁纸"
            default_wallpaper=$(download_default_wallpaper)
            if [ -n "$default_wallpaper" ]; then
                set_sddm_background "$default_wallpaper"
            else
                log "使用渐变背景"
                main "gradient"
            fi
            ;;
        "gradient")
            log "创建渐变背景"
            gradient_bg="${DEFAULT_BACKGROUNDS[RANDOM % ${#DEFAULT_BACKGROUNDS[@]}]}"
            gradient_path="$SDDM_BACKGROUND_DIR/gradient_background.jpg"
            if create_gradient_background "$gradient_bg" "$gradient_path"; then
                set_sddm_background "$gradient_path"
            else
                log "无法创建渐变背景，使用系统默认"
            fi
            ;;
        "custom")
            if [ -n "$custom_image" ] && [ -f "$custom_image" ]; then
                log "使用自定义图片: $custom_image"
                set_sddm_background "$custom_image"
            else
                log "自定义图片无效，使用默认模式"
                main "default"
            fi
            ;;
        "auto"|*)
            log "自动模式：尝试使用桌面壁纸，失败则随机选择"
            current_wallpaper=$(get_current_hyprland_wallpaper)
            if [ -n "$current_wallpaper" ] && [ -f "$current_wallpaper" ]; then
                set_sddm_background "$current_wallpaper"
            else
                main "random"
            fi
            ;;
    esac
    
    # 重启SDDM以应用更改（可选）
    if command -v systemctl >/dev/null 2>&1; then
        log "SDDM背景更新完成。如需立即生效，请运行: sudo systemctl restart sddm"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
SDDM背景管理器

用法: $0 [模式] [自定义图片路径]

模式:
  auto     - 自动模式（默认）：尝试使用桌面壁纸，失败则随机选择
  desktop  - 使用当前桌面壁纸（Hyprland）
  random   - 随机选择壁纸
  default  - 下载并使用默认壁纸
  gradient - 创建随机渐变背景
  custom   - 使用自定义图片（需要提供图片路径）

示例:
  sudo $0 auto                    # 自动模式
  sudo $0 desktop                 # 使用桌面壁纸
  sudo $0 random                  # 随机壁纸
  sudo $0 custom /path/to/image.jpg  # 自定义图片

注意: 此脚本需要sudo权限来修改SDDM主题文件
EOF
}

# 参数处理
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

main "$@"