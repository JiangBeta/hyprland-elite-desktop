#!/bin/bash
# 输入法智能管理脚本

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测当前输入法状态
detect_input_method() {
    echo "=== 输入法环境检测 ==="
    
    # 检查fcitx5
    if command -v fcitx5 >/dev/null 2>&1; then
        echo "✅ fcitx5: $(fcitx5 --version 2>/dev/null | head -1)"
    else
        echo "❌ fcitx5: 未安装"
        return 1
    fi
    
    # 检查rime
    if command -v rime_deployer >/dev/null 2>&1; then
        echo "✅ fcitx5-rime: 已安装"
        HAS_RIME=true
    else
        echo "❌ fcitx5-rime: 未安装"
        HAS_RIME=false
    fi
    
    # 检查万象词库
    if [[ -d "$HOME/.local/share/fcitx5/rime" ]]; then
        local dict_count=$(find "$HOME/.local/share/fcitx5/rime" -name "*.dict.yaml" 2>/dev/null | wc -l)
        if [[ $dict_count -gt 0 ]]; then
            echo "✅ 万象词库: $dict_count 个词典文件"
            HAS_WANXIANG=true
        else
            echo "❌ 万象词库: 无词典文件"
            HAS_WANXIANG=false
        fi
    else
        echo "❌ 万象词库: rime目录不存在"
        HAS_WANXIANG=false
    fi
    
    # 检查当前配置
    if [[ -L "$HOME/.config/fcitx5" ]]; then
        local link_target=$(readlink "$HOME/.config/fcitx5")
        echo "📁 当前配置: $link_target"
    elif [[ -d "$HOME/.config/fcitx5" ]]; then
        echo "📁 当前配置: 本地目录 (非链接)"
    else
        echo "❌ 当前配置: 不存在"
    fi
    
    echo
}

# 切换到rime+万象配置
switch_to_rime() {
    log_info "切换到 rime + 万象词库 配置..."
    
    if [[ ! $HAS_RIME == true ]]; then
        log_error "fcitx5-rime 未安装，请先安装："
        echo "sudo pacman -S fcitx5-rime"
        return 1
    fi
    
    # 备份现有配置
    if [[ -d "$HOME/.config/fcitx5" && ! -L "$HOME/.config/fcitx5" ]]; then
        local backup_dir="$HOME/.config/fcitx5.backup.$(date +%s)"
        mv "$HOME/.config/fcitx5" "$backup_dir"
        log_info "已备份现有配置到: $backup_dir"
    fi
    
    # 链接fcitx5基础配置
    rm -f "$HOME/.config/fcitx5"
    ln -sf "$DOTFILES_DIR/config/fcitx5" "$HOME/.config/fcitx5"
    
    # 安装万象词库
    if [[ -x "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" ]]; then
        "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" install
    else
        log_warning "万象词库安装脚本不存在，请手动安装"
    fi
    
    restart_fcitx5
    log_success "已切换到 rime + 万象词库 配置"
}

# 切换到标准fcitx5拼音
switch_to_standard() {
    log_info "切换到标准 fcitx5 拼音配置..."
    
    # 使用回退配置或标准配置
    if [[ -d "$DOTFILES_DIR/config/fcitx5-fallback" ]]; then
        rm -f "$HOME/.config/fcitx5"
        ln -sf "$DOTFILES_DIR/config/fcitx5-fallback" "$HOME/.config/fcitx5"
        log_info "使用回退配置"
    else
        rm -f "$HOME/.config/fcitx5"
        ln -sf "$DOTFILES_DIR/config/fcitx5" "$HOME/.config/fcitx5"
        log_info "使用标准配置"
    fi
    
    restart_fcitx5
    log_success "已切换到标准 fcitx5 拼音配置"
}

# 重启fcitx5
restart_fcitx5() {
    if pgrep fcitx5 >/dev/null; then
        log_info "重启 fcitx5..."
        pkill fcitx5
        sleep 1
        fcitx5 -d
        log_success "fcitx5 已重启"
    else
        log_info "启动 fcitx5..."
        fcitx5 -d
    fi
}

# 交互式配置
interactive_setup() {
    detect_input_method
    
    echo "=== 输入法配置选择 ==="
    echo "1. 使用 rime + 万象词库 (词库丰富，智能联想)"
    echo "2. 使用标准 fcitx5 拼音 (简单稳定)"
    echo "3. 仅重启 fcitx5"
    echo "4. 退出"
    echo
    
    read -p "请选择 (1-4): " choice
    
    case "$choice" in
        1)
            switch_to_rime
            ;;
        2)
            switch_to_standard
            ;;
        3)
            restart_fcitx5
            ;;
        4)
            log_info "操作取消"
            exit 0
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
}

# 显示帮助
show_help() {
    cat << EOF
输入法智能管理脚本

用法: $0 <命令>

命令:
    detect      检测当前输入法状态
    rime        切换到 rime + 万象词库
    standard    切换到标准 fcitx5 拼音
    restart     重启 fcitx5
    interactive 交互式配置 (默认)
    help        显示此帮助

示例:
    $0                  # 交互式配置
    $0 detect           # 检测状态
    $0 rime             # 切换到rime
    $0 standard         # 切换到标准拼音
EOF
}

# 主函数
main() {
    case "${1:-interactive}" in
        detect)
            detect_input_method
            ;;
        rime)
            detect_input_method >/dev/null 2>&1
            switch_to_rime
            ;;
        standard)
            detect_input_method >/dev/null 2>&1
            switch_to_standard
            ;;
        restart)
            restart_fcitx5
            ;;
        interactive)
            interactive_setup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"