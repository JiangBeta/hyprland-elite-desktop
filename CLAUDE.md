# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing Linux desktop environment configurations, specifically for Arch Linux with Hyprland (Wayland compositor). The repository is primarily documented in Chinese.

## Project Structure

- `config/` - Application configurations that get symlinked to `~/.config/`
  - `hypr/` - Hyprland window manager configuration
  - `waybar/` - Status bar configuration
  - `kitty/` - Terminal emulator configuration
  - `fcitx5/` - Chinese input method configuration
  - `swww/` - Wallpaper manager with scripts
  - `mako/` - Notification daemon
  - `satty/` & `swappy/` - Screenshot tools
  - `applications/` - Custom .desktop files
- `shell/` - Shell configuration files (bashrc, zshrc, screenrc)
- `scripts/` - Custom utility scripts
- `install.sh` - Installation script that creates symlinks
- `sync.sh` - Synchronization script to update dotfiles from live configs

## Common Commands

### Initial Setup
```bash
# Clone and install dotfiles on a new machine
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Sync Changes
```bash
# After modifying configurations, sync back to dotfiles
cd ~/dotfiles
./sync.sh

# Then commit changes
git add .
git commit -m "Update configurations"
git push
```

### Test Configurations
```bash
# Reload Hyprland config
hyprctl reload

# Restart services after config changes
pkill waybar && waybar &
pkill mako && mako &
pkill fcitx5 && fcitx5 -d

# Test wallpaper switching
~/.config/swww/swww-random.sh

# Test notifications
notify-send "Test" "Notification test"
```

## Architecture

### Configuration Management
- Uses **symlinks** from dotfiles to actual config locations
- `install.sh` creates symlinks and backs up existing configs
- `sync.sh` copies changes from live configs back to dotfiles (skips symlinks)
- All config changes should be made in the actual config locations, then synced

### Key Components
1. **Hyprland** - Main window manager with keybindings and animations
2. **Waybar** - Minimal status bar (CPU, memory, volume, battery, clock)
3. **swww** - Wallpaper system with automatic downloading and cycling
4. **fcitx5** - Chinese input support
5. **Shell configs** - Bash, Zsh, and Screen configurations

### Wallpaper System
- `swww-daemon` manages wallpaper display
- Scripts in `config/swww/`:
  - `download-wallpapers.sh` - Downloads sample wallpapers
  - `auto-download-wallpapers.sh` - Automatic wallpaper fetching
  - `swww-random.sh` - Random wallpaper switching
  - `swww-set.sh` - Manual wallpaper selection
  - `swww-cycle.sh` - Timed wallpaper rotation

## Important Notes

- Repository uses Chinese documentation and comments
- No build system, tests, or linting - pure configuration files
- Keybindings are defined in `config/hypr/hyprland.conf`
- High-quality wallpaper settings (95% quality, Lanczos3 scaling, 2s fade)
- Notifications configured for 5-second auto-dismiss with transparency