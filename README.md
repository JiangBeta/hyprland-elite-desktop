# Hyprland Desktop Environment

> 🚀 现代化的 Hyprland 桌面环境配置，开箱即用的生产力工具集

![Hyprland Elite Desktop](screenshots/hero-desktop.jpg)

## 🎯 核心特性

### 🖥️ 桌面环境
- **Hyprland** - 高性能 Wayland 合成器
- **Waybar** - 功能丰富的状态栏
- **Mako** - 🆕 智能通知系统（支持恢复、过滤）
- **Ulauncher** - 现代化应用启动器

### 🛠️ 生产力工具
- **番茄工作法** - 集成状态栏的时间管理，支持工作统计
- **TOTP 验证器** - 支持 Google Authenticator 导入，状态栏显示
- **智能壁纸** - 自动下载和切换，支持定时更换
- **截图工具** - Grim + Slurp + Swappy/Satty，支持编辑和标注
- **通知推送** - 集成 ntfy.sh 手机推送，支持远程通知
- **Obsidian 集成** - 快捷键捕获想法和任务到笔记系统
- **系统监控** - 自动监控系统资源并智能通知

### 🎨 系统美化
- **SDDM** - Sugar Candy 登录主题，统一配色
- **fcitx5 + Rime** - 🆕 现代化中文输入法，已修复标点符号、Shift键等问题
  - 支持万象拼音、万象专业版、明月拼音
  - 智能标点符号（，。？！；：）
  - Shift键临时英文输入，不提交候选词
  - 预留云拼音接口
- **GTK/Qt** - 统一的暗色主题
- **动态效果** - 流畅的窗口动画
- **高DPI支持** - 完美的缩放和字体渲染

## 📦 支持的发行版

| 发行版 | 支持程度 | 包管理器 |
|--------|----------|----------|
| Arch Linux / Manjaro | 🟢 完全支持 | pacman + yay |
| Debian / Ubuntu | 🟡 基础功能 | apt |
| Fedora | 🟡 基础功能 | dnf |

## 🚀 快速安装

### 💫 超简单三步部署

```bash
# 1. 克隆项目
git clone https://github.com/laofahai/hyprland-elite-desktop ~/dotfiles
cd ~/dotfiles

# 2. 复制并编辑配置
cp .env.example .env.local
vim .env.local  # 修改 NTFY_TOPIC 等个人配置

# 3. 一键部署
./dotfiles.sh setup
```

**就这么简单！🎉 剩下的都是自动处理！**

### 🔧 依赖安装（可选）

如果要使用完整的桌面环境功能：

#### Arch Linux
```bash
# 核心软件包
sudo pacman -S hyprland waybar kitty fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt \
               fcitx5-configtool mako ulauncher grim slurp swww wl-clipboard \
               brightnessctl playerctl network-manager-applet blueman gnome-keyring

# 可选功能
yay -S youtube-music-bin lunar-calendar-bin satty
```

### 3. 统一管理脚本

```bash
# 查看所有可用命令
./dotfiles.sh help

# 快速设置（推荐新用户）
./dotfiles.sh setup

# 高级功能
./dotfiles.sh status    # 查看配置状态
./dotfiles.sh sync      # 同步配置到仓库
./dotfiles.sh backup    # 创建配置备份
./dotfiles.sh input-method  # 专门配置输入法
```

## 🔤 中文输入法专项安装

### 🚀 快速配置输入法
```bash
# 方式一：交互式安装（推荐新手）
./scripts/install-fcitx5-rime.sh

# 方式二：一键完整安装
./scripts/install-fcitx5-rime.sh full

# 方式三：基础安装
./scripts/install-fcitx5-rime.sh basic

# 方式四：仅更新配置
./scripts/install-fcitx5-rime.sh config-only
```

### 🛠️ 输入法功能特色
- ✅ **已修复问题**：标点符号英文化、Shift键行为异常、云拼音报错
- 🎯 **智能候选**：9个候选词，支持整句输入和智能补全
- 📝 **中文标点**：自动中文标点符号（，。？！；：）  
- ⚡ **快捷操作**：Shift临时英文，Ctrl+\`切换方案，F4简繁切换
- 🔤 **多方案**：万象拼音、万象专业版、明月拼音可选
- 🌐 **云拼音**：预留云拼音接口，支持后续扩展

### 📋 输入法测试
```bash
# 测试配置状态
./scripts/test-fcitx5-rime.sh

# 查看详细文档
cat docs/fcitx5-rime-install-guide.md
```

## 🌐 网络代理配置

### 全局代理支持
本配置支持为所有GUI应用设置全局代理，包括Chrome、Firefox、VSCode等：

```bash
# 编辑 .env.local 配置代理
vim ~/dotfiles/.env.local

# 设置代理配置
ENABLE_PROXY=true          # 启用代理
PROXY_HOST=127.0.0.1       # 代理服务器地址  
PROXY_PORT=7897            # 代理端口（clash默认）
NO_PROXY=localhost,127.0.0.1  # 排除地址列表

# 应用代理配置
~/dotfiles/scripts/generate-proxy-env.sh  # 生成代理环境变量
~/dotfiles/scripts/hyprland-startup-env.sh  # 应用到系统环境

# 重启GUI应用使代理生效（或重新登录）
```

### 支持的代理类型
- **HTTP/HTTPS代理** - 支持所有基于HTTP的代理
- **SOCKS代理** - 需要本地HTTP代理转换
- **Clash/V2Ray** - 完美支持常见代理客户端

### 代理配置说明
- 代理设置会自动应用到systemd用户环境和D-Bus激活环境
- 新启动的GUI应用会自动继承代理设置
- 终端应用通过zsh配置自动使用代理
- 支持动态开启/关闭，无需重启系统

## 🔄 多设备同步

### 在另一台电脑上同步：
```bash
git clone https://github.com/laofahai/hyprland-elite-desktop ~/dotfiles
cd ~/dotfiles
cp .env.example .env.local
vim .env.local              # 修改 NTFY_TOPIC 为唯一值
./dotfiles.sh setup        # 一键同步
```

### 日常更新：
```bash
cd ~/dotfiles
git pull
./dotfiles.sh setup        # 重新应用最新配置
```

## 🔧 常用命令

```bash
# 健康提醒管理
periodic-reminders.sh start    # 启动健康提醒
periodic-reminders.sh status   # 查看服务状态
periodic-reminders.sh stop     # 停止健康提醒

# 配置管理
./dotfiles.sh status           # 查看配置状态
./dotfiles.sh backup           # 创建备份
./dotfiles.sh cleanup          # 清理系统缓存

# 输入法管理
./scripts/test-fcitx5-rime.sh  # 测试输入法配置
fcitx5-remote -r               # 重启输入法
```

## ⚙️ 重要配置

在 `.env.local` 中修改这些配置：

```bash
# 通知主题（必须唯一）
NTFY_TOPIC="yourname_laptop_$(date +%s)"

# 健康提醒频率（分钟）
BREAK_INTERVAL=120    # 休息提醒
WATER_INTERVAL=180    # 喝水提醒
EYE_INTERVAL=60       # 护眼提醒
```

## 🎛️ 快捷键

### 基础操作
| 快捷键 | 功能 |
|--------|------|
| `Super + Q` | 打开终端 |
| `Super + C` | 关闭窗口 |
| `Super + E` | 文件管理器 |
| `Alt + \`` | 应用启动器 (Ulauncher) |
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

### Obsidian 快速捕获
| 快捷键 | 功能 |
|--------|------|
| `Alt + I` | 快速捕获想法/任务到 Obsidian |
| `Alt + Shift + I` | 快速添加任务到 Obsidian |

### 中文输入法
| 快捷键 | 功能 |
|--------|------|
| `Ctrl + Space` | 切换中英文输入法 |
| `Ctrl + \`` | 选择输入方案（万象/明月拼音等） |
| `Shift` | 临时输入英文（不提交候选词） |
| `F4` | 切换简繁体 |
| `- =` | 翻页（或 `, .`） |
| `/fh` | 输入符号 |

## 🔧 内置修复

### 🖥️ 应用程序优化
系统自动修复常见问题：
- **WPS Office** - 修复高DPI下字体模糊锯齿问题
- **微信文件** - 使用系统默认应用打开接收的文件
- **字体渲染** - 优化整体字体显示效果

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

### 🔔 智能通知系统
状态栏集成的通知中心，支持高级功能：
- 💬 **智能过滤** - 自动过滤系统控制通知
- 🔁 **通知恢复** - 防重复恢复机制
- ✨ **直观操作** - 左键恢复、右键清空
- 🎨 **状态显示** - 不同状态不同图标（🔔活跃、🕰️历史、🔕无通知）

```bash
# 测试通知系统功能
./test-notification-logic.sh

# 查看详细文档
cat NOTIFICATION_SYSTEM.md
```

### 番茄工作法
状态栏集成的番茄计时器：
- 25分钟工作 → 5分钟休息
- 4个周期后长休息（15分钟）
- 支持暂停/重置/跳过

## 📁 项目结构

```
dotfiles/
├── dotfiles.sh                # 🆕 统一管理脚本（971行）
├── config/                   # 应用配置文件
│   ├── hypr/                # Hyprland 窗口管理器
│   ├── waybar/              # 状态栏（番茄钟、TOTP等）
│   ├── fcitx5-rime/         # 🆕 中文输入法（万象/明月拼音）
│   ├── fcitx5/              # fcitx5 基础配置
│   ├── sddm/                # 登录管理器主题
│   ├── mako/                # 智能通知系统
│   ├── swww/                # 壁纸管理
│   ├── totp/                # 双因素认证
│   ├── kitty/               # 终端模拟器
│   ├── ulauncher/           # 应用启动器
│   └── ...                  # 其他20+应用配置
├── scripts/                  # 实用脚本和工具（35个脚本）
│   ├── lib/common.sh        # 通用函数库（398行）
│   ├── install-fcitx5-rime.sh  # 🆕 输入法专用安装器
│   ├── test-fcitx5-rime.sh     # 🆕 输入法测试工具
│   ├── notification-manager.sh # 通知管理
│   ├── pomodoro-*.sh        # 番茄工作法
│   ├── totp-*.sh            # TOTP管理
│   └── ...
├── docs/                     # 文档（8个文档，1340行）
│   ├── fcitx5-rime-install-guide.md  # 🆕 输入法安装指南
│   ├── fcitx5-rime-config.md         # 输入法配置说明
│   └── ...
├── shell/                    # Shell 配置 (zsh/bash)
├── screenshots/              # 项目截图
├── .env.example             # 环境变量模板
└── README.md                # 项目说明
```

## 🔧 配置管理

### 🆕 统一管理脚本
```bash
# 查看所有可用命令
./dotfiles.sh help

# 检查配置状态
./dotfiles.sh status

# 备份当前配置
./dotfiles.sh backup

# 恢复备份
./dotfiles.sh restore backup_name
```

### 🔒 隐私保护
项目已配置完善的 `.gitignore`，以下个人数据不会被提交：
- 🔐 **TOTP 密钥** - 二步验证私钥
- 📝 **输入法数据** - 个人词典和历史
- ⚙️ **应用状态** - 番茄钟、Claude 设置等
- 📊 **缓存数据** - 临时文件和系统缓存

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

### 个人配置文件
创建以下文件进行个人化配置：
- `.env.local` - 个人环境变量
- `shell/zshrc.local` - 个人 shell 配置
- `config/totp/secrets.conf` - TOTP 密钥

## 🐛 故障排除

### 服务重启
```bash
# 重启关键服务
pkill waybar && waybar &
pkill mako && mako &
pkill fcitx5 && fcitx5 -d

# 输入法问题排查
fcitx5-diagnose                    # 系统诊断
./scripts/test-fcitx5-rime.sh     # 测试配置
rime_deployer --build ~/.local/share/fcitx5/rime/  # 重新部署
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