#!/bin/bash

# SDDM主题部署脚本
# 自动部署sugar-candy-compact主题和相关配置

DOTFILES_DIR="/home/laofahai/dotfiles"
SDDM_CONFIG_DIR="/etc/sddm.conf.d"
SDDM_THEME_DIR="/usr/share/sddm/themes"
CUSTOM_THEME_NAME="sugar-candy-compact"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log "错误：需要sudo权限来部署SDDM配置"
        echo "请运行：sudo $0"
        exit 1
    fi
}

deploy_sddm_config() {
    log "部署SDDM主配置文件..."
    
    # 创建SDDM配置目录
    mkdir -p "$SDDM_CONFIG_DIR"
    
    # 复制主配置文件
    cp "$DOTFILES_DIR/config/sddm/sddm.conf" "$SDDM_CONFIG_DIR/sddm.conf"
    log "已复制主配置文件到 $SDDM_CONFIG_DIR/sddm.conf"
}

deploy_custom_theme() {
    log "部署自定义SDDM主题..."
    
    # 复制自定义主题到系统目录
    if [ -d "$DOTFILES_DIR/config/sddm/$CUSTOM_THEME_NAME" ]; then
        # 删除旧的自定义主题（如果存在）
        rm -rf "$SDDM_THEME_DIR/$CUSTOM_THEME_NAME"
        
        # 复制新主题
        cp -r "$DOTFILES_DIR/config/sddm/$CUSTOM_THEME_NAME" "$SDDM_THEME_DIR/"
        log "已复制自定义主题到 $SDDM_THEME_DIR/$CUSTOM_THEME_NAME"
        
        # 设置正确的权限
        chown -R root:root "$SDDM_THEME_DIR/$CUSTOM_THEME_NAME"
        chmod -R 755 "$SDDM_THEME_DIR/$CUSTOM_THEME_NAME"
        log "已设置主题文件权限"
    else
        log "错误：找不到自定义主题目录 $DOTFILES_DIR/config/sddm/$CUSTOM_THEME_NAME"
        exit 1
    fi
}

setup_background() {
    log "设置SDDM背景..."
    
    # 运行背景管理脚本
    if [ -f "$DOTFILES_DIR/scripts/sddm-background-manager.sh" ]; then
        bash "$DOTFILES_DIR/scripts/sddm-background-manager.sh" auto
    else
        log "警告：未找到背景管理脚本"
    fi
}

restart_sddm() {
    log "重启SDDM服务以应用更改..."
    
    if systemctl is-active --quiet sddm; then
        systemctl restart sddm
        log "SDDM服务已重启"
    else
        log "SDDM服务未运行，启用并启动..."
        systemctl enable sddm
        systemctl start sddm
    fi
}

backup_current_config() {
    local backup_dir="/tmp/sddm_backup_$(date +%Y%m%d_%H%M%S)"
    
    log "备份当前SDDM配置到 $backup_dir"
    mkdir -p "$backup_dir"
    
    # 备份现有配置
    if [ -f "$SDDM_CONFIG_DIR/sddm.conf" ]; then
        cp "$SDDM_CONFIG_DIR/sddm.conf" "$backup_dir/"
    fi
    
    if [ -d "$SDDM_THEME_DIR/$CUSTOM_THEME_NAME" ]; then
        cp -r "$SDDM_THEME_DIR/$CUSTOM_THEME_NAME" "$backup_dir/"
    fi
    
    log "备份完成：$backup_dir"
}

show_status() {
    log "SDDM配置状态："
    echo "  主配置文件: $SDDM_CONFIG_DIR/sddm.conf"
    echo "  自定义主题: $SDDM_THEME_DIR/$CUSTOM_THEME_NAME"
    echo "  SDDM服务状态: $(systemctl is-active sddm)"
    echo "  当前主题设置: $(grep -E '^Current=' $SDDM_CONFIG_DIR/sddm.conf 2>/dev/null || echo '未设置')"
}

main() {
    log "开始部署SDDM配置..."
    
    check_sudo
    backup_current_config
    deploy_sddm_config
    deploy_custom_theme
    setup_background
    
    show_status
    
    read -p "是否重启SDDM服务以应用更改？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_sddm
    else
        log "配置已部署，请手动重启SDDM服务：sudo systemctl restart sddm"
    fi
    
    log "SDDM部署完成！"
}

# 显示帮助信息
show_help() {
    cat << EOF
SDDM主题部署脚本

功能：
- 备份现有SDDM配置
- 部署自定义sugar-candy-compact主题
- 设置主配置文件
- 配置背景图片
- 可选择重启SDDM服务

用法: sudo $0 [选项]

选项:
  --help, -h    显示此帮助信息
  --status      仅显示当前SDDM状态
  --backup      仅备份当前配置

注意: 此脚本需要sudo权限
EOF
}

# 参数处理
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --status)
        show_status
        exit 0
        ;;
    --backup)
        check_sudo
        backup_current_config
        exit 0
        ;;
    *)
        main
        ;;
esac