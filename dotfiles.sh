#!/bin/bash

# ===========================================
# Dotfiles Management Script
# ===========================================
# One script for all operations: install, sync, backup, maintain

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Display help message
show_help() {
    cat << EOF
🚀 Dotfiles Management Script

Usage: $0 <command> [options]

📋 Main Commands:
    setup                🆕 Quick setup (recommended for new users)
    install [modules...] Install config files (advanced users)
    sync                 Sync configs to repository
    status               Show configuration status
    backup               Create backup of current configs
    restore <name>       Restore specified backup
    cleanup              Clean system and backups
    help                 Show this help message
    input-method         Setup input method (fcitx5/rime)

🔧 Modules (for install command):
    --core              Core configs (hypr, waybar, etc.)
    --productivity      Productivity tools (pomodoro, totp)
    --development       Dev environment (shell, git)
    --themes            Themes and aesthetics
    --all               All modules (default)

💡 Quick Start:
    1. cp .env.example .env.local
    2. Edit .env.local config file
    3. $0 setup

📚 Examples:
    $0 setup                              # Quick deploy (recommended)
    $0 install --core --productivity      # Install specific modules
    $0 sync                               # Sync configs
    $0 status                             # Check status
    $0 backup                             # Create backup

EOF
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for dep in git rsync; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        exit 1
    fi
}

# Detect distribution and package manager
detect_distro() {
    if command -v pacman >/dev/null 2>&1; then
        DISTRO="arch"
        PKG_INSTALL="sudo pacman -S --needed"
        AUR_HELPER="yay -S"
    elif command -v apt >/dev/null 2>&1; then
        DISTRO="debian"
        PKG_INSTALL="sudo apt install -y"
        AUR_HELPER="echo 'Manual installation required:'"
    elif command -v dnf >/dev/null 2>&1; then
        DISTRO="fedora"
        PKG_INSTALL="sudo dnf install -y"
        AUR_HELPER="echo 'Manual installation required:'"
    else
        DISTRO="unknown"
        PKG_INSTALL="echo 'Manual installation required:'"
        AUR_HELPER="echo 'Manual installation required:'"
    fi
    
    log_info "Detected distribution: $DISTRO"
}

# Define package groups
declare -A PACKAGES=(
    [core]="hyprland waybar kitty mako ulauncher"
    [productivity]="oath-toolkit websocat jq"
    [development]="git curl wget xdotool"
    [media]="grim slurp swappy satty swww"
    [input]="fcitx5 fcitx5-rime rime-pinyin-simp fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
    [system]="network-manager-applet blueman brightnessctl playerctl gnome-keyring"
)

declare -A AUR_PACKAGES=(
    [productivity]="lunar-calendar-bin"
    [media]="youtube-music-bin"
)

# Install package group
install_package_group() {
    local group="$1"
    local packages="${PACKAGES[$group]}"
    local aur_packages="${AUR_PACKAGES[$group]}"
    
    if [[ -n "$packages" ]]; then
        log_info "Installing $group components..."
        
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
                log_warning "Unknown distribution, please install manually: $packages"
                ;;
        esac
        
        if [[ -n "$aur_packages" && "$DISTRO" == "arch" ]]; then
            log_info "Installing AUR packages: $aur_packages"
            $AUR_HELPER $aur_packages
        fi
        
        log_success "$group component installation completed"
    fi
}


# Link configurations
link_configs() {
    local groups=("$@")
    
    log_info "Linking configuration files..."
    
    # Base configurations (always linked)
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
    
    # Add configurations based on components
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
    
    # Create backup and link
    mkdir -p "$BACKUP_DIR"
    
    for config in "${base_configs[@]}"; do
        IFS=':' read -r src dst <<< "$config"
        
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            log_info "Backing up: $dst"
            mv "$dst" "$BACKUP_DIR/"
        fi
        
        log_info "Linking: $(basename "$src") -> $dst"
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
    done
    
    # Link scripts
    mkdir -p "$HOME/.local/bin"
    find "$DOTFILES_DIR/scripts" -name "*.sh" -executable | while read -r script; do
        basename_script=$(basename "$script")
        ln -sf "$script" "$HOME/.local/bin/$basename_script"
    done
    
    # Handle desktop files
    mkdir -p "$HOME/.local/share/applications"
    if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
        log_info "Linking application launchers..."
        for src in "$DOTFILES_DIR/config/applications"/*.desktop; do
            if [[ -f "$src" ]]; then
                basename_file=$(basename "$src")
                dst="$HOME/.local/share/applications/$basename_file"
                ln -sf "$src" "$dst"
                log_success "  ✓ $basename_file"
            fi
        done
        # Update desktop database cache
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
            log_success "Desktop application cache updated"
        fi
    fi
    
    log_success "Configuration linking completed, backup saved at: $BACKUP_DIR"
}

# Install function
install_dotfiles() {
    local modules=("$@")
    
    # If no modules specified, install all by default
    if [ ${#modules[@]} -eq 0 ]; then
        modules=("--all")
    fi
    
    log_info "Starting dotfiles installation..."
    log_info "Backup directory: $BACKUP_DIR"
    
    detect_distro
    
    # Process module installation
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
                --themes) log_info "Themes are applied automatically through configuration files" ;;
            esac
        done
    fi
    
    # Install packages
    for group in "${install_groups[@]}"; do
        install_package_group "$group"
    done
    
    # Link configurations
    link_configs "${install_groups[@]}"
    
    log_success "Installation completed!"
}

# Sync function
sync_dotfiles() {
    log_info "Starting configuration sync to repository..."
    
    cd "$DOTFILES_DIR"
    
    # Check for changes
    if ! git status --porcelain | grep -q .; then
        log_info "No changes to sync"
        return 0
    fi
    
    # Show changes
    log_info "Detected the following changes:"
    git status --short
    
    # Confirm sync
    log_warning "Commit these changes? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Please enter commit message:"
        read -r commit_message
        
        if [[ -z "$commit_message" ]]; then
            commit_message="update: configuration update $(date '+%Y-%m-%d %H:%M')"
        fi
        
        git add .
        git commit -m "$commit_message"
        
        log_info "Push to remote repository? (y/N)"
        read -r push_response
        
        if [[ "$push_response" =~ ^[Yy]$ ]]; then
            git push
            log_success "Push completed!"
        fi
    else
        log_info "Sync operation cancelled"
        return 0
    fi
    
    log_success "Sync completed!"
}

# Cleanup function
cleanup_dotfiles() {
    log_info "Starting system and backup cleanup..."
    
    local cleaned_items=0
    
    # Clean old backups (keep only the last one)
    log_info "Cleaning old backup files..."
    local backup_dirs=($(ls -dt "$HOME"/dotfiles_backup_* 2>/dev/null | tail -n +2))
    if [ ${#backup_dirs[@]} -gt 0 ]; then
        for backup_dir in "${backup_dirs[@]}"; do
            log_info "Deleting old backup: $(basename "$backup_dir")"
            rm -rf "$backup_dir"
            ((cleaned_items++))
        done
    fi
    
    # Clean temporary files
    log_info "Cleaning temporary files..."
    local temp_dirs=(
        "/tmp/screenshots"
        "/tmp/screenshot_*"
        "$HOME/.cache/thumbnails"
        "$HOME/.cache/hypr"
    )
    
    for temp_pattern in "${temp_dirs[@]}"; do
        for temp_path in $temp_pattern; do
            if [[ -e "$temp_path" ]]; then
                log_info "Removing temporary file: $temp_path"
                rm -rf "$temp_path"
                ((cleaned_items++))
            fi
        done
    done
    
    # Clean invalid symbolic links
    log_info "Checking for invalid symbolic links..."
    local config_dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share/applications"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            find "$config_dir" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r broken_link; do
                log_info "Removing invalid link: $broken_link"
                rm -f "$broken_link"
                ((cleaned_items++))
            done
        fi
    done
    
    # Restart services (optional)
    log_warning "Restart desktop services? (y/N)"
    read -r restart_response
    
    if [[ "$restart_response" =~ ^[Yy]$ ]]; then
        log_info "Restarting desktop services..."
        
        # Restart waybar
        if pgrep waybar > /dev/null; then
            pkill waybar
            waybar &
            log_info "Restarted waybar"
        fi
        
        # Restart mako
        if pgrep mako > /dev/null; then
            pkill mako
            mako &
            log_info "Restarted mako"
        fi
        
        # Restart fcitx5
        if pgrep fcitx5 > /dev/null; then
            pkill fcitx5
            fcitx5 -d
            log_info "Restarted fcitx5"
        fi
    fi
    
    if [ $cleaned_items -eq 0 ]; then
        log_info "System is already clean, nothing to clean up"
    else
        log_success "Cleanup completed! Processed $cleaned_items items"
    fi
}

# Backup function
backup_dotfiles() {
    log_info "Creating configuration backup..."
    
    # Backup critical configuration directories
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
            log_info "Backing up: $dir"
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    log_success "Backup creation completed: $BACKUP_DIR"
}

# Restore function
restore_dotfiles() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        log_error "Please specify backup name"
        log_info "Available backups:"
        ls -1 "$HOME"/dotfiles_backup_* 2>/dev/null | xargs -I {} basename {} || log_info "  No available backups"
        exit 1
    fi
    
    local backup_path="$HOME/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        log_error "Backup does not exist: $backup_path"
        exit 1
    fi
    
    log_info "Restoring backup: $backup_name"
    log_warning "This will overwrite current configurations, continue? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Restore backup
        rsync -av "$backup_path/" "$HOME/" --exclude=".*"
        log_success "Backup restoration completed!"
    else
        log_info "Restoration operation cancelled"
    fi
}

# Status check
show_status() {
    log_info "Configuration file status check..."
    
    echo
    echo "=== Configuration File Link Status ==="
    
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
            echo "⚠️  $dir (non-linked directory)"
        else
            echo "❌ $dir (does not exist)"
        fi
    done
    
    echo
    echo "=== Git Status ==="
    cd "$DOTFILES_DIR"
    if git status --porcelain | grep -q .; then
        echo "⚠️  Uncommitted changes"
        git status --short
    else
        echo "✅ Working directory clean"
    fi
}

# Quick setup function (one-click deployment)
quick_setup() {
    echo -e "${BLUE}🚀 Quick setup dotfiles...${NC}"
    echo
    
    # Check .env.local
    if [[ ! -f "$DOTFILES_DIR/.env.local" ]]; then
        if [[ -f "$DOTFILES_DIR/.env.example" ]]; then
            log_warning ".env.local configuration file not found"
            echo "Please run first:"
            echo "  cp .env.example .env.local"
            echo "  Edit .env.local file"
            echo "  Then re-run ./dotfiles.sh setup"
            exit 1
        else
            log_error "Template file .env.example not found"
            exit 1
        fi
    fi
    
    # Load configuration
    source "$DOTFILES_DIR/.env.local"
    log_success "Configuration file loaded successfully"
    
    # Create necessary directories
    log_info "Creating directory structure..."
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/var/log/dotfiles"
    mkdir -p "$HOME/.config/totp" && chmod 700 "$HOME/.config/totp"
    
    # Backup existing configurations
    backup_dotfiles
    
    # Link configuration files
    log_info "Linking configuration files..."
    ln -sf "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
    
    # Handle git config directory carefully
    if [[ -d "$HOME/.config/git" && ! -L "$HOME/.config/git" ]]; then
        log_warning "Backing up existing git directory"
        mv "$HOME/.config/git" "$HOME/.config/git.backup.$(date +%s)"
    fi
    ln -sf "$DOTFILES_DIR/config/git" "$HOME/.config/"
    
    # Desktop environment configuration (if supported)
    if command -v hyprctl >/dev/null 2>&1; then
        log_info "Hyprland detected, linking desktop configuration..."
        ln -sf "$DOTFILES_DIR/config/hypr" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/waybar" "$HOME/.config/"
        ln -sf "$DOTFILES_DIR/config/mako" "$HOME/.config/"
        log_success "Desktop environment configuration completed"
    else
        log_warning "Hyprland not detected, skipping desktop environment configuration"
    fi
    
    log_success "Desktop environment configuration completed"
    
    # Patch system desktop files for better functionality
    echo
    log_info "🔧 System Desktop Files Patching"
    echo "Some applications need system-level patches for better functionality:"
    echo "  • WPS Office: Font rendering fixes"
    echo "  • VSCode: Wayland support improvements"
    echo
    read -p "Apply system desktop file patches? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Skipping desktop file patches"
    else
        log_info "Applying desktop file patches..."
        if [[ -x "$DOTFILES_DIR/scripts/patch-desktop-files.sh" ]]; then
            sudo "$DOTFILES_DIR/scripts/patch-desktop-files.sh"
            if [[ $? -eq 0 ]]; then
                log_success "Desktop file patches applied successfully"
            else
                log_warning "Desktop file patching failed, but continuing"
            fi
        else
            log_warning "Desktop file patcher script not found"
        fi
    fi
    
    # Check and install additional fonts for better WPS rendering
    echo
    log_info "🔤 Font Package Check"
    echo "Better font rendering requires additional font packages."
    echo "Checking for missing font packages..."
    
    missing_fonts=()
    
    # Check for Windows fonts (ttf-ms-fonts)
    if ! fc-list | grep -i "times new roman" >/dev/null 2>&1; then
        missing_fonts+=("ttf-ms-fonts (Windows fonts)")
    fi
    
    # Check for liberation fonts
    if ! fc-list | grep -i "liberation" >/dev/null 2>&1; then
        missing_fonts+=("ttf-liberation (Liberation fonts)")
    fi
    
    if [ ${#missing_fonts[@]} -gt 0 ]; then
        echo "Missing font packages:"
        for font in "${missing_fonts[@]}"; do
            echo "  • $font"
        done
        echo
        read -p "Install missing font packages? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log_info "Installing font packages..."
            
            # Try to install missing fonts
            if command -v yay >/dev/null 2>&1; then
                if [[ " ${missing_fonts[@]} " =~ "ttf-ms-fonts" ]]; then
                    yay -S ttf-ms-fonts --noconfirm || log_warning "Failed to install ttf-ms-fonts"
                fi
                if [[ " ${missing_fonts[@]} " =~ "ttf-liberation" ]]; then
                    sudo pacman -S ttf-liberation --noconfirm || log_warning "Failed to install ttf-liberation"
                fi
            elif command -v pacman >/dev/null 2>&1; then
                if [[ " ${missing_fonts[@]} " =~ "ttf-liberation" ]]; then
                    sudo pacman -S ttf-liberation --noconfirm || log_warning "Failed to install ttf-liberation"
                fi
                log_info "For ttf-ms-fonts, install an AUR helper like yay first"
            fi
            
            log_success "Font installation completed"
        else
            log_info "Skipping font installation"
        fi
    else
        log_success "All recommended fonts are already installed"
    fi
    
    # Set script permissions
    log_info "Setting script permissions..."
    find "$DOTFILES_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # Add to PATH
    if ! grep -q "dotfiles/scripts" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# dotfiles scripts' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/dotfiles/scripts:$PATH"' >> "$HOME/.zshrc"
        log_success "Script directory added to PATH"
    fi
    
    # Test configuration
    log_info "Testing configuration..."
    if [[ -x "$DOTFILES_DIR/scripts/load-env.sh" ]]; then
        if "$DOTFILES_DIR/scripts/load-env.sh" >/dev/null 2>&1; then
            log_success "Environment configuration test passed"
        else
            log_warning "Environment configuration test failed, but continuing installation"
        fi
    fi
    
    # Initialize proxy configuration
    echo
    log_info "🌐 Initializing proxy configuration..."
    if [[ -x "$DOTFILES_DIR/scripts/generate-proxy-env.sh" ]]; then
        "$DOTFILES_DIR/scripts/generate-proxy-env.sh"
        log_success "Proxy configuration initialized"
        echo "  Proxy settings can be modified in: .env.local"
        echo "  Use ENABLE_PROXY=true/false to toggle proxy"
    else
        log_warning "Proxy configuration script not found"
    fi

    # Optional service setup
    echo
    log_info "🔧 Optional Service Setup:"
    
    # Health reminders
    read -p "Enable health reminder service? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if [[ -x "$DOTFILES_DIR/scripts/periodic-reminders.sh" ]]; then
            "$DOTFILES_DIR/scripts/periodic-reminders.sh" test >/dev/null 2>&1 && log_success "Health reminder test successful"
            echo "Manage health reminders:"
            echo "  Start: periodic-reminders.sh start"
            echo "  Status: periodic-reminders.sh status"
            echo "  Stop: periodic-reminders.sh stop"
        fi
    fi
    
    # System monitoring
    read -p "Enable system monitoring cron job? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cron_line="*/30 * * * * $DOTFILES_DIR/scripts/system-monitor-notify.sh"
        if ! crontab -l 2>/dev/null | grep -q "system-monitor-notify.sh"; then
            (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
            log_success "System monitoring enabled (checks every 30 minutes)"
        else
            log_info "System monitoring already exists"
        fi
    fi
    
    # SDDM theme configuration
    if command -v sddm >/dev/null 2>&1; then
        echo
        read -p "Configure SDDM login theme? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            log_info "Checking SDDM theme dependencies..."
            
            # Check if astronaut theme is installed
            if [[ ! -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]]; then
                log_warning "sddm-astronaut-theme not installed"
                echo "Please install first:"
                echo "  yay -S sddm-astronaut-theme"
                echo "Then configure: sudo cp $DOTFILES_DIR/config/sddm/sddm.conf /etc/sddm.conf"
            else
                log_info "Found sddm-astronaut-theme, configuring..."
                echo "Copying SDDM configuration..."
                sudo cp "$DOTFILES_DIR/config/sddm/sddm.conf" /etc/sddm.conf
                log_success "SDDM theme configured successfully"
                echo "Restart SDDM to apply: sudo systemctl restart sddm"
            fi
        fi
    else
        log_info "SDDM not detected, skipping login theme configuration"
    fi
    
    echo
    log_success "🎉 Quick setup completed!"
    echo
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "  1. Reopen terminal or run: source ~/.zshrc"
    echo "  2. Adjust .env.local configuration as needed" 
    echo "  3. Setup input method: ./dotfiles.sh input-method"
    echo "  4. Enjoy your new desktop environment!"
    echo
    echo -e "${BLUE}🔧 Common commands:${NC}"
    echo "  ./dotfiles.sh status           # Check configuration status"
    echo "  ./dotfiles.sh sync             # Sync configurations"
    echo "  ./dotfiles.sh backup           # Backup configurations"
    echo "  ./dotfiles.sh input-method     # Setup input method (fcitx5/rime)"
    echo "  periodic-reminders.sh start    # Start health reminders"
}

# 输入法智能配置
setup_input_method() {
    echo -e "${BLUE}🔤 Input Method Configuration${NC}"
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
    
    echo "Current input method status:"
    echo "  • fcitx5: $($has_fcitx5 && echo "✅ installed" || echo "❌ not found")"
    echo "  • fcitx5-rime: $($has_rime && echo "✅ installed" || echo "❌ not found")" 
    echo "  • 万象词库: $($has_wanxiang && echo "✅ available" || echo "❌ not found")"
    
    if [[ -L "$HOME/.config/fcitx5" ]]; then
        local link_target=$(readlink "$HOME/.config/fcitx5")
        echo "  • Current config: $(basename "$link_target")"
    elif [[ -d "$HOME/.config/fcitx5" ]]; then
        echo "  • Current config: local directory (not linked)"
    else
        echo "  • Current config: not exists"
    fi
    
    echo
    
    if ! $has_fcitx5; then
        log_error "fcitx5 not installed. Please install first:"
        echo "sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt"
        return 1
    fi
    
    echo "Available input method options:"
    echo "  1. Enhanced rime + 万象词库 (rich vocabulary, smart prediction)"
    echo "  2. Standard fcitx5 pinyin (simple, stable)"
    echo "  3. Just restart fcitx5"
    echo "  4. Cancel"
    echo
    
    read -p "Please choose (1-4): " -n 1 -r choice
    echo
    echo
    
    case "$choice" in
        1)
            if ! $has_rime; then
                log_error "fcitx5-rime not installed. Please install first:"
                echo "sudo pacman -S fcitx5-rime"
                return 1
            fi
            
            log_info "Setting up rime + 万象词库..."
            
            # 备份现有配置
            if [[ -d "$HOME/.config/fcitx5" && ! -L "$HOME/.config/fcitx5" ]]; then
                local backup_name="fcitx5.backup.$(date +%s)"
                mv "$HOME/.config/fcitx5" "$HOME/$backup_name"
                log_info "Backed up existing config to: ~/$backup_name"
            fi
            
            # 链接rime专用fcitx5配置
            rm -f "$HOME/.config/fcitx5"
            ln -sf "$DOTFILES_DIR/config/fcitx5-rime" "$HOME/.config/fcitx5"
            
            # 安装万象词库
            log_info "Installing 万象词库..."
            if [[ -x "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" ]]; then
                "$DOTFILES_DIR/scripts/setup-rime-wanxiang.sh" install
            else
                log_warning "万象词库安装脚本不存在"
                log_info "你可以手动从以下地址下载词库："
                echo "https://github.com/amzxyz/rime_wanxiang"
                echo "解压到: $HOME/.local/share/fcitx5/rime/"
            fi
            
            restart_input_method
            log_success "rime + 万象词库 configured successfully!"
            ;;
            
        2)
            log_info "Setting up standard fcitx5 pinyin..."
            
            # 使用标准配置
            rm -f "$HOME/.config/fcitx5"
            if [[ -d "$DOTFILES_DIR/config/fcitx5-fallback" ]]; then
                ln -sf "$DOTFILES_DIR/config/fcitx5-fallback" "$HOME/.config/fcitx5"
                log_info "Using fallback configuration"
            else
                ln -sf "$DOTFILES_DIR/config/fcitx5" "$HOME/.config/fcitx5"
                log_info "Using standard configuration"
            fi
            
            restart_input_method
            log_success "Standard fcitx5 pinyin configured successfully!"
            ;;
            
        3)
            restart_input_method
            ;;
            
        4)
            log_info "Operation cancelled"
            return 0
            ;;
            
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}✅ Input method configuration completed!${NC}"
    echo
    echo "Usage:"
    echo "  • Switch input: Ctrl+Space" 
    echo "  • Configure: fcitx5-configtool"
    echo "  • Test typing in any application"
    
    if $has_rime; then
        echo "  • Rime settings: Ctrl+\` (backtick)"
        echo "  • Deploy config: rime_deployer"
    fi
}

# 重启输入法服务
restart_input_method() {
    log_info "Restarting input method services..."
    
    # 重启fcitx5
    if pgrep fcitx5 >/dev/null; then
        pkill fcitx5
        sleep 1
    fi
    
    fcitx5 -d
    log_success "Input method services restarted"
}

# Main function
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
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
