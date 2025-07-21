#!/bin/bash
# 万象输入法词库安装脚本

set -e

RIME_DIR="$HOME/.local/share/fcitx5/rime"
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

# 检查rime是否安装
check_rime() {
    if ! command -v rime_deployer >/dev/null 2>&1; then
        log_error "rime_deployer not found, please install fcitx5-rime first"
        return 1
    fi
    
    if ! pgrep fcitx5 >/dev/null; then
        log_warning "fcitx5 is not running, please start it first"
    fi
    
    return 0
}

# 创建rime配置目录
setup_rime_dirs() {
    log_info "Setting up rime directories..."
    
    mkdir -p "$RIME_DIR"
    
    # 备份现有配置
    if [[ -f "$RIME_DIR/default.yaml" ]]; then
        cp "$RIME_DIR/default.yaml" "$RIME_DIR/default.yaml.backup.$(date +%s)"
        log_info "Backed up existing default.yaml"
    fi
}

# 安装基础rime配置
install_basic_config() {
    log_info "Installing basic rime configuration..."
    
    # 复制基础配置文件
    cp "$DOTFILES_DIR/config/fcitx5-rime/default.yaml" "$RIME_DIR/"
    cp "$DOTFILES_DIR/config/fcitx5-rime/luna_pinyin_simp.custom.yaml" "$RIME_DIR/"
    
    log_success "Basic rime configuration installed"
}

# 下载万象词库（多源策略）
download_wanxiang() {
    log_info "Setting up 万象 dictionary..."
    
    # 多个下载源，按优先级排序
    local sources=(
        "https://github.com/amzxyz/rime_wanxiang.git"
        "https://gitee.com/amzxyz/rime_wanxiang.git" 
        "https://hub.fastgit.xyz/amzxyz/rime_wanxiang.git"
    )
    
    local temp_dir="/tmp/rime_wanxiang_$$"
    local success=false
    
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git not found, please install git first:"
        echo "sudo pacman -S git"
        return 1
    fi
    
    # 尝试各个源
    for url in "${sources[@]}"; do
        log_info "Trying source: $url"
        
        if timeout 30 git clone --depth 1 "$url" "$temp_dir" 2>/dev/null; then
            log_success "Successfully cloned from: $url"
            success=true
            break
        else
            log_warning "Failed to clone from: $url"
            rm -rf "$temp_dir" 2>/dev/null
        fi
    done
    
    if ! $success; then
        log_error "All download sources failed"
        log_info "Manual installation options:"
        echo "1. 直接下载: https://github.com/amzxyz/rime_wanxiang/archive/refs/heads/master.zip"
        echo "2. 解压到: $RIME_DIR"
        echo "3. 运行: rime_deployer"
        return 1
    fi
    
    # 复制词库文件
    log_info "Installing dictionary files..."
    local file_count=0
    
    if [[ -d "$temp_dir" ]]; then
        # 复制各类配置文件
        while IFS= read -r -d '' file; do
            cp "$file" "$RIME_DIR/" 2>/dev/null && ((file_count++))
        done < <(find "$temp_dir" -name "*.yaml" -print0)
        
        while IFS= read -r -d '' file; do
            cp "$file" "$RIME_DIR/" 2>/dev/null && ((file_count++))
        done < <(find "$temp_dir" -name "*.dict.yaml" -print0)
        
        while IFS= read -r -d '' file; do
            cp "$file" "$RIME_DIR/" 2>/dev/null && ((file_count++))
        done < <(find "$temp_dir" -name "*.schema.yaml" -print0)
        
        log_success "Installed $file_count dictionary files"
        
        # 清理临时目录
        rm -rf "$temp_dir"
        
        if [ $file_count -gt 0 ]; then
            return 0
        else
            log_error "No dictionary files found in repository"
            return 1
        fi
    else
        log_error "Downloaded directory not found"
        return 1
    fi
}

# 部署rime配置
deploy_rime() {
    log_info "Deploying rime configuration..."
    
    # 重新部署
    rime_deployer
    
    # 重启fcitx5
    if pgrep fcitx5 >/dev/null; then
        log_info "Restarting fcitx5..."
        pkill fcitx5
        sleep 1
        fcitx5 -d
    fi
    
    log_success "Rime deployment completed"
}

# 主函数
main() {
    case "${1:-install}" in
        install)
            log_info "Installing rime with 万象 dictionary..."
            
            if ! check_rime; then
                exit 1
            fi
            
            setup_rime_dirs
            install_basic_config
            
            if download_wanxiang; then
                deploy_rime
                log_success "万象 dictionary installation completed!"
                log_info "Switch input method to test: Ctrl+Space"
            else
                log_warning "Please install 万象 dictionary manually and run: $0 deploy"
            fi
            ;;
            
        deploy)
            log_info "Deploying existing configuration..."
            deploy_rime
            ;;
            
        remove)
            log_info "Removing rime configuration..."
            rm -rf "$RIME_DIR"
            log_success "Rime configuration removed"
            ;;
            
        *)
            echo "Usage: $0 {install|deploy|remove}"
            echo "  install - Install rime with 万象 dictionary"
            echo "  deploy  - Deploy existing configuration"
            echo "  remove  - Remove rime configuration"
            exit 1
            ;;
    esac
}

main "$@"