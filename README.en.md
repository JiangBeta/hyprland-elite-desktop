# Hyprland Desktop Environment

> 🚀 Modern Hyprland desktop environment configuration with out-of-the-box productivity tools

## 🎯 Core Features

### 🖥️ Desktop Environment
- **Hyprland** - High-performance Wayland compositor
- **Waybar** - Feature-rich status bar
- **Mako** - Elegant notification system
- **Wofi** - Application launcher

### 🛠️ Productivity Tools
- **Pomodoro Timer** - Integrated status bar time management
- **TOTP Authenticator** - Google Authenticator import support
- **Smart Wallpapers** - Auto-download and switching
- **Screenshot Tools** - Grim + Slurp + Swappy/Satty

### 🎨 System Theming
- **SDDM** - Sugar Candy login theme
- **fcitx5** - Modern Chinese input method
- **GTK/Qt** - Unified dark theme
- **Smooth Animations** - Fluid window transitions

## 📦 Supported Distributions

| Distribution | Support Level | Package Manager |
|--------------|---------------|-----------------|
| Arch Linux / Manjaro | 🟢 Full Support | pacman + yay |
| Debian / Ubuntu | 🟡 Basic Features | apt |
| Fedora | 🟡 Basic Features | dnf |

## 🚀 Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/laofahai/hyprland-elite-desktop.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install Dependencies (Arch Linux)
```bash
# Core packages
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-chinese-addons \
               mako wofi grim slurp swww wl-clipboard brightnessctl \
               playerctl network-manager-applet blueman gnome-keyring

# Optional features
yay -S youtube-music-bin lunar-calendar-bin
```

### 3. Run Installation
```bash
# Full installation
./install.sh

# Modular installation
./install.sh --core --productivity --development
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

### Pomodoro Technique
Status bar integrated pomodoro timer:
- 25 minutes work → 5 minutes break
- Long break (15 minutes) after 4 cycles
- Support pause/reset/skip

## 📁 Project Structure

```
dotfiles/
├── config/              # Application configs
│   ├── hypr/           # Hyprland configuration
│   ├── waybar/         # Status bar config and scripts
│   ├── fcitx5/         # Input method config
│   ├── sddm/           # Login manager theme
│   └── ...
├── scripts/            # Utility scripts
├── shell/              # Shell configurations
├── install.sh          # Installation script
└── sync.sh            # Config sync script
```

## 🔧 Customization

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