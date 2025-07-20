#!/bin/bash

# Dotfiles 统一管理脚本
# 整合install.sh、sync.sh、cleanup.sh的功能

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
Dotfiles 管理脚本

用法: $0 <命令> [选项]

命令:
    install [模块...]    安装配置文件 (默认安装全部)
    sync                 同步配置到仓库
    cleanup              清理系统和备份
    backup               创建当前配置备份
    restore <备份名>     恢复指定备份
    status               显示配置状态
    help                 显示此帮助信息

模块 (用于install命令):
    --core              核心配置 (hypr, waybar, etc.)
    --productivity      生产力工具 (pomodoro, totp)
    --development       开发环境 (vscode, shell)
    --themes            主题和美化
    --all               所有模块 (默认)

示例:
    $0 install --core --productivity
    $0 sync
    $0 backup
    $0 restore dotfiles_backup_20240120_143022

EOF
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    for dep in git rsync; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
}

# 安装功能
install_dotfiles() {
    local modules=("$@")
    
    # 如果没有指定模块，默认安装全部
    if [ ${#modules[@]} -eq 0 ]; then
        modules=("--all")
    fi
    
    log_info "开始安装 dotfiles..."
    log_info "备份目录: $BACKUP_DIR"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 调用原始安装脚本
    if [[ " ${modules[*]} " =~ " --all " ]] || [ ${#modules[@]} -eq 0 ]; then
        "$DOTFILES_DIR/install.sh"
    else
        "$DOTFILES_DIR/scripts/modular-install.sh" "${modules[@]}"
    fi
    
    log_success "安装完成！"
}

# 同步功能
sync_dotfiles() {
    log_info "开始同步配置到仓库..."
    
    if [ -f "$DOTFILES_DIR/sync.sh" ]; then
        "$DOTFILES_DIR/sync.sh"
    else
        log_error "sync.sh 脚本不存在"
        exit 1
    fi
    
    log_success "同步完成！"
}

# 清理功能
cleanup_dotfiles() {
    log_info "开始清理系统和备份..."
    
    if [ -f "$DOTFILES_DIR/cleanup.sh" ]; then
        "$DOTFILES_DIR/cleanup.sh"
    else
        log_error "cleanup.sh 脚本不存在"
        exit 1
    fi
    
    log_success "清理完成！"
}

# 备份功能
backup_dotfiles() {
    log_info "创建配置备份..."
    
    # 备份关键配置目录
    local backup_dirs=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.config/fcitx5"
        "$HOME/.config/kitty"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
    )
    
    mkdir -p "$BACKUP_DIR"
    
    for dir in "${backup_dirs[@]}"; do
        if [ -e "$dir" ]; then
            log_info "备份: $dir"
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    log_success "备份创建完成: $BACKUP_DIR"
}

# 恢复功能
restore_dotfiles() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        log_error "请指定备份名称"
        log_info "可用备份:"
        ls -1 "$HOME"/dotfiles_backup_* 2>/dev/null | xargs -I {} basename {} || log_info "  无可用备份"
        exit 1
    fi
    
    local backup_path="$HOME/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        log_error "备份不存在: $backup_path"
        exit 1
    fi
    
    log_info "恢复备份: $backup_name"
    log_warning "这将覆盖当前配置，是否继续? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # 恢复备份
        rsync -av "$backup_path/" "$HOME/" --exclude=".*"
        log_success "备份恢复完成！"
    else
        log_info "已取消恢复操作"
    fi
}

# 状态检查
show_status() {
    log_info "配置文件状态检查..."
    
    echo
    echo "=== 配置文件链接状态 ==="
    
    local config_dirs=(
        ".config/hypr"
        ".config/waybar"
        ".config/fcitx5"
        ".config/kitty"
    )
    
    for dir in "${config_dirs[@]}"; do
        local target="$HOME/$dir"
        if [ -L "$target" ]; then
            local link_target=$(readlink "$target")
            echo "✅ $dir -> $link_target"
        elif [ -d "$target" ]; then
            echo "⚠️  $dir (非链接目录)"
        else
            echo "❌ $dir (不存在)"
        fi
    done
    
    echo
    echo "=== Git 状态 ==="
    cd "$DOTFILES_DIR"
    if git status --porcelain | grep -q .; then
        echo "⚠️  有未提交的修改"
        git status --short
    else
        echo "✅ 工作目录干净"
    fi
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    check_dependencies
    
    local command="$1"
    shift
    
    case "$command" in
        install)
            install_dotfiles "$@"
            ;;
        sync)
            sync_dotfiles
            ;;
        cleanup)
            cleanup_dotfiles
            ;;
        backup)
            backup_dotfiles
            ;;
        restore)
            restore_dotfiles "$@"
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
