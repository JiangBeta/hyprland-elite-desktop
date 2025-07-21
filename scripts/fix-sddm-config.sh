#!/bin/bash

# SDDM配置修复脚本
# 修复SDDM配置部署问题

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

success() {
    echo "[SUCCESS] $1"
}

# 检查权限
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "需要sudo权限来修复SDDM配置"
        echo "请运行：sudo $0"
        exit 1
    fi
}

# 备份当前配置
backup_current() {
    local backup_dir="/tmp/sddm_config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [ -d "/etc/sddm.conf.d" ]; then
        cp -r /etc/sddm.conf.d "$backup_dir/"
        log "已备份现有配置到: $backup_dir"
    fi
}

# 修复SDDM配置
fix_sddm_config() {
    log "修复SDDM配置..."
    
    # 创建正确的配置目录
    mkdir -p /etc/sddm.conf.d
    
    # 写入正确的主配置
    cat > /etc/sddm.conf.d/sddm.conf << 'EOF'
[Theme]
Current=sugar-candy-optimized

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Users]
MaximumUid=60000
MinimumUid=1000

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF

    success "主配置文件已更新"
}

# 部署优化主题
deploy_optimized_theme() {
    log "部署优化的SDDM主题..."
    
    local theme_name="sugar-candy-optimized"
    local source_dir="$HOME/dotfiles/config/sddm/sugar-candy-compact"
    local target_dir="/usr/share/sddm/themes/$theme_name"
    
    # 检查源目录
    if [ ! -d "$source_dir" ]; then
        error "源主题目录不存在: $source_dir"
        return 1
    fi
    
    # 删除旧主题（如果存在）
    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir"
        log "已删除旧主题"
    fi
    
    # 复制新主题
    cp -r "$source_dir" "$target_dir"
    
    # 设置权限
    chown -R root:root "$target_dir"
    chmod -R 755 "$target_dir"
    
    success "主题部署完成: $target_dir"
}

# 更新主题配置
update_theme_config() {
    log "更新主题配置文件..."
    
    local theme_dir="/usr/share/sddm/themes/sugar-candy-optimized"
    local config_file="$theme_dir/theme.conf"
    
    # 创建优化的主题配置
    cat > "$config_file" << 'EOF'
[General]
Background="Backgrounds/current_wallpaper.jpg"
FallbackBackground="rgba(45, 52, 67, 1.0)"
DimBackgroundImage="0.2"
ScaleImageCropped="true"
ScreenWidth="1920"
ScreenHeight="1080"

## [Blur Settings] - 全屏模糊效果，与Hyprland风格统一
FullBlur="true"
PartialBlur="false"
BlurRadius="50"

## [Design Customizations] - 与waybar风格统一的圆角和透明度
HaveFormBackground="true"
FormPosition="center"
BackgroundImageHAlignment="center"
BackgroundImageVAlignment="center"
MainColor="#abb2bf"
AccentColor="#61afef"
BackgroundColor="rgba(40, 44, 52, 0.85)"
OverrideLoginButtonTextColor="#ffffff"
InterfaceShadowSize="6"
InterfaceShadowOpacity="0.3"
RoundCorners="20"
ScreenPadding="40"
Font="JetBrainsMono Nerd Font"
FontSize="14"

## [登录表单样式] - 更紧凑的设计
LoginBackground="rgba(40, 44, 52, 0.9)"
HeaderColor="#ffffff"
DateTimeColor="#abb2bf"
PowerButtonsColor="#61afef"

## [Interface Behavior]
ForceRightToLeft="false"
ForceLastUser="true"
ForcePasswordFocus="true"
ForceHideCompletePassword="false"
ForceHideVirtualKeyboardButton="false"
ForceHideSystemButtons="false"
AllowEmptyPassword="false"
AllowBadUsernames="false"

## [Locale Settings]
Locale=""
HourFormat="HH:mm"
DateFormat="dddd, MMMM d"

## [Translations]
HeaderText="欢迎回来！"
LoginButtonText="登录"
EOF

    success "主题配置文件已更新"
}

# 设置默认背景
setup_default_background() {
    log "设置默认背景..."
    
    local bg_dir="/usr/share/sddm/themes/sugar-candy-optimized/Backgrounds"
    local default_bg="$bg_dir/current_wallpaper.jpg"
    
    # 确保背景目录存在
    mkdir -p "$bg_dir"
    
    # 如果没有背景图片，创建一个默认的渐变背景
    if [ ! -f "$default_bg" ]; then
        # 尝试复制系统默认背景
        if [ -f "$bg_dir/Mountain.jpg" ]; then
            cp "$bg_dir/Mountain.jpg" "$default_bg"
            log "使用Mountain.jpg作为默认背景"
        else
            # 创建一个简单的纯色背景文件占位符
            touch "$default_bg"
            log "创建背景占位符，建议稍后运行背景管理脚本"
        fi
    fi
    
    success "背景设置完成"
}

# 重启SDDM服务
restart_sddm() {
    log "重启SDDM服务..."
    
    if systemctl is-active --quiet sddm; then
        systemctl restart sddm
        success "SDDM服务已重启"
    else
        systemctl enable sddm
        systemctl start sddm
        success "SDDM服务已启动"
    fi
}

# 显示配置状态
show_status() {
    log "当前SDDM配置状态："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 配置文件："
    ls -la /etc/sddm.conf.d/
    echo ""
    echo "🎨 当前主题："
    grep -E "^Current=" /etc/sddm.conf.d/sddm.conf 2>/dev/null || echo "未设置"
    echo ""
    echo "📁 主题目录："
    ls -la /usr/share/sddm/themes/ | grep sugar
    echo ""
    echo "🔧 服务状态："
    systemctl is-active sddm
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 主修复函数
main() {
    log "开始修复SDDM配置..."
    
    check_sudo
    backup_current
    fix_sddm_config
    deploy_optimized_theme
    update_theme_config
    setup_default_background
    
    show_status
    
    read -p "是否重启SDDM服务以应用更改？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_sddm
    else
        log "配置已修复，请手动重启SDDM服务：sudo systemctl restart sddm"
    fi
    
    success "SDDM配置修复完成！"
}

# 显示帮助
show_help() {
    cat << EOF
SDDM配置修复脚本

功能：
- 修复SDDM主配置文件
- 部署优化的sugar-candy主题
- 设置正确的主题路径
- 配置默认背景

用法：sudo $0

注意：需要sudo权限
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
        error "未知选项: $1"
        show_help
        exit 1
        ;;
esac