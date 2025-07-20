# Hyprland Desktop Environment

> 🚀 Modern Hyprland desktop environment configuration with out-of-the-box productivity tools

## 🎯 Core Features

### 🖥️ Desktop Environment
- **Hyprland** - High-performance Wayland compositor
- **Waybar** - Feature-rich status bar
- **Mako** - 🆕 Smart notification system (recovery, filtering support)
- **Wofi** - Application launcher

### 🛠️ Productivity Tools
- **Pomodoro Timer** - Integrated status bar time management
- **TOTP Authenticator** - Google Authenticator import support
- **Smart Wallpapers** - Auto-download and switching
- **Screenshot Tools** - Grim + Slurp + Swappy/Satty
- **Push Notifications** - Integrated ntfy.sh mobile push

### 🎨 System Theming
- **SDDM** - Sugar Candy login theme with unified color scheme
- **fcitx5** - Modern Chinese input method with cloud pinyin support
- **GTK/Qt** - Unified dark theme
- **Smooth Animations** - Fluid window transitions
- **High DPI Support** - Perfect scaling and font rendering

## 📦 Supported Distributions

| Distribution | Support Level | Package Manager |
|--------------|---------------|-----------------|
| Arch Linux / Manjaro | 🟢 Full Support | pacman + yay |
| Debian / Ubuntu | 🟡 Basic Features | apt |
| Fedora | 🟡 Basic Features | dnf |

## 🚀 Quick Installation

### 💫 Super Simple 3-Step Deployment

```bash
# 1. Clone project
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# 2. Copy and edit configuration
cp .env.example .env.local
vim .env.local  # Modify NTFY_TOPIC and other personal settings

# 3. One-click deployment
./dotfiles.sh setup
```

**That's it! 🎉 Everything else is handled automatically!**

### 🔧 Dependency Installation (Optional)

If you want to use complete desktop environment features:

#### Arch Linux
```bash
# Core packages
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-chinese-addons \
               mako wofi grim slurp swww wl-clipboard brightnessctl \
               playerctl network-manager-applet blueman gnome-keyring

# Optional features
yay -S youtube-music-bin lunar-calendar-bin
```

### 3. Unified Management Script

```bash
# View all available commands
./dotfiles.sh help

# Quick setup (recommended for new users)
./dotfiles.sh setup

# Advanced features
./dotfiles.sh status    # Check configuration status
./dotfiles.sh sync      # Sync configuration to repository
./dotfiles.sh backup    # Create configuration backup
```

## 🔄 Multi-Device Sync

### Sync to another computer:
```bash
git clone <your-repo> ~/dotfiles
cd ~/dotfiles
cp .env.example .env.local
vim .env.local              # Modify NTFY_TOPIC to unique value
./dotfiles.sh setup        # One-click sync
```

### Daily updates:
```bash
cd ~/dotfiles
git pull
./dotfiles.sh setup        # Re-apply latest configuration
```

## 🔧 Common Commands

```bash
# Health reminder management
periodic-reminders.sh start    # Start health reminders
periodic-reminders.sh status   # Check service status
periodic-reminders.sh stop     # Stop health reminders

# Configuration management
./dotfiles.sh status           # Check configuration status
./dotfiles.sh backup           # Create backup
```

## ⚙️ Important Configuration

Modify these settings in `.env.local`:

```bash
# Notification topic (must be unique)
NTFY_TOPIC="yourname_laptop_$(date +%s)"

# Health reminder frequency (minutes)
BREAK_INTERVAL=120    # Break reminder
WATER_INTERVAL=180    # Water reminder
EYE_INTERVAL=60       # Eye care reminder
```

## 🎛️ Keybindings

### Basic Operations
| Keybinding | Function |
|------------|----------|
| `Super + Q` | Open terminal |
| `Super + C` | Close window |
| `Super + E` | File manager |
| `Super + R` | Application launcher |
| `Super + W` | Random wallpaper |

### Screenshot Functions
| Keybinding | Function |
|------------|----------|
| `Alt + A` | Region screenshot + edit |
| `Print` | Region screenshot + edit |
| `Shift + Print` | Fullscreen screenshot + edit |

### Workspaces
| Keybinding | Function |
|------------|----------|
| `Super + 1-9` | Switch to workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Alt + Tab` | Workspace switching |

## 🔧 Advanced Features

### TOTP Two-Factor Authentication
```bash
# Import Google Authenticator
python3 ~/dotfiles/scripts/import-totp.py 'otpauth-migration://...'

# View codes in status bar
Super + T  # Display current code
```

### Wallpaper Management
```bash
# Manual wallpaper download
~/.config/swww/download-wallpapers.sh

# Auto-switch wallpaper (every 30 minutes)
~/.config/swww/swww-cycle.sh 1800 &
```

### 🔔 Smart Notification System
Status bar integrated notification center with advanced features:
- 💬 **Smart Filtering** - Automatically filter system control notifications
- 🔁 **Notification Recovery** - Anti-duplicate recovery mechanism
- ✨ **Intuitive Operations** - Left click to recover, right click to clear
- 🎨 **Status Display** - Different icons for different states (🔔active, 🕰️history, 🔕no notifications)

```bash
# Test notification system functionality
./test-notification-logic.sh

# View detailed documentation
cat NOTIFICATION_SYSTEM.md
```

### Pomodoro Technique
Status bar integrated pomodoro timer:
- 25 minutes work → 5 minutes break
- Long break (15 minutes) after 4 cycles
- Support pause/reset/skip

## 📁 Project Structure

```
dotfiles/
├── dotfiles.sh            # 🆕 Unified management script
├── config/              # Application configuration files
│   ├── hypr/           # Hyprland configuration
│   ├── waybar/         # Status bar configuration and scripts
│   ├── fcitx5/         # Input method configuration
│   ├── sddm/           # Login manager theme
│   ├── mako/           # Notification system configuration
│   ├── swww/           # Wallpaper management
│   ├── totp/           # Two-factor authentication
│   └── ...
├── scripts/            # Utility scripts and tools
├── shell/              # Shell configurations (zsh/bash)
├── screenshots/        # Project screenshots
├── .env.example        # Environment variable template
└── README.md           # Project documentation
```

## 🔧 Configuration Management

### 🆕 Unified Management Script
```bash
# View all available commands
./dotfiles.sh help

# Check configuration status
./dotfiles.sh status

# Backup current configuration
./dotfiles.sh backup

# Restore backup
./dotfiles.sh restore backup_name
```

### 🔒 Privacy Protection
The project has configured comprehensive `.gitignore` to protect personal data:
- 🔐 **TOTP Keys** - Two-factor authentication private keys
- 📝 **Input Method Data** - Personal dictionary and history
- ⚙️ **Application State** - Pomodoro timer, Claude settings, etc.
- 📊 **Cache Data** - Temporary files and system cache

### Modify Theme Colors
```bash
# Edit Waybar styles
vim ~/.config/waybar/style.css

# Edit Hyprland config
vim ~/.config/hypr/hyprland.conf
```

### Add Keybindings
In `hyprland.conf` add:
```ini
bind = $mainMod, KEY, exec, command
```

### Personal Configuration Files
Create these files for personalization:
- `.env.local` - Personal environment variables
- `shell/zshrc.local` - Personal shell configuration
- `config/totp/secrets.conf` - TOTP keys

## 🐛 Troubleshooting

### Restart Services
```bash
# Restart key services
pkill waybar && waybar &
pkill mako && mako &
pkill fcitx5 && fcitx5 -d
```

### Wallpaper Issues
```bash
# Check swww daemon
pgrep swww-daemon || swww-daemon &
```

### Notification Test
```bash
notify-send "Test" "Notification working"
```

## 🤝 Contributing

Issues and Pull Requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

MIT License

---

> 💡 **Tip**: Recommend testing in a virtual machine first to ensure the configuration meets your needs