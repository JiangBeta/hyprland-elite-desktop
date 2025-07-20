# 📦 dotfiles 部署指南

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

### 2. 配置环境
```bash
# 复制配置模板
cp .env.example .env.local

# 编辑配置文件
vim .env.local  # 或使用你喜欢的编辑器
```

### 3. 运行部署脚本
```bash
# 即将创建的部署脚本
./dotfiles.sh --setup
```

---

## ⚙️ 环境配置详解

### 必需配置

在 `.env.local` 中，以下配置是必需的：

```bash
# 通知系统
NTFY_TOPIC="your_unique_topic_name"  # 请使用唯一的主题名

# 健康提醒（根据个人喜好调整）
BREAK_INTERVAL=120    # 休息提醒间隔（分钟）
WATER_INTERVAL=180    # 喝水提醒间隔（分钟）
EYE_INTERVAL=60       # 护眼提醒间隔（分钟）
POSTURE_INTERVAL=90   # 坐姿提醒间隔（分钟）

# 日志配置
LOG_LEVEL=INFO        # DEBUG, INFO, WARN, ERROR
LOG_DIR=$HOME/.local/var/log/dotfiles
```

### 可选配置

```bash
# 系统监控阈值
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85

# 代理设置（如果需要）
ENABLE_PROXY=false
PROXY_HOST=127.0.0.1
PROXY_PORT=7897

# 调试模式
DEBUG_MODE=false
```

---

## 🛠️ 分步部署

### 第一步：基础环境
```bash
# 1. 安装必要依赖
# Arch Linux:
sudo pacman -S hyprland waybar mako swww jq curl bc oathtool

# Ubuntu/Debian:
# sudo apt install jq curl bc oathtool
# # Hyprland 和 waybar 需要从其他源安装

# 2. 创建必要目录
mkdir -p ~/.config ~/.local/bin ~/.local/var/log/dotfiles
```

### 第二步：配置文件
```bash
# 1. 基础桌面环境配置
ln -sf ~/dotfiles/config/hypr ~/.config/
ln -sf ~/dotfiles/config/waybar ~/.config/
ln -sf ~/dotfiles/config/mako ~/.config/

# 2. Shell 配置
ln -sf ~/dotfiles/shell/zshrc ~/.zshrc

# 3. 应用配置
ln -sf ~/dotfiles/config/git ~/.config/
```

### 第三步：脚本和服务
```bash
# 1. 添加 scripts 到 PATH
echo 'export PATH="$HOME/dotfiles/scripts:$PATH"' >> ~/.bashrc

# 2. 测试环境配置
~/dotfiles/scripts/load-env.sh

# 3. 测试健康提醒
~/dotfiles/scripts/periodic-reminders.sh test
```

### 第四步：启用服务
```bash
# 1. 设置 cron 任务（系统监控）
(crontab -l 2>/dev/null; echo "*/30 * * * * $HOME/dotfiles/scripts/system-monitor-notify.sh") | crontab -

# 2. 启动健康提醒服务
~/dotfiles/scripts/periodic-reminders.sh start

# 3. 验证服务状态
~/dotfiles/scripts/periodic-reminders.sh status
```

---

## 🔒 安全注意事项

### TOTP 配置
```bash
# 1. 创建 TOTP 配置目录
mkdir -p ~/.config/totp
chmod 700 ~/.config/totp

# 2. 设置正确的文件权限
touch ~/.config/totp/secrets.conf
chmod 600 ~/.config/totp/secrets.conf

# 3. 手动导入 TOTP 密钥（不要使用硬编码）
# 使用 Google Authenticator 导出功能，然后：
# python3 ~/dotfiles/scripts/import-totp.py 'otpauth-migration://...'
```

### 通知配置
```bash
# 1. 使用唯一的 ntfy 主题名
NTFY_TOPIC="$(whoami)_$(hostname)_$(date +%s)"

# 2. 考虑使用私有 ntfy 服务器
NTFY_SERVER="https://your-private-ntfy-server.com"
```

---

## 🖥️ 桌面环境特定配置

### Hyprland
```bash
# 确保正确的显示器配置
# 编辑 ~/.config/hypr/hyprland.conf 中的 monitor 设置
```

### 其他桌面环境
如果不使用 Hyprland，需要调整以下配置：
- 通知守护进程（替换 mako）
- 状态栏（替换 waybar）
- 窗口管理器相关脚本

---

## 🔧 故障排除

### 常见问题

1. **权限错误**
   ```bash
   chmod +x ~/dotfiles/scripts/*.sh
   ```

2. **依赖缺失**
   ```bash
   # 检查依赖
   ~/dotfiles/scripts/load-env.sh
   ```

3. **通知不工作**
   ```bash
   # 测试通知系统
   notify-send "测试" "这是一条测试通知"
   ```

4. **进程过多**
   ```bash
   # 停止所有相关进程
   pkill -f "periodic-reminders"
   ~/dotfiles/scripts/periodic-reminders.sh stop
   ```

### 日志查看
```bash
# 查看服务日志
tail -f ~/.local/var/log/dotfiles/periodic-reminders.log

# 查看系统日志
journalctl --user -f
```

---

## 🔄 更新和维护

### 更新配置
```bash
# 1. 拉取最新配置
cd ~/dotfiles
git pull

# 2. 更新环境配置
# 检查 .env.example 是否有新的配置项
diff .env.example .env.local

# 3. 重启服务
~/dotfiles/scripts/periodic-reminders.sh restart
```

### 备份和恢复
```bash
# 备份当前配置
tar -czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/.config ~/.local/bin ~/.zshrc

# 恢复配置
# tar -xzf ~/dotfiles-backup-YYYYMMDD.tar.gz -C /
```

---

## 📊 性能优化

### 减少资源使用
```bash
# 在 .env.local 中：
# 增加提醒间隔
BREAK_INTERVAL=240  # 4小时
WATER_INTERVAL=360  # 6小时

# 减少日志级别
LOG_LEVEL=WARN

# 禁用不需要的功能
ENABLE_TIME_REMINDER=false
```

### 监控资源使用
```bash
# 检查进程状态
~/dotfiles/scripts/periodic-reminders.sh status

# 查看系统资源
htop
```

---

## 🎯 个性化配置

### 主题配置
```bash
# 在 .env.local 中自定义主题
GTK_THEME=Adwaita-dark
ICON_THEME=Papirus-Dark
CURSOR_THEME=Adwaita
```

### 快捷键配置
编辑 `~/.config/hypr/hyprland.conf` 添加自定义快捷键。

### 自定义脚本
在 `~/dotfiles/scripts/custom/` 目录下添加个人脚本，它们会自动添加到 PATH。

---

## ✅ 验证清单

部署完成后，请验证以下功能：

- [ ] 基础桌面环境正常启动
- [ ] waybar 显示正常
- [ ] 通知系统工作正常
- [ ] 健康提醒服务运行正常
- [ ] TOTP 工具可正常使用
- [ ] 系统监控正常工作
- [ ] 日志文件正常写入
- [ ] 所有依赖安装完成

## 📞 支持

如果遇到问题：
1. 查看日志文件
2. 检查 GitHub Issues
3. 运行诊断脚本：`~/dotfiles/scripts/diagnose.sh`