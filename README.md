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
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt swww mako network-manager-applet blueman wofi brightnessctl playerctl wget grim slurp wl-clipboard swappy satty gnome-keyring xdotool jq websocat

yay -S lunar-calendar-bin youtube-music-bin
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
- **swappy**: 截图编辑工具（类似微信截图）
- **satty**: 现代化截图标注工具

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

### 截图功能
- `Alt + A`: 区域截图+编辑（类似微信）
- `Print`: 区域截图+编辑
- `Shift + Print`: 全屏截图+编辑
- `Super + Print`: 区域截图直接复制到剪贴板

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
- 核心功能：CPU、内存、音量、电池、温度
- 扩展功能：TOTP验证、天气、网速监控、系统更新提醒

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

## 🆕 最新功能

### 🎨 桌面美化和登录管理
- **SDDM**: 现代化登录管理器
- **Sugar Candy Theme**: 美观的登录界面主题
- **登录用户管理**: 支持多用户登录和安全配置

### 📱 手机桌面协作
- **智能解锁方案**: 小米手机信任位置、设备、WiFi
- **Join**: 手机通知同步到桌面（过滤重复通知）
- **scrcpy**: 手机屏幕镜像和控制（配合智能解锁）
- **AirDroid**: 备用远程控制方案

### 📧 邮件和日程管理
- **Thunderbird**: 统一邮件管理客户端
- **KOrganizer**: KDE日历和任务管理
- **通知集成**: 邮件、日程、手机通知统一显示

### 🔧 TOTP 二步验证功能
- **totp.sh**: 显示当前 TOTP 验证码和倒计时
- **totp-switch.sh**: 在多个 TOTP 账户间切换
- **totp-selector.sh**: 图形化选择 TOTP 账户
- **totp-copy.sh**: 一键复制 TOTP 验证码

### 📊 实时信息显示
- **netspeed.sh**: 网络速度监控
- **updates.sh**: 系统更新提醒
- **lunar-calendar.sh**: 农历日期显示
- **weather.sh**: 天气信息
- **notification.sh**: 智能通知管理

### 🎵 媒体和娱乐
- **YouTube Music**: 支持桌面应用和图标

## 📋 完整目录结构

```
dotfiles/
├── config/                 # ~/.config 下的配置文件
│   ├── hypr/              # Hyprland 配置
│   ├── waybar/            # Waybar 配置及扩展脚本
│   │   ├── *.sh          # 各种功能脚本
│   │   ├── config.jsonc  # Waybar 配置
│   │   └── style.css     # Waybar 样式
│   ├── fcitx5/           # 输入法配置
│   ├── kitty/            # 终端配置
│   ├── swww/             # 壁纸管理脚本
│   ├── mako/             # 通知配置
│   └── applications/     # 应用程序配置
├── claude/               # Claude AI 配置
├── shell/               # Shell 配置文件
├── scripts/             # 脚本文件
├── install.sh           # 安装脚本
├── sync.sh             # 同步脚本
├── CLAUDE.md           # Claude AI 使用指南
└── README.md           # 说明文档
```

## 🔧 故障排除

### fcitx5 主题未生效
fcitx5 查找用户主题的路径是 `~/.local/share/fcitx5/themes/`，而不是 `~/.config/fcitx5/themes/`。安装脚本已经正确处理了这个路径。

如果主题仍未生效：
```bash
# 检查主题是否正确链接
ls -la ~/.local/share/fcitx5/themes/

# 重启 fcitx5
pkill fcitx5 && fcitx5 -d
```

### VS Code 主题未切换到亮色
VS Code OSS 的配置文件位于 `~/.config/Code - OSS/User/settings.json`，需要手动添加主题配置：
```json
{
    "workbench.colorTheme": "Default Light Modern",
    "window.autoDetectColorScheme": false
}
```

### wofi 配置缺失
如果 wofi 样式未生效，检查软链接：
```bash
# 创建 wofi 配置链接
ln -sf ~/dotfiles/config/wofi ~/.config/wofi
```

### TOTP 配置
使用提供的导入脚本导入 Google Authenticator 的 TOTP 账户：
```bash
python3 ~/dotfiles/scripts/import-totp.py 'otpauth-migration://...'
```

### YouTube Music 无法启动
如果 YouTube Music 无法从应用启动器启动，检查 wrapper 脚本：
```bash
# 检查脚本链接是否存在
ls -la ~/.local/bin/youtube-music-wrapper.sh

# 如果不存在，重新创建
mkdir -p ~/.local/bin
ln -sf ~/dotfiles/scripts/youtube-music-wrapper.sh ~/.local/bin/
update-desktop-database ~/.local/share/applications/
```

### 自动验证
install.sh 现在包含自动验证功能，会检查关键配置是否正确链接：
- YouTube Music wrapper script
- fcitx5 modern theme  
- wofi configuration
