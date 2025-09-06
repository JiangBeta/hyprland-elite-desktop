#!/bin/bash

# ===========================================
# Dotfiles 管理脚本
# ===========================================
# 一个脚本完成所有操作：安装、同步、备份、维护

set -e

# 获取脚本所在的目录
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 定义备份目录，包含日期和时间戳
BACKUP_DIR="$DOTFILES_DIR/backups/backup_$(date +%Y%m%d_%H%M%S)"
# 最大备份数量
MAX_BACKUPS=5

# 颜色定义，用于日志输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 清理旧的备份（只保留最新的 MAX_BACKUPS 个）
cleanup_old_backups() {
    # 备份的根目录
    local backup_base_dir="$DOTFILES_DIR/backups"
    
    # 如果备份目录不存在，直接返回
    if [[ ! -d "$backup_base_dir" ]]; then
        return 0
    fi
    
    # 计算当前备份的数量
    local backup_count=$(find "$backup_base_dir" -maxdepth 1 -name "backup_*" -type d | wc -l)
    
    # 如果备份数量超过最大值
    if [[ $backup_count -gt $MAX_BACKUPS ]]; then
        local excess_count=$((backup_count - MAX_BACKUPS))
        log_info "找到 $backup_count 个备份，正在删除最旧的 $excess_count 个"
        
        # 找到最旧的备份并删除
        find "$backup_base_dir" -maxdepth 1 -name "backup_*" -type d -printf '%T@ %p\n' | \
        sort -n | \
        head -n $excess_count | \
        cut -d' ' -f2- | \
        while read -r old_backup; do
            log_info "正在删除旧备份: $(basename "$old_backup")"
            rm -rf "$old_backup"
        done
    fi
}

# 日志输出函数
log_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
🚀 Dotfiles 管理脚本

用法: $0 <命令> [选项]

📋 主要命令:
    setup                🆕 快速设置 (推荐新用户使用)
    install [modules...] 安装配置文件 (高级用户)
    sync                 同步配置到仓库
    status               显示配置状态
    backup               创建当前配置的备份
    restore <name>       恢复指定备份
    cleanup              清理系统和备份
    help                 显示此帮助信息
    input-method         设置输入法 (fcitx5/rime)

🔧 模块 (用于 install 命令):
    --core              核心配置 (hypr, waybar 等)
    --productivity      生产力工具 (pomodoro, totp)
    --development       开发环境 (shell, git)
    --themes            主题和美化
    --all               所有模块 (默认)

💡 快速开始:
    1. cp .env.example .env.local
    2. 编辑 .env.local 配置文件
    3. $0 setup

📚 例子:
    $0 setup                          # 快速部署 (推荐)
    $0 install --core --productivity      # 安装特定模块
    $0 sync                               # 同步配置
    $0 status                             # 检查状态
    $0 backup                             # 创建备份

EOF
}

# 检查依赖项
check_dependencies() {
    local missing_deps=()
    
    # 检查 git 和 rsync 是否已安装
    for dep in git rsync; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # 如果有缺少的依赖项，报错并退出
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖项: ${missing_deps[*]}"
        log_info "请安装缺少的依赖项后重试"
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
        PKG_INSTALL="echo '需要手动安装:'"
        AUR_HELPER="echo '需要手动安装:'"
    fi
    
    log_info "检测到发行版: $DISTRO"
}

# 定义包组
declare -A PACKAGES=(
    [core]="hyprland waybar kitty mako"
    [productivity]="oath-toolkit websocat jq"
    [development]="git curl wget xdotool"
    [media]="grim slurp swappy satty swww"
    [input]="fcitx5 fcitx5-rime rime-pinyin-simp fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
    [system]="network-manager-applet blueman brightnessctl playerctl gnome-keyring"
)

# 定义 AUR 包组
declare -A AUR_PACKAGES=(
    [core]="ulauncher"
    [productivity]="lunar-calendar-bin"
    [media]="youtube-music-bin"
)

# 安装包组
install_package_group() {
    local group="$1"
    local packages="${PACKAGES[$group]}"
    local aur_packages="${AUR_PACKAGES[$group]}"
    
    if [[ -n "$packages" ]]; then
        log_info "正在安装 $group 组件..."
        
        case "$DISTRO" in
            "arch")
                $PKG_INSTALL $packages
                ;;
            "debian")
                case "$group" in
                    "core")
                        $PKG_INSTALL hyprland waybar kitty mako ulauncher
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
            log_info "正在安装 AUR 包: $aur_packages"
            $AUR_HELPER $aur_packages
        fi
        
        log_success "$group 组件安装完成"
    fi
}

# 链接配置文件
link_configs() {
    local groups=("$@")
    
    log_info "正在链接配置文件..."
    
    # 基础配置（总是被链接）
    local base_configs=(
        "$DOTFILES_DIR/config/hypr:$HOME/.config/hypr"
        "$DOTFILES_DIR/config/waybar:$HOME/.config/waybar"
        "$DOTFILES_DIR/config/kitty:$HOME/.config/kitty"
        "$DOTFILES_DIR/config/mako:$HOME/.config/mako"
        "$DOTFILES_DIR/config/wofi:$HOME/.config/wofi"
        "$DOTFILES_DIR/shell/bashrc:$HOME/.bashrc"
        "$DOTFILES_DIR/shell/zshrc:$HOME/.zshrc"
        "$DOTFILES_DIR/claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
        "$DOTFILES_DIR/.Xresources:$HOME/.Xresources"
    )
    
    # 根据组件添加额外配置
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
    
    # 在创建新备份前清理旧备份
    cleanup_old_backups
    
    for config in "${base_configs[@]}"; do
        IFS=':' read -r src dst <<< "$config"
        
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            log_info "正在备份: $dst"
            mv "$dst" "$BACKUP_DIR/"
        fi
        
        log_info "正在链接: $(basename "$src") -> $dst"
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
    done
    
    # 链接脚本
    mkdir -p "$HOME/.local/bin"
    find "$DOTFILES_DIR/scripts" -name "*.sh" -executable | while read -r script; do
        basename_script=$(basename "$script")
        ln -sf "$script" "$HOME/.local/bin/$basename_script"
    done
    
    # 处理桌面文件
    mkdir -p "$HOME/.local/share/applications"
    if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
        log_info "正在链接应用启动器..."
        for src in "$DOTFILES_DIR/config/applications"/*.desktop; do
            if [[ -f "$src" ]]; then
                basename_file=$(basename "$src")
                dst="$HOME/.local/share/applications/$basename_file"
                ln -sf "$src" "$dst"
                log_success "  ✓ $basename_file"
            fi
        done
        
        # 更新桌面数据库缓存
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
            log_success "桌面应用缓存已更新"
        fi
    fi
    
    log_success "配置链接完成，备份保存在: $BACKUP_DIR"
}

# 安装函数
install_dotfiles() {
    local modules=("$@")
    
    # 如果没有指定模块，默认安装所有
    if [ ${#modules[@]} -eq 0 ]; then
        modules=("--all")
    fi
    
    log_info "正在开始 dotfiles 安装..."
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
    
    # 安装包
    for group in "${install_groups[@]}"; do
        install_package_group "$group"
    done
    
    # 链接配置
    link_configs "${install_groups[@]}"
    
    log_success "安装完成!"
}

# 同步函数
sync_dotfiles() {
    log_info "正在开始同步配置到仓库..."
    
    cd "$DOTFILES_DIR"
    
    # 检查是否有改动
    if ! git status --porcelain | grep -q .; then
        log_info "没有需要同步的改动"
        return 0
    fi
    
    # 显示改动
    log_info "检测到以下改动:"
    git status --short
    
    # 确认同步
    log_warning "提交这些改动吗? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "请输入提交信息:"
        read -r commit_message
        
        if [[ -z "$commit_message" ]]; then
            commit_message="更新: 配置更新 $(date '+%Y-%m-%d %H:%M')"
        fi
        
        git add .
        git commit -m "$commit_message"
        
        log_info "推送到远程仓库吗? (y/N)"
        read -r push_response
        
        if [[ "$push_response" =~ ^[Yy]$ ]]; then
            git push
            log_success "推送完成!"
        fi
    else
        log_info "同步操作已取消"
        return 0
    fi
    
    log_success "同步完成!"
}

# 清理函数
cleanup_dotfiles() {
    log_info "正在开始清理系统和备份..."
    
    local cleaned_items=0
    
    # 清理旧的备份（只保留最新的 MAX_BACKUPS 个）
    log_info "正在清理旧的备份文件..."
    local backup_base_dir="$DOTFILES_DIR/backups"
    if [[ -d "$backup_base_dir" ]]; then
        local backup_count=$(find "$backup_base_dir" -maxdepth 1 -name "backup_*" -type d | wc -l)
        if [[ $backup_count -gt $MAX_BACKUPS ]]; then
            local excess_count=$((backup_count - MAX_BACKUPS))
            log_info "找到 $backup_count 个备份，正在删除最旧的 $excess_count 个"
            
            find "$backup_base_dir" -maxdepth 1 -name "backup_*" -type d -printf '%T@ %p\n' | \
            sort -n | \
            head -n $excess_count | \
            cut -d' ' -f2- | \
            while read -r old_backup; do
                log_info "正在删除旧备份: $(basename "$old_backup")"
                rm -rf "$old_backup"
                ((cleaned_items++))
            done
        fi
    fi
    
    # 同时也清理主目录下任何旧风格的备份
    local old_backup_dirs=($(ls -dt "$HOME"/dotfiles_backup_* 2>/dev/null))
    if [ ${#old_backup_dirs[@]} -gt 0 ]; then
        for backup_dir in "${old_backup_dirs[@]}"; do
            log_info "正在删除旧式备份: $(basename "$backup_dir")"
            rm -rf "$backup_dir"
            ((cleaned_items++))
        done
    fi
    
    # 清理临时文件
    log_info "正在清理临时文件..."
    local temp_dirs=(
        "/tmp/screenshots"
        "/tmp/screenshot_*"
        "$HOME/.cache/thumbnails"
        "$HOME/.cache/hypr"
    )
    
    for temp_pattern in "${temp_dirs[@]}"; do
        for temp_path in $temp_pattern; do
            if [[ -e "$temp_path" ]]; then
                log_info "正在删除临时文件: $temp_path"
                rm -rf "$temp_path"
                ((cleaned_items++))
            fi
        done
    done
    
    # 清理无效的符号链接
    log_info "正在检查无效的符号链接..."
    local config_dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share/applications"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            find "$config_dir" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r broken_link; do
                log_info "正在删除无效链接: $broken_link"
                rm -f "$broken_link"
                ((cleaned_items++))
            done
        fi
    done
    
    # 重启服务（可选）
    log_warning "重启桌面服务吗? (y/N)"
    read -r restart_response
    
    if [[ "$restart_response" =~ ^[Yy]$ ]]; then
        log_info "正在重启桌面服务..."
        
        # 重启 waybar
        if pgrep waybar > /dev/null; then
            pkill waybar
            waybar &
            log_info "已重启 waybar"
        fi
        
        # 重启 mako
        if pgrep mako > /dev/null; then
            pkill mako
            mako &
            log_info "已重启 mako"
        fi
        
        # 重启 fcitx5
        if pgrep fcitx5 > /dev/null; then
            pkill fcitx5
            fcitx5 -d
            log_info "已重启 fcitx5"
        fi
    fi
    
    if [ $cleaned_items -eq 0 ]; then
        log_info "系统已经很干净了，没有需要清理的"
    else
        log_success "清理完成! 处理了 $cleaned_items 项"
    fi
}

# 备份函数
backup_dotfiles() {
    log_info "正在创建配置备份..."
    
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
    
    # 在创建新备份前清理旧备份
    cleanup_old_backups
    
    for dir in "${backup_dirs[@]}"; do
        if [ -e "$dir" ]; then
            log_info "正在备份: $dir"
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    log_success "备份创建完成: $BACKUP_DIR"
}

# 恢复函数
restore_dotfiles() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        log_error "请指定备份名称"
        log_info "可用备份:"
        find "$DOTFILES_DIR/backups" -maxdepth 1 -name "backup_*" -type d 2>/dev/null | xargs -I {} basename {} || log_info "  没有可用备份"
        exit 1
    fi
    
    # 支持完整路径和仅备份名称
    if [[ "$backup_name" == backup_* ]]; then
        local backup_path="$DOTFILES_DIR/backups/$backup_name"
    else
        local backup_path="$backup_name"
    fi
    
    if [ ! -d "$backup_path" ]; then
        log_error "备份不存在: $backup_path"
        exit 1
    fi
    
    log_info "正在恢复备份: $backup_name"
    log_warning "这将覆盖当前配置，是否继续? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # 恢复备份
        rsync -av "$backup_path/" "$HOME/" --exclude=".*"
        log_success "备份恢复完成!"
    else
        log_info "恢复操作已取消"
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
        echo "⚠️  有未提交的改动"
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
            echo "请先运行:"
            echo "  cp .env.example .env.local"
            echo "  编辑 .env.local 文件"
            echo "  然后重新运行 ./dotfiles.sh setup"
            exit 1
        else
            log_error "模板文件 .env.example 不存在"
            exit 1
        fi
    fi
    
    # 加载配置
    source "$DOTFILES_DIR/.env.local"
    log_success "配置文件加载成功"
    
    # 创建必要的目录
    log_info "正在创建目录结构..."
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/var/log/dotfiles"
    mkdir -p "$HOME/.config/totp" && chmod 700 "$HOME/.config/totp"
    mkdir -p "$HOME/.claude"
    
    # 备份现有配置
    backup_dotfiles
    
    # 链接配置文件
    log_info "正在链接配置文件..."
    ln -sf "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
    
    # 小心处理 git 配置目录
    if [[ -d "$HOME/.config/git" && ! -L "$HOME/.config/git" ]]; then
        log_warning "正在备份现有的 git 目录"
        mv "$HOME/.config/git" "$HOME/.config/git.backup.$(date +%s)"
    fi
    ln -sf "$DOTFILES_DIR/config/git" "$HOME/.config/"
    
    # 桌面环境配置（如果支持）
    if command -v hyprctl >/dev/null 2>&1; then
        log_info "检测到 Hyprland，正在链接桌面配置..."
        ln -sf "$DOTFILES_DIR/config/hypr" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/waybar" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/mako" "$HOME/.config/"
        log_success "桌面环境配置完成"
    else
        log_warning "未检测到 Hyprland，跳过桌面环境配置"
    fi
    
    log_success "桌面环境配置完成"
    
    # 修复系统桌面文件以获得更好的功能
    echo
    log_info "🔧 系统桌面文件修复"
    echo "一些应用程序需要系统级修复以获得更好的功能:"
    echo "  • WPS Office: 字体渲染修复"
    echo "  • VSCode: Wayland 支持改进"
    echo
    read -p "应用系统桌面文件修复吗? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "跳过桌面文件修复"
    else
        log_info "正在应用桌面文件修复..."
        if [[ -x "$DOTFILES_DIR/scripts/patch-desktop-files.sh" ]]; then
            sudo "$DOTFILES_DIR/scripts/patch-desktop-files.sh"
            if [[ $? -eq 0 ]]; then
                log_success "桌面文件修复应用成功"
            else
                log_warning "桌面文件修复失败，但继续进行"
            fi
        else
            log_warning "未找到桌面文件修复脚本"
        fi
    fi
    
    # 检查并安装额外字体以获得更好的 WPS 渲染
    echo
    log_info "🔤 字体包检查"
    echo "更好的字体渲染需要额外的字体包."
    echo "正在检查缺少的字体包..."
    
    missing_fonts=()
    
    # 检查 Windows 字体 (ttf-ms-fonts)
    if ! fc-list | grep -i "times new roman" >/dev/null 2>&1; then
        missing_fonts+=("ttf-ms-fonts (Windows 字体)")
    fi
    
    # 检查 liberation 字体
    if ! fc-list | grep -i "liberation" >/dev/null 2>&1; then
        missing_fonts+=("ttf-liberation (Liberation 字体)")
    fi
    
    if [ ${#missing_fonts[@]} -gt 0 ]; then
        echo "缺少的字体包:"
        for font in "${missing_fonts[@]}"; do
            echo "  • $font"
        done
        echo
        read -p "安装缺少的字体包吗? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log_info "正在安装字体包..."
            
            # 尝试安装缺少的字体
            if command -v yay >/dev/null 2>&1; then
                if [[ " ${missing_fonts[@]} " =~ "ttf-ms-fonts" ]]; then
                    yay -S ttf-ms-fonts --noconfirm || log_warning "安装 ttf-ms-fonts 失败"
                fi
                if [[ " ${missing_fonts[@]} " =~ "ttf-liberation" ]]; then
                    sudo pacman -S ttf-liberation --noconfirm || log_warning "安装 ttf-liberation 失败"
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if [[ " ${missing_fonts[@]} " =~ "ttf-liberation" ]]; then
                    sudo pacman -S ttf-liberation --noconfirm || log_warning "安装 ttf-liberation 失败"
                fi
                log_info "对于 ttf-ms-fonts，请先安装一个 AUR 助手，例如 yay"
            fi
            
            log_success "字体安装完成"
        else
            log_info "跳过字体安装"
        fi
    else
        log_success "所有推荐字体已安装"
    fi
    
    # 设置脚本权限
    log_info "正在设置脚本权限..."
    find "$DOTFILES_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # 添加到 PATH
    if ! grep -q "dotfiles/scripts" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# dotfiles 脚本' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/dotfiles/scripts:$PATH"' >> "$HOME/.zshrc"
        log_success "脚本目录已添加到 PATH"
    fi
    
    # 测试配置
    log_info "正在测试配置..."
    if [[ -x "$DOTFILES_DIR/scripts/load-env.sh" ]]; then
        if "$DOTFILES_DIR/scripts/load-env.sh" >/dev/null 2>&1; then
            log_success "环境变量配置测试通过"
        else
            log_warning "环境变量配置测试失败，但继续安装"
        fi
    fi
    
    # 初始化代理配置
    echo
    log_info "🌐 正在初始化代理配置..."
    if [[ -x "$DOTFILES_DIR/scripts/generate-proxy-env.sh" ]]; then
        "$DOTFILES_DIR/scripts/generate-proxy-env.sh"
        log_success "代理配置已初始化"
        echo "  代理设置可以在 .env.local 中修改"
        echo "  使用 ENABLE_PROXY=true/false 来切换代理"
    else
        log_warning "未找到代理配置脚本"
    fi
    
    # 可选服务设置
    echo
    log_info "🔧 可选服务设置:"
    
    # 健康提醒
    read -p "启用健康提醒服务吗? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if [[ -x "$DOTFILES_DIR/scripts/periodic-reminders.sh" ]]; then
            "$DOTFILES_DIR/scripts/periodic-reminders.sh" test >/dev/null 2>&1 && log_success "健康提醒测试成功"
            echo "管理健康提醒:"
            echo "  开始: periodic-reminders.sh start"
            echo "  状态: periodic-reminders.sh status"
            echo "  停止: periodic-reminders.sh stop"
        fi
    fi
    
    # 系统监控
    read -p "启用系统监控 cron 任务吗? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cron_line="*/30 * * * * $DOTFILES_DIR/scripts/system-monitor-notify.sh"
        if ! crontab -l 2>/dev/null | grep -q "system-monitor-notify.sh"; then
            (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
            log_success "系统监控已启用 (每 30 分钟检查一次)"
        else
            log_info "系统监控已存在"
        fi
    fi
    
    # SDDM 主题配置
    if command -v sddm >/dev/null 2>&1; then
        echo
        read -p "配置 SDDM 登录主题吗? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            log_info "正在检查 SDDM 主题依赖..."
            
            # 检查 astronaut 主题是否已安装
            if [[ ! -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]]; then
                log_warning "sddm-astronaut-theme 未安装"
                echo "请先安装:"
                echo "  yay -S sddm-astronaut-theme"
                echo "然后配置: sudo cp $DOTFILES_DIR/config/sddm/sddm.conf /etc/sddm.conf"
            else
                log_info "找到 sddm-astronaut-theme，正在配置..."
                echo "正在复制 SDDM 配置..."
                sudo cp "$DOTFILES_DIR/config/sddm/sddm.conf" /etc/sddm.conf
                log_success "SDDM 主题配置成功"
                echo "重启 SDDM 以应用: sudo systemctl restart sddm"
            fi
        fi
    else
        log_info "未检测到 SDDM，跳过登录主题配置"
    fi
    
    echo
    log_success "🎉 快速设置完成!"
    echo
    echo -e "${BLUE}📋 下一步:${NC}"
    echo "  1. 重新打开终端或运行: source ~/.zshrc"
    echo "  2. 根据需要调整 .env.local 配置"
    echo "  3. 设置输入法: ./dotfiles.sh input-method"
    echo "  4. 享受你的新桌面环境!"
    echo
    echo -e "${BLUE}🔧 常用命令:${NC}"
    echo "  ./dotfiles.sh status           # 检查配置状态"
    echo "  ./dotfiles.sh sync             # 同步配置"
    echo "  ./dotfiles.sh backup           # 备份配置"
    echo "  ./dotfiles.sh input-method     # 设置输入法 (fcitx5/rime)"
    echo "  periodic-reminders.sh start    # 启动健康提醒"
}

# 输入法智能配置
setup_input_method() {
    echo -e "${BLUE}🔤 输入法配置${NC}"
    echo
    
    # 检测环境
    local has_fcitx5=false
    local has_rime=false
    local has_wanxiang=false
    
    if command -v fcitx5 >/dev/null 2>&1; then
        has_fcitx5=true
    fi
    
    if command -v rime_deployer >/dev/null 2>&1; then
        has_rime=true
    fi
    
    if [[ -d "$HOME/.local/share/fcitx5/rime" ]] && [[ -n "$(find "$HOME/.local/share/fcitx5/rime" -name "*.dict.yaml" 2>/dev/null | head -1)" ]]; then
        has_wanxiang=true
    fi
    
    echo "当前输入法状态:"
    echo "  • fcitx5: $($has_fcitx5 && echo "✅ 已安装" || echo "❌ 未找到")"
    echo "  • fcitx5-rime: $($has_rime && echo "✅ 已安装" || echo "❌ 未找到")" 
    echo "  • 万象词库: $($has_wanxiang && echo "✅ 可用" || echo "❌ 未找到")"
    
    if [[ -L "$HOME/.config/fcitx5" ]]; then
        local link_target=$(readlink "$HOME/.config/fcitx5")
        echo "  • 当前配置: $(basename "$link_target")"
    elif [[ -d "$HOME/.config/fcitx5" ]]; then
        echo "  • 当前配置: 本地目录 (未链接)"
    else
        echo "  • 当前配置: 不存在"
    fi
    
    echo
    
    if ! $has_fcitx5; then
        log_error "fcitx5 未安装. 请先安装:"
        echo "sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
        return 1
    fi
    
    echo "可用输入法选项:"
    echo "  1. 增强 rime + 万象词库 (词汇丰富，智能预测)"
    echo "  2. 标准 fcitx5 拼音 (简单，稳定)"
    echo "  3. 仅重启 fcitx5"
    echo "  4. 取消"
    echo
    
    read -p "请选择 (1-4): " -n 1 -r choice
    echo
    echo
    
    case "$choice" in
        1)
            if ! $has_rime; then
                log_error "fcitx5-rime 未安装. 请先安装:"
                echo "sudo pacman -S fcitx5-rime"
                return 1
            fi
            
            log_info "正在设置 rime + 万象词库..."
            
            # 备份现有配置
            if [[ -d "$HOME/.config/fcitx5" && ! -L "$HOME/.config/fcitx5" ]]; then
                local backup_name="fcitx5.backup.$(date +%s)"
                mv "$HOME/.config/fcitx5" "$HOME/$backup_name"
                log_info "已将现有配置备份到: ~/$backup_name"
            fi
            
            # 使用软链接链接 fcitx5-rime 配置
            rm -rf "$HOME/.config/fcitx5"
            ln -sf "$DOTFILES_DIR/config/fcitx5-rime" "$HOME/.config/fcitx5"
            
            # 安装万象词库
            log_info "正在安装万象词库..."
            if [[ -x "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" ]]; then
                "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" install
            else
                log_warning "万象词库安装脚本不存在"
                log_info "你可以手动从以下地址下载词库："
                echo "https://github.com/amzxyz/rime_wanxiang"
                echo "解压到: $HOME/.local/share/fcitx5/rime/"
            fi
            
            restart_input_method
            log_success "rime + 万象词库配置成功!"
            ;;
            
        2)
            log_info "正在设置标准 fcitx5 拼音..."
            
            # 使用标准配置
            rm -f "$HOME/.config/fcitx5"
            if [[ -d "$DOTFILES_DIR/config/fcitx5-fallback" ]]; then
                ln -sf "$DOTFILES_DIR/config/fcitx5-fallback" "$HOME/.config/fcitx5"
                log_info "正在使用备用配置"
            else
                ln -sf "$DOTFILES_DIR/config/fcitx5" "$HOME/.config/fcitx5"
                log_info "正在使用标准配置"
            fi
            
            restart_input_method
            log_success "标准 fcitx5 拼音配置成功!"
            ;;
            
        3)
            restart_input_method
            ;;
        4)
            log_info "操作已取消"
            return 0
            ;;
        *)
            log_error "无效的选择"
            return 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}✅ 输入法配置完成!${NC}"
    echo
    echo "用法:"
    echo "  • 切换输入法: Ctrl+Space" 
    echo "  • 配置: fcitx5-configtool"
    echo "  • 在任意应用中测试输入"
    
    if $has_rime; then
        echo "  • Rime 设置: Ctrl+\` (反引号)"
        echo "  • 部署配置: rime_deployer"
    fi
}

# 重启输入法服务
restart_input_method() {
    log_info "正在重启输入法服务..."
    
    # 重启 fcitx5
    if pgrep fcitx5 >/dev/null; then
        pkill fcitx5
        sleep 1
    fi
    
    fcitx5 -d
    log_success "输入法服务已重启"
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
        input-method)
            setup_input_method
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