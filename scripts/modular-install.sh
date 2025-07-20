#!/bin/bash

# 模块化安装脚本
# 支持按需安装不同组件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

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
    
    print_info "检测到发行版: $DISTRO"
}

# 定义软件包组
declare -A PACKAGES=(
    # 核心桌面环境
    [core]="hyprland waybar kitty mako wofi"
    
    # 生产力工具
    [productivity]="oath-toolkit websocat jq"
    
    # 开发工具
    [development]="git curl wget xdotool"
    
    # 办公应用 (主要是窗口规则优化，无需安装额外软件)
    [office]=""
    
    # 截图和媒体
    [media]="grim slurp swappy satty swww"
    
    # 输入法
    [input]="fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
    
    # 系统工具
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
        print_info "安装 $group 组件..."
        
        case "$DISTRO" in
            "arch")
                $PKG_INSTALL $packages
                ;;
            "debian")
                # Debian/Ubuntu 包名映射
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
            "fedora")
                $PKG_INSTALL $packages
                ;;
            *)
                print_warning "未知发行版，请手动安装: $packages"
                ;;
        esac
        
        if [[ -n "$aur_packages" && "$DISTRO" == "arch" ]]; then
            print_info "安装 AUR 包: $aur_packages"
            $AUR_HELPER $aur_packages
        fi
        
        print_success "$group 组件安装完成"
    fi
}

# 配置链接
link_configs() {
    local groups=("$@")
    
    print_info "链接配置文件..."
    
    # 基础配置（始终链接）
    local base_configs=(
        "$DOTFILES_DIR/config/hypr:$HOME/.config/hypr"
        "$DOTFILES_DIR/config/waybar:$HOME/.config/waybar"
        "$DOTFILES_DIR/config/kitty:$HOME/.config/kitty"
        "$DOTFILES_DIR/config/mako:$HOME/.config/mako"
        "$DOTFILES_DIR/config/wofi:$HOME/.config/wofi"
        "$DOTFILES_DIR/shell/bashrc:$HOME/.bashrc"
        "$DOTFILES_DIR/shell/zshrc:$HOME/.zshrc"
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
            "office")
                # Office optimization is mainly handled via Hyprland window rules
                print_info "办公应用优化已通过 Hyprland 窗口规则启用"
                ;;
        esac
    done
    
    # 创建备份并链接
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    for config in "${base_configs[@]}"; do
        IFS=':' read -r src dst <<< "$config"
        
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            print_info "备份: $dst"
            mv "$dst" "$BACKUP_DIR/"
        fi
        
        print_info "链接: $(basename "$src") -> $dst"
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
    done
    
    # 链接脚本
    mkdir -p "$HOME/.local/bin"
    find "$DOTFILES_DIR/scripts" -name "*.sh" -executable | while read -r script; do
        basename_script=$(basename "$script")
        ln -sf "$script" "$HOME/.local/bin/$basename_script"
    done
    
    print_success "配置链接完成，备份保存在: $BACKUP_DIR"
}

# 显示帮助
show_help() {
    cat << EOF
模块化安装脚本

用法: $0 [选项]

选项:
    --core          安装核心桌面环境 (hyprland, waybar, kitty)
    --productivity  安装生产力工具 (TOTP, 天气, 农历)
    --development   安装开发工具 (git, curl, 编辑器集成)
    --office        安装办公应用优化 (微信, 飞书窗口规则)
    --media         安装媒体工具 (截图, 壁纸, 音视频)
    --input         安装输入法支持 (fcitx5, 中文输入)
    --system        安装系统工具 (网络, 蓝牙, 亮度控制)
    --all           安装所有组件 (等同于不加参数)
    --help          显示此帮助信息

示例:
    $0 --core --input                 # 只安装核心环境和输入法
    $0 --all                          # 安装所有组件
    $0 --core --productivity --media  # 自定义组合
EOF
}

# 主函数
main() {
    local install_groups=()
    local install_all=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --core) install_groups+=("core") ;;
            --productivity) install_groups+=("productivity") ;;
            --development) install_groups+=("development") ;;
            --office) install_groups+=("office") ;;
            --media) install_groups+=("media") ;;
            --input) install_groups+=("input") ;;
            --system) install_groups+=("system") ;;
            --all) install_all=true ;;
            --help) show_help; exit 0 ;;
            *) print_error "未知选项: $1"; show_help; exit 1 ;;
        esac
        shift
    done
    
    # 如果没有指定组件或指定了 --all，安装所有组件
    if [[ ${#install_groups[@]} -eq 0 ]] || [[ "$install_all" == true ]]; then
        install_groups=("core" "productivity" "development" "office" "media" "input" "system")
    fi
    
    print_info "开始模块化安装..."
    print_info "将安装组件: ${install_groups[*]}"
    
    # 检测发行版
    detect_distro
    
    # 安装软件包
    for group in "${install_groups[@]}"; do
        install_package_group "$group"
    done
    
    # 链接配置文件
    link_configs "${install_groups[@]}"
    
    print_success "模块化安装完成！"
    print_info "请重新登录或运行 'source ~/.bashrc' 来应用更改"
    
    # 显示后续步骤
    if [[ " ${install_groups[*]} " =~ " productivity " ]]; then
        print_info "TOTP配置: 编辑 ~/.config/totp/secrets.conf 添加验证码"
    fi
    
    if [[ " ${install_groups[*]} " =~ " input " ]]; then
        print_info "输入法配置: 重启后 fcitx5 将自动启动"
    fi
}

# 运行主函数
main "$@"