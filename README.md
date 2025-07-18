# 我的 Dotfiles

这是我的 Arch Linux + Hyprland 桌面环境配置文件。

## 🚀 快速开始

### 1. 克隆仓库
```bash
git clone <仓库地址> ~/dotfiles
cd ~/dotfiles
```

### 2. 安装依赖软件
```bash
# 基础软件包
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt

# 壁纸和通知
sudo pacman -S swww mako

# 网络和蓝牙管理
sudo pacman -S network-manager-applet blueman

# 其他工具
sudo pacman -S wofi brightnessctl playerctl wpctl wget

# yay
yay -S lunar-calendar-bin
```

### 3. 启用系统服务
```bash
# 启用蓝牙
sudo systemctl enable --now bluetooth

# 启用网络管理
sudo systemctl enable --now NetworkManager
```

### 4. 运行安装脚本
```bash
./install.sh
```

## 📦 包含的配置

### 🖥️ 桌面环境
- **Hyprland**: Wayland 合成器配置
- **Waybar**: 状态栏配置（已优化，移除冗余模块）
- **Kitty**: 终端模拟器配置

### 🎨 主题和外观
- **swww**: 壁纸切换工具（高质量配置）
- **mako**: 通知管理器（半透明、自动消失）

### ⌨️ 输入法
- **fcitx5**: 中文输入法配置

### 🔧 工具脚本
- **swww-random.sh**: 随机切换壁纸
- **swww-set.sh**: 手动选择壁纸
- **swww-cycle.sh**: 定时切换壁纸
- **download-wallpapers.sh**: 下载示例壁纸
- **auto-download-wallpapers.sh**: 自动下载新壁纸

## 🎯 快捷键

### 基础操作
- `Super + Q`: 打开终端
- `Super + C`: 关闭窗口
- `Super + M`: 退出 Hyprland
- `Super + E`: 文件管理器
- `Super + R`: 应用启动器
- `Super + V`: 切换浮动窗口

### 壁纸管理
- `Super + W`: 随机切换壁纸
- `Super + Shift + W`: 手动选择壁纸

### 工作区
- `Super + 1-9`: 切换到工作区 1-9
- `Super + Shift + 1-9`: 移动窗口到工作区 1-9
- `Alt + Tab`: 切换工作区

### 多媒体
- `音量键`: 调节音量
- `亮度键`: 调节屏幕亮度
- `媒体键`: 播放/暂停/切换

## 🔧 高级功能

### 自动下载壁纸
```bash
# 手动下载壁纸
~/.config/swww/download-wallpapers.sh

# 设置定时自动下载（每天一次）
crontab -e
# 添加：0 9 * * * ~/.config/swww/auto-download-wallpapers.sh
```

### 定时切换壁纸
```bash
# 每30分钟切换一次壁纸
~/.config/swww/swww-cycle.sh 1800 &
```

### 托盘图标
- **WiFi**: nm-applet（右键可搜索连接网络）
- **蓝牙**: blueman-applet（点击管理蓝牙设备）

## 🎨 自定义

### 修改主题颜色
编辑 `config/waybar/style.css` 和 `config/hypr/hyprland.conf` 中的颜色配置。

### 添加新的快捷键
在 `config/hypr/hyprland.conf` 的 `KEYBINDINGS` 部分添加：
```
bind = $mainMod, KEY, exec, command
```

### 自定义通知样式
编辑 `config/mako/config` 文件。

## 🐛 故障排除

### 启动服务问题
```bash
# 重启相关服务
pkill waybar && waybar &
pkill mako && mako &
pkill nm-applet && nm-applet &
pkill blueman-applet && blueman-applet &
```

### 壁纸不切换
```bash
# 检查 swww daemon
pgrep swww-daemon || swww-daemon &

# 手动测试
~/.config/swww/swww-random.sh
```

### 输入法问题
```bash
# 重启输入法
pkill fcitx5 && fcitx5 -d
```

### 通知测试
```bash
# 测试通知功能
~/.config/swww/test-notification.sh
```

## 📋 配置文件说明

### Hyprland 配置特点
- 高质量动画和模糊效果
- 自动启动必要服务
- 优化的快捷键布局

### Waybar 配置特点
- 精简的模块配置
- 移除了冗余的网络、蓝牙、温度、麦克风模块
- 保留核心功能：CPU、内存、音量、电池

### swww 配置特点
- 高质量壁纸（95% 压缩质量）
- Lanczos3 缩放算法
- 2秒淡入过渡效果

### mako 配置特点
- 半透明通知
- 5秒自动消失
- 支持点击消失

## 🔄 更新配置

当你修改了配置文件后，运行：
```bash
cd ~/dotfiles
./sync.sh  # 同步当前配置到 dotfiles
```

## 📝 备份说明

安装脚本会自动备份你的原有配置到 `~/dotfiles_backup_<timestamp>/` 目录。

## 🆘 获取帮助

如果遇到问题，请检查：
1. 是否安装了所有必需的软件包
2. 是否启用了必要的系统服务
3. 是否有权限问题
4. 查看日志文件 `~/.config/swww/wallpaper_download.log`

---

**享受你的新桌面环境！** 🎉

个人配置文件管理仓库

## 目录结构

```
dotfiles/
├── config/          # ~/.config 下的配置文件
│   ├── hypr/        # Hyprland 配置
│   ├── waybar/      # Waybar 配置
│   ├── fcitx5/      # 输入法配置
│   └── kitty/       # 终端配置
├── shell/           # Shell 配置文件
│   ├── bashrc       # Bash 配置
│   ├── zshrc        # Zsh 配置
│   └── screenrc     # Screen 配置
├── scripts/         # 脚本文件
├── install.sh       # 安装脚本
├── sync.sh          # 同步脚本
└── README.md        # 说明文档
```

## 使用方法

### 首次设置

1. 克隆仓库到家目录：
   ```bash
   git clone <your-repo-url> ~/dotfiles
   ```

2. 运行安装脚本：
   ```bash
   chmod +x ~/dotfiles/install.sh
   ~/dotfiles/install.sh
   ```

### 同步更改

当你修改了配置文件后，运行同步脚本：
```bash
chmod +x ~/dotfiles/sync.sh
~/dotfiles/sync.sh
```

然后提交更改：
```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

### 在新机器上使用

1. 克隆仓库
2. 运行 `install.sh`
3. 重新登录或重新加载配置

## 包含的配置

- **Hyprland**: 窗口管理器配置
- **Waybar**: 状态栏配置
- **Fcitx5**: 输入法配置
- **Kitty**: 终端模拟器配置
- **Bash/Zsh**: Shell 配置
- **Screen**: 终端复用器配置

## 注意事项

- 安装脚本会自动备份现有配置
- 所有配置文件都使用软链接，修改会直接反映到 dotfiles 目录
- 定期运行 `sync.sh` 来保持同步
