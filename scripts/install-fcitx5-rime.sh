#!/bin/bash
# Fcitx5 + Rime 输入法快速安装脚本
# 提供多种安装选项

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           Fcitx5 + Rime 输入法安装器            ║"
    echo "║                                                  ║"
    echo "║  支持万象拼音、明月拼音等多种输入方案            ║"
    echo "║  已修复标点符号、Shift键、云拼音等问题           ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_options() {
    echo -e "${CYAN}请选择安装方式：${NC}"
    echo
    echo -e "${GREEN}1.${NC} 完整安装 (推荐)"
    echo "   - fcitx5 + rime + 万象拼音词库"
    echo "   - 包含所有优化配置"
    echo
    echo -e "${GREEN}2.${NC} 基础安装"
    echo "   - fcitx5 + rime基础配置"
    echo "   - 支持明月拼音简体"
    echo
    echo -e "${GREEN}3.${NC} 最小安装"
    echo "   - 仅安装必要包，手动配置"
    echo
    echo -e "${GREEN}4.${NC} 仅更新配置"
    echo "   - 假设已安装软件包，仅更新dotfiles配置"
    echo
    echo -e "${GREEN}5.${NC} 修复现有配置"
    echo "   - 修复标点符号、Shift键等问题"
    echo
}

check_system() {
    log_step "检查系统环境..."
    
    # 检查是否为Arch Linux
    if ! command -v pacman >/dev/null 2>&1; then
        log_warning "未检测到pacman，可能不是Arch Linux系统"
        log_info "安装命令可能需要调整"
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_warning "网络连接可能有问题，下载可能会失败"
    fi
    
    log_success "系统环境检查完成"
}

install_packages() {
    local level=$1
    
    log_step "安装软件包..."
    
    case $level in
        "full"|"basic")
            log_info "安装完整fcitx5套件..."
            echo "请执行以下命令："
            echo "sudo pacman -S fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool"
            echo
            read -p "按回车键继续，或Ctrl+C退出..."
            ;;
        "minimal")
            log_info "安装最小包..."
            echo "请执行以下命令："
            echo "sudo pacman -S fcitx5 fcitx5-rime"
            echo
            read -p "按回车键继续，或Ctrl+C退出..."
            ;;
        "config-only")
            log_info "跳过软件包安装..."
            ;;
    esac
}

configure_basic() {
    log_step "配置基础Rime..."
    
    if [[ -x "$SCRIPT_DIR/setup-rime.sh" ]]; then
        "$SCRIPT_DIR/setup-rime.sh"
        log_success "基础Rime配置完成"
    else
        log_error "setup-rime.sh脚本不存在"
        return 1
    fi
}

configure_wanxiang() {
    log_step "配置万象拼音..."
    
    if [[ -x "$SCRIPT_DIR/setup-rime-wanxiang.sh" ]]; then
        "$SCRIPT_DIR/setup-rime-wanxiang.sh" install
        log_success "万象拼音配置完成"
    else
        log_error "setup-rime-wanxiang.sh脚本不存在"
        return 1
    fi
}

update_dotfiles_config() {
    log_step "同步dotfiles配置..."
    
    # 确保配置文件存在
    local rime_dir="$HOME/.local/share/fcitx5/rime"
    mkdir -p "$rime_dir"
    
    # 复制主要配置文件
    configs=(
        "default.yaml"
        "wanxiang.custom.yaml" 
        "wanxiang_pro.custom.yaml"
        "luna_pinyin_simp.custom.yaml"
    )
    
    for config in "${configs[@]}"; do
        if [[ -f "$DOTFILES_DIR/config/fcitx5-rime/$config" ]]; then
            cp "$DOTFILES_DIR/config/fcitx5-rime/$config" "$rime_dir/"
            log_info "已更新 $config"
        fi
    done
    
    log_success "配置文件同步完成"
}

deploy_rime() {
    log_step "部署Rime配置..."
    
    local rime_dir="$HOME/.local/share/fcitx5/rime"
    
    if command -v rime_deployer >/dev/null 2>&1; then
        rime_deployer --build "$rime_dir" 2>/dev/null || true
        log_success "Rime配置部署完成"
    else
        log_warning "rime_deployer命令不存在，请手动执行部署"
    fi
}

restart_fcitx5() {
    log_step "重启fcitx5..."
    
    if command -v fcitx5-remote >/dev/null 2>&1; then
        fcitx5-remote -r 2>/dev/null || true
        log_success "fcitx5已重启"
    else
        log_warning "请手动重启fcitx5"
    fi
}

run_test() {
    log_step "运行配置测试..."
    
    if [[ -x "$SCRIPT_DIR/test-fcitx5-rime.sh" ]]; then
        echo
        "$SCRIPT_DIR/test-fcitx5-rime.sh"
    else
        log_warning "测试脚本不存在，请手动验证"
    fi
}

fix_existing_config() {
    log_step "修复现有配置问题..."
    
    local rime_dir="$HOME/.local/share/fcitx5/rime"
    
    # 备份现有配置
    if [[ -d "$rime_dir" ]]; then
        local backup_dir="$rime_dir.backup.$(date +%s)"
        cp -r "$rime_dir" "$backup_dir"
        log_info "已备份现有配置到: $backup_dir"
    fi
    
    # 更新配置
    update_dotfiles_config
    deploy_rime
    restart_fcitx5
    
    log_success "配置修复完成"
}

show_final_instructions() {
    echo
    log_success "安装完成！"
    echo
    echo -e "${CYAN}使用说明：${NC}"
    echo "• Ctrl+Space: 切换中英文"
    echo "• Ctrl+\`: 选择输入方案"
    echo "• Shift: 临时输入英文（不提交候选词）"
    echo "• F4: 切换简繁体"
    echo
    echo -e "${CYAN}注意事项：${NC}"
    echo "• 重启系统或重新登录以确保环境变量生效"
    echo "• 如有问题，运行: $SCRIPT_DIR/test-fcitx5-rime.sh"
    echo "• 文档位置: $DOTFILES_DIR/docs/fcitx5-rime-config.md"
    echo
}

main() {
    show_banner
    
    case "${1:-interactive}" in
        "full")
            check_system
            install_packages "full"
            configure_basic
            configure_wanxiang
            deploy_rime
            restart_fcitx5
            run_test
            show_final_instructions
            ;;
        "basic")
            check_system
            install_packages "basic"
            configure_basic
            deploy_rime
            restart_fcitx5
            run_test
            show_final_instructions
            ;;
        "minimal")
            check_system
            install_packages "minimal"
            configure_basic
            deploy_rime
            restart_fcitx5
            show_final_instructions
            ;;
        "config-only")
            update_dotfiles_config
            deploy_rime
            restart_fcitx5
            run_test
            show_final_instructions
            ;;
        "fix")
            fix_existing_config
            run_test
            show_final_instructions
            ;;
        "interactive"|*)
            show_options
            echo -n "请输入选项 [1-5]: "
            read -r choice
            
            case $choice in
                1) exec "$0" full ;;
                2) exec "$0" basic ;;
                3) exec "$0" minimal ;;
                4) exec "$0" config-only ;;
                5) exec "$0" fix ;;
                *) 
                    log_error "无效选项"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

main "$@"