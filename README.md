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
- **youtube-music.sh**: YouTube Music 媒体控制和歌词显示
- **youtube-music-control.sh**: YouTube Music 交互控制

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

### YouTube Music 控制（Waybar 组件）
- `左键点击`: 切换喜欢/不喜欢状态
- `右键点击`: 播放/暂停
- `中键点击`: 查看歌词帮助
- `滚轮上/下`: 切换上一首/下一首

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

### YouTube Music 集成功能
#### 功能特点
- **歌词优先显示**: 当检测到歌词时，waybar 会优先显示当前播放歌曲的歌词
- **智能图标**: 根据歌曲的 like 状态显示不同图标
  - `󰋑` 实心心形 - 已点赞
  - `󰋟` 空心心形 - 未点赞或未知状态
- **一键 like**: 点击图标即可切换歌曲的喜欢状态

#### 依赖要求
- YouTube Music 应用 (`yay -S youtube-music-bin`)
- xdotool 工具 (`sudo pacman -S xdotool`)
- Synced Lyrics 浏览器扩展（可选，用于歌词显示）

#### 使用说明
1. 启动 YouTube Music 应用
2. waybar 会自动检测并显示当前播放状态
3. 有歌词时显示歌词，无歌词时显示艺术家和歌曲名
4. 通过点击和滚轮进行各种控制操作

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
- YouTube Music 集成：歌词优先显示、like 状态控制

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

### TOTP 二步验证功能
- **totp.sh**: 显示当前 TOTP 验证码和倒计时
- **totp-switch.sh**: 在多个 TOTP 账户间切换
- **totp-selector.sh**: 图形化选择 TOTP 账户
- **totp-copy.sh**: 一键复制 TOTP 验证码

### 实时信息显示
- **netspeed.sh**: 网络速度监控
- **updates.sh**: 系统更新提醒
- **lunar-calendar.sh**: 农历日期显示
- **weather.sh**: 天气信息
- **notification.sh**: 智能通知管理

### 歌词增强功能
- **youtube-music-lyrics-fetch.sh**: 智能歌词获取
- **lyrics-from-dom.sh**: DOM 歌词提取
- **debug-lyrics.sh**: 歌词调试工具
- **test-lyrics.sh**: 歌词功能测试

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
