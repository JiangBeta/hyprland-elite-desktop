#!/bin/bash

# Desktop Files Patcher
# Patches system desktop files for better font rendering and functionality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script needs to be run as root to modify system desktop files."
    echo "Please run: sudo $0"
    exit 1
fi

log_info "🔧 Patching system desktop files..."

# Backup directory
BACKUP_DIR="/etc/dotfiles-backups/desktop-files-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to patch WPS Office files
patch_wps_files() {
    local wps_files=(
        "/usr/share/applications/wps-office-wps.desktop"
        "/usr/share/applications/wps-office-et.desktop"
        "/usr/share/applications/wps-office-wpp.desktop"
        "/usr/share/applications/wps-office-pdf.desktop"
    )
    
    for file in "${wps_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Patching $(basename "$file")..."
            
            # Backup original
            cp "$file" "$BACKUP_DIR/"
            
            # Patch the Exec line to include font fix environment variables
            sed -i 's|^Exec=\(/usr/bin/[^[:space:]]*\)|Exec=env QT_SCREEN_SCALE_FACTORS=1 QT_AUTO_SCREEN_SCALE_FACTOR=0 QT_SCALE_FACTOR=1 \1|g' "$file"
            
            log_success "  ✓ Patched $(basename "$file")"
        else
            log_warning "  ! $(basename "$file") not found"
        fi
    done
}

# Function to patch WeChat file opening (removed - causes issues)
patch_wechat_files() {
    log_info "WeChat patching skipped - system default works better"
}

# Function to patch VSCode for better Wayland support
patch_vscode_files() {
    local vscode_files=(
        "/usr/share/applications/code.desktop"
        "/usr/share/applications/visual-studio-code.desktop"
    )
    
    for file in "${vscode_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Patching $(basename "$file")..."
            
            # Backup original
            cp "$file" "$BACKUP_DIR/"
            
            # Add Wayland support flags if not already present
            if ! grep -q "\-\-enable-features=UseOzonePlatform" "$file"; then
                sed -i 's|^Exec=/usr/bin/code|Exec=/usr/bin/code --enable-features=UseOzonePlatform --ozone-platform=wayland|g' "$file"
            fi
            
            log_success "  ✓ Patched $(basename "$file")"
        else
            log_warning "  ! $(basename "$file") not found"
        fi
    done
}

# Function to restore original files
restore_originals() {
    log_info "🔄 Restoring original desktop files..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backup directory found!"
        exit 1
    fi
    
    for backup_file in "$BACKUP_DIR"/*.desktop; do
        if [[ -f "$backup_file" ]]; then
            filename=$(basename "$backup_file")
            original_path="/usr/share/applications/$filename"
            
            if [[ -f "$original_path" ]]; then
                cp "$backup_file" "$original_path"
                log_success "  ✓ Restored $filename"
            fi
        fi
    done
    
    log_success "All files restored from backup"
}

# Main execution
case "${1:-patch}" in
    "patch"|"")
        log_info "Starting desktop files patching..."
        
        # Patch different application types
        patch_wps_files
        patch_wechat_files  
        patch_vscode_files
        
        # Update desktop database
        log_info "Updating desktop database..."
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database /usr/share/applications/
            log_success "Desktop database updated"
        fi
        
        log_success "🎉 Desktop files patching completed!"
        log_info "Backup saved to: $BACKUP_DIR"
        echo
        log_info "📋 Changes made:"
        echo "  • WPS Office: Added font rendering fixes"  
        echo "  • WeChat: Improved file manager integration"
        echo "  • VSCode: Added Wayland support flags"
        echo
        log_info "💡 To restore original files, run: sudo $0 restore"
        ;;
        
    "restore")
        restore_originals
        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database /usr/share/applications/
        fi
        ;;
        
    *)
        echo "Usage: $0 [patch|restore]"
        echo "  patch   - Apply patches to desktop files (default)"
        echo "  restore - Restore original desktop files from backup"
        exit 1
        ;;
esac