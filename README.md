# Hyprland Desktop Environment

> 🚀 现代化的 Hyprland 桌面环境配置，开箱即用的生产力工具集

## 🎯 核心特性

### 🖥️ 桌面环境
- **Hyprland** - 高性能 Wayland 合成器
- **Waybar** - 功能丰富的状态栏
- **Mako** - 优雅的通知系统
- **Wofi** - 应用启动器

### 🛠️ 生产力工具
- **番茄工作法** - 集成状态栏的时间管理
- **TOTP 验证器** - 支持 Google Authenticator 导入
- **智能壁纸** - 自动下载和切换
- **截图工具** - Grim + Slurp + Swappy/Satty

### 🎨 系统美化
- **SDDM** - Sugar Candy 登录主题
- **fcitx5** - 现代化中文输入法
- **GTK/Qt** - 统一的暗色主题
- **动态效果** - 流畅的窗口动画

## 📦 支持的发行版

| 发行版 | 支持程度 | 包管理器 |
|--------|----------|----------|
| Arch Linux / Manjaro | 🟢 完全支持 | pacman + yay |
| Debian / Ubuntu | 🟡 基础功能 | apt |
| Fedora | 🟡 基础功能 | dnf |

## 🚀 快速安装

### 1. 克隆仓库
```bash
git clone https://github.com/laofahai/hyprland-elite-desktop.git ~/dotfiles
cd ~/dotfiles
```

### 2. 安装依赖（Arch Linux）
```bash
# 核心软件包
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-chinese-addons \
               mako wofi grim slurp swww wl-clipboard brightnessctl \
               playerctl network-manager-applet blueman gnome-keyring

# 可选功能
yay -S youtube-music-bin lunar-calendar-bin
```

### 3. 执行安装
```bash
# 完整安装
./install.sh

# 模块化安装
./install.sh --core --productivity --development
```

## 🎛️ 快捷键

### 基础操作
| 快捷键 | 功能 |
|--------|------|
| `Super + Q` | 打开终端 |
| `Super + C` | 关闭窗口 |
| `Super + E` | 文件管理器 |
| `Super + R` | 应用启动器 |
| `Super + W` | 随机切换壁纸 |

### 截图功能
| 快捷键 | 功能 |
|--------|------|
| `Alt + A` | 区域截图+编辑 |
| `Print` | 区域截图+编辑 |
| `Shift + Print` | 全屏截图+编辑 |

### 工作区
| 快捷键 | 功能 |
|--------|------|
| `Super + 1-9` | 切换工作区 |
| `Super + Shift + 1-9` | 移动窗口到工作区 |
| `Alt + Tab` | 工作区切换 |

## 🔧 高级功能

### TOTP 二步验证
```bash
# 导入 Google Authenticator
python3 ~/dotfiles/scripts/import-totp.py 'otpauth-migration://...'

# 状态栏查看验证码
Super + T  # 显示当前验证码
```

### 壁纸管理
```bash
# 手动下载壁纸库
~/.config/swww/download-wallpapers.sh

# 定时切换壁纸（每30分钟）
~/.config/swww/swww-cycle.sh 1800 &
```

### 番茄工作法
状态栏集成的番茄计时器：
- 25分钟工作 → 5分钟休息
- 4个周期后长休息（15分钟）
- 支持暂停/重置/跳过

## 📁 项目结构

```
dotfiles/
├── config/              # 应用配置文件
│   ├── hypr/           # Hyprland 配置
│   ├── waybar/         # 状态栏配置和脚本
│   ├── fcitx5/         # 输入法配置
│   ├── sddm/           # 登录管理器主题
│   └── ...
├── scripts/            # 实用脚本
├── shell/              # Shell 配置
├── install.sh          # 安装脚本
└── sync.sh            # 配置同步脚本
```

## 🔧 自定义配置

### 修改主题颜色
```bash
# 编辑 Waybar 样式
vim ~/.config/waybar/style.css

# 编辑 Hyprland 配置
vim ~/.config/hypr/hyprland.conf
```

### 添加快捷键
在 `hyprland.conf` 中添加：
```ini
bind = $mainMod, KEY, exec, command
```

## 🐛 故障排除

### 服务重启
```bash
# 重启关键服务
pkill waybar && waybar &
pkill mako && mako &
pkill fcitx5 && fcitx5 -d
```

### 壁纸问题
```bash
# 检查 swww daemon
pgrep swww-daemon || swww-daemon &
```

### 通知测试
```bash
notify-send "测试" "通知功能正常"
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

## 📄 许可证

MIT License

---

> 💡 **提示**: 首次使用建议先在虚拟机中测试，确保配置符合个人需求