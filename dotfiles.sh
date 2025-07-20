#!/bin/bash

# ===========================================
# Dotfiles 统一管理脚本
# ===========================================
# 一个脚本搞定所有操作：安装、同步、备份、维护

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
🚀 Dotfiles 统一管理脚本

用法: $0 <命令> [选项]

📋 主要命令:
    setup                🆕 快速设置 (推荐新用户)
    install [模块...]    安装配置文件 (高级用户)
    sync                 同步配置到仓库
    status               显示配置状态
    backup               创建当前配置备份
    restore <备份名>     恢复指定备份
    cleanup              清理系统和备份
    help                 显示此帮助信息

🔧 模块 (用于install命令):
    --core              核心配置 (hypr, waybar, etc.)
    --productivity      生产力工具 (pomodoro, totp)
    --development       开发环境 (shell, git)
    --themes            主题和美化
    --all               所有模块 (默认)

💡 快速开始:
    1. cp .env.example .env.local
    2. 编辑 .env.local 配置文件
    3. $0 setup

📚 示例:
    $0 setup                              # 快速部署 (推荐)
    $0 install --core --productivity      # 安装指定模块
    $0 sync                               # 同步配置
    $0 status                             # 查看状态
    $0 backup                             # 创建备份

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

# 检测发行版和包管理器
detect_distro() {
    if command -v pacman >/dev/null 2>&1; then
        DISTRO="arch"
        PKG_INSTALL="sudo pacman -S --needed"
        AUR_HELPER="yay -S"
    elif command -v apt >/dev/null 2>&1; then
        DISTRO="debian"
        PKG_INSTALL="sudo apt install -y"
        AUR_HELPER="echo '需要手动安装:'"
    elif command -v dnf >/dev/null 2>&1; then
        DISTRO="fedora"
        PKG_INSTALL="sudo dnf install -y"
        AUR_HELPER="echo '需要手动安装:'"
    else
        DISTRO="unknown"
        PKG_INSTALL="echo '请手动安装:'"
        AUR_HELPER="echo '请手动安装:'"
    fi
    
    log_info "检测到发行版: $DISTRO"
}

# 定义软件包组
declare -A PACKAGES=(
    [core]="hyprland waybar kitty mako wofi"
    [productivity]="oath-toolkit websocat jq"
    [development]="git curl wget xdotool"
    [media]="grim slurp swappy satty swww"
    [input]="fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
    [system]="network-manager-applet blueman brightnessctl playerctl gnome-keyring"
)

declare -A AUR_PACKAGES=(
    [productivity]="lunar-calendar-bin"
    [media]="youtube-music-bin"
)

# 安装软件包组
install_package_group() {
    local group="$1"
    local packages="${PACKAGES[$group]}"
    local aur_packages="${AUR_PACKAGES[$group]}"
    
    if [[ -n "$packages" ]]; then
        log_info "安装 $group 组件..."
        
        case "$DISTRO" in
            "arch")
                $PKG_INSTALL $packages
                ;;
            "debian")
                case "$group" in
                    "core")
                        $PKG_INSTALL hyprland waybar kitty mako-notifier wofi
                        ;;
                    "input")
                        $PKG_INSTALL fcitx5 fcitx5-chinese-addons
                        ;;
                    "system")
                        $PKG_INSTALL network-manager-gnome blueman brightnessctl playerctl gnome-keyring
                        ;;
                    *)
                        $PKG_INSTALL $packages
                        ;;
                esac
                ;;
            *)
                log_warning "未知发行版，请手动安装: $packages"
                ;;
        esac
        
        if [[ -n "$aur_packages" && "$DISTRO" == "arch" ]]; then
            log_info "安装 AUR 包: $aur_packages"
            $AUR_HELPER $aur_packages
        fi
        
        log_success "$group 组件安装完成"
    fi
}

# 配置链接
link_configs() {
    local groups=("$@")
    
    log_info "链接配置文件..."
    
    # 基础配置（始终链接）
    local base_configs=(
        "$DOTFILES_DIR/config/hypr:$HOME/.config/hypr"
        "$DOTFILES_DIR/config/waybar:$HOME/.config/waybar"
        "$DOTFILES_DIR/config/kitty:$HOME/.config/kitty"
        "$DOTFILES_DIR/config/mako:$HOME/.config/mako"
        "$DOTFILES_DIR/config/wofi:$HOME/.config/wofi"
        "$DOTFILES_DIR/shell/bashrc:$HOME/.bashrc"
        "$DOTFILES_DIR/shell/zshrc:$HOME/.zshrc"
        "$DOTFILES_DIR/.Xresources:$HOME/.Xresources"
    )
    
    # 根据组件添加配置
    for group in "${groups[@]}"; do
        case "$group" in
            "input")
                base_configs+=("$DOTFILES_DIR/config/fcitx5:$HOME/.config/fcitx5")
                ;;
            "media")
                base_configs+=("$DOTFILES_DIR/config/swww:$HOME/.config/swww")
                base_configs+=("$DOTFILES_DIR/config/satty:$HOME/.config/satty")
                base_configs+=("$DOTFILES_DIR/config/swappy:$HOME/.config/swappy")
                ;;
            "productivity")
                base_configs+=("$DOTFILES_DIR/config/totp:$HOME/.config/totp")
                ;;
            "development")
                base_configs+=("$DOTFILES_DIR/config/Code:$HOME/.config/Code")
                ;;
        esac
    done
    
    # 创建备份并链接
    mkdir -p "$BACKUP_DIR"
    
    for config in "${base_configs[@]}"; do
        IFS=':' read -r src dst <<< "$config"
        
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            log_info "备份: $dst"
            mv "$dst" "$BACKUP_DIR/"
        fi
        
        log_info "链接: $(basename "$src") -> $dst"
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
    done
    
    # 链接脚本
    mkdir -p "$HOME/.local/bin"
    find "$DOTFILES_DIR/scripts" -name "*.sh" -executable | while read -r script; do
        basename_script=$(basename "$script")
        ln -sf "$script" "$HOME/.local/bin/$basename_script"
    done
    
    # 处理desktop文件
    mkdir -p "$HOME/.local/share/applications"
    if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
        for src in "$DOTFILES_DIR/config/applications"/*.desktop; do
            if [[ -f "$src" ]]; then
                basename_file=$(basename "$src")
                dst="$HOME/.local/share/applications/$basename_file"
                ln -sf "$src" "$dst"
            fi
        done
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
    
    log_success "配置链接完成，备份保存在: $BACKUP_DIR"
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
    
    detect_distro
    
    # 处理模块安装
    local install_groups=()
    if [[ " ${modules[*]} " =~ " --all " ]] || [ ${#modules[@]} -eq 0 ]; then
        install_groups=("core" "productivity" "development" "media" "input" "system")
    else
        for module in "${modules[@]}"; do
            case "$module" in
                --core) install_groups+=("core" "system") ;;
                --productivity) install_groups+=("productivity") ;;
                --development) install_groups+=("development") ;;
                --media) install_groups+=("media") ;;
                --input) install_groups+=("input") ;;
                --themes) log_info "主题通过配置文件自动应用" ;;
            esac
        done
    fi
    
    # 安装软件包
    for group in "${install_groups[@]}"; do
        install_package_group "$group"
    done
    
    # 链接配置
    link_configs "${install_groups[@]}"
    
    log_success "安装完成！"
}

# 同步功能
sync_dotfiles() {
    log_info "开始同步配置到仓库..."
    
    cd "$DOTFILES_DIR"
    
    # 检查是否有变更
    if ! git status --porcelain | grep -q .; then
        log_info "没有需要同步的变更"
        return 0
    fi
    
    # 显示变更
    log_info "检测到以下变更:"
    git status --short
    
    # 确认同步
    log_warning "是否提交这些变更? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "请输入提交信息:"
        read -r commit_message
        
        if [[ -z "$commit_message" ]]; then
            commit_message="update: 配置更新 $(date '+%Y-%m-%d %H:%M')"
        fi
        
        git add .
        git commit -m "$commit_message"
        
        log_info "是否推送到远程仓库? (y/N)"
        read -r push_response
        
        if [[ "$push_response" =~ ^[Yy]$ ]]; then
            git push
            log_success "推送完成！"
        fi
    else
        log_info "已取消同步操作"
        return 0
    fi
    
    log_success "同步完成！"
}

# 清理功能
cleanup_dotfiles() {
    log_info "开始清理系统和备份..."
    
    local cleaned_items=0
    
    # 清理旧备份
    log_info "清理旧备份文件..."
    local backup_dirs=($(ls -dt "$HOME"/dotfiles_backup_* 2>/dev/null | tail -n +6))
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        for backup_dir in "${backup_dirs[@]}"; do
            log_info "删除旧备份: $(basename "$backup_dir")"
            rm -rf "$backup_dir"
            ((cleaned_items++))
        done
    fi
    
    # 清理临时文件
    log_info "清理临时文件..."
    local temp_dirs=(
        "/tmp/screenshots"
        "/tmp/screenshot_*"
        "$HOME/.cache/thumbnails"
        "$HOME/.cache/hypr"
    )
    
    for temp_pattern in "${temp_dirs[@]}"; do
        for temp_path in $temp_pattern; do
            if [[ -e "$temp_path" ]]; then
                log_info "删除临时文件: $temp_path"
                rm -rf "$temp_path"
                ((cleaned_items++))
            fi
        done
    done
    
    # 清理无效的符号链接
    log_info "检查无效的符号链接..."
    local config_dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share/applications"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            find "$config_dir" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r broken_link; do
                log_info "删除无效链接: $broken_link"
                rm -f "$broken_link"
                ((cleaned_items++))
            done
        fi
    done
    
    # 重启服务（可选）
    log_warning "是否重启桌面服务？(y/N)"
    read -r restart_response
    
    if [[ "$restart_response" =~ ^[Yy]$ ]]; then
        log_info "重启桌面服务..."
        
        # 重启 waybar
        if pgrep waybar > /dev/null; then
            pkill waybar
            waybar &
            log_info "重启 waybar"
        fi
        
        # 重启 mako
        if pgrep mako > /dev/null; then
            pkill mako
            mako &
            log_info "重启 mako"
        fi
        
        # 重启 fcitx5
        if pgrep fcitx5 > /dev/null; then
            pkill fcitx5
            fcitx5 -d
            log_info "重启 fcitx5"
        fi
    fi
    
    if [ $cleaned_items -eq 0 ]; then
        log_info "系统已经很干净，没有需要清理的内容"
    else
        log_success "清理完成！共处理 $cleaned_items 个项目"
    fi
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

# 快速设置函数（一键部署）
quick_setup() {
    echo -e "${BLUE}🚀 快速设置 dotfiles...${NC}"
    echo
    
    # 检查 .env.local
    if [[ ! -f "$DOTFILES_DIR/.env.local" ]]; then
        if [[ -f "$DOTFILES_DIR/.env.example" ]]; then
            log_warning "未找到 .env.local 配置文件"
            echo "请先运行："
            echo "  cp .env.example .env.local"
            echo "  编辑 .env.local 文件"
            echo "  然后重新运行 ./dotfiles.sh setup"
            exit 1
        else
            log_error "未找到 .env.example 模板文件"
            exit 1
        fi
    fi
    
    # 加载配置
    source "$DOTFILES_DIR/.env.local"
    log_success "配置文件加载完成"
    
    # 创建必要目录
    log_info "创建目录结构..."
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/var/log/dotfiles"
    mkdir -p "$HOME/.config/totp" && chmod 700 "$HOME/.config/totp"
    
    # 备份现有配置
    backup_dotfiles
    
    # 链接配置文件
    log_info "链接配置文件..."
    ln -sf "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/config/git" "$HOME/.config/"
    
    # 桌面环境配置（如果支持）
    if command -v hyprctl >/dev/null 2>&1; then
        log_info "检测到 Hyprland，链接桌面配置..."
        ln -sf "$DOTFILES_DIR/config/hypr" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/waybar" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/mako" "$HOME/.config/"
        log_success "桌面环境配置完成"
    else
        log_warning "未检测到 Hyprland，跳过桌面环境配置"
    fi
    
    # 设置脚本权限
    log_info "设置脚本权限..."
    find "$DOTFILES_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # 添加到PATH
    if ! grep -q "dotfiles/scripts" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# dotfiles scripts' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/dotfiles/scripts:$PATH"' >> "$HOME/.zshrc"
        log_success "已添加脚本目录到 PATH"
    fi
    
    # 测试配置
    log_info "测试配置..."
    if [[ -x "$DOTFILES_DIR/scripts/load-env.sh" ]]; then
        if "$DOTFILES_DIR/scripts/load-env.sh" >/dev/null 2>&1; then
            log_success "环境配置测试通过"
        else
            log_warning "环境配置测试失败，但继续安装"
        fi
    fi
    
    # 可选服务设置
    echo
    log_info "🔧 可选服务设置："
    
    # 健康提醒
    read -p "启用健康提醒服务？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if [[ -x "$DOTFILES_DIR/scripts/periodic-reminders.sh" ]]; then
            "$DOTFILES_DIR/scripts/periodic-reminders.sh" test >/dev/null 2>&1 && log_success "健康提醒测试成功"
            echo "管理健康提醒："
            echo "  启动: periodic-reminders.sh start"
            echo "  状态: periodic-reminders.sh status"
            echo "  停止: periodic-reminders.sh stop"
        fi
    fi
    
    # 系统监控
    read -p "启用系统监控定时任务？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cron_line="*/30 * * * * $DOTFILES_DIR/scripts/system-monitor-notify.sh"
        if ! crontab -l 2>/dev/null | grep -q "system-monitor-notify.sh"; then
            (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
            log_success "系统监控已启用（每30分钟检查一次）"
        else
            log_info "系统监控已存在"
        fi
    fi
    
    # SDDM 主题配置
    if command -v sddm >/dev/null 2>&1; then
        echo
        read -p "配置 SDDM 登录主题？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            log_info "检查 SDDM 主题依赖..."
            
            # 检查 Sugar Candy 主题是否安装
            if [[ ! -d "/usr/share/sddm/themes/sugar-candy" ]]; then
                log_warning "Sugar Candy 主题未安装"
                echo "请先安装："
                echo "  yay -S sddm-sugar-candy-git"
                echo "然后运行: sudo $DOTFILES_DIR/scripts/fix-sddm-config.sh"
            else
                log_info "发现 Sugar Candy 主题，配置中..."
                echo "需要 sudo 权限配置 SDDM..."
                echo "请运行: sudo $DOTFILES_DIR/scripts/fix-sddm-config.sh"
                echo "然后重启登录管理器: sudo systemctl restart sddm"
            fi
        fi
    else
        log_info "未检测到 SDDM，跳过登录主题配置"
    fi
    
    echo
    log_success "🎉 快速设置完成！"
    echo
    echo -e "${BLUE}📋 接下来的步骤：${NC}"
    echo "  1. 重新打开终端或运行: source ~/.zshrc"
    echo "  2. 根据需要调整 .env.local 配置"
    echo "  3. 享受你的新桌面环境！"
    echo
    echo -e "${BLUE}🔧 常用命令：${NC}"
    echo "  ./dotfiles.sh status           # 查看配置状态"
    echo "  ./dotfiles.sh sync             # 同步配置"
    echo "  ./dotfiles.sh backup           # 备份配置"
    echo "  periodic-reminders.sh start    # 启动健康提醒"
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
        setup)
            quick_setup
            ;;
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
