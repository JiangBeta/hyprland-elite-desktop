# 🔄 多设备同步指南

## 📱 在另一台电脑上同步配置

### 方法一：完整同步（推荐）

**第一次设置：**
```bash
# 1. 克隆项目
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# 2. 复制配置模板
cp .env.example .env.local

# 3. 编辑个人配置
vim .env.local
# 重要：修改 NTFY_TOPIC 为唯一值，如：
# NTFY_TOPIC="username_laptop_20250720"

# 4. 一键部署
./dotfiles.sh setup
```

**后续更新：**
```bash
cd ~/dotfiles
git pull
./dotfiles.sh setup  # 重新应用配置
```

---

### 方法二：选择性同步

**只同步基础配置：**
```bash
# 1. 克隆项目
git clone <your-repo-url> ~/dotfiles

# 2. 手动链接需要的配置
ln -sf ~/dotfiles/shell/zshrc ~/.zshrc
ln -sf ~/dotfiles/config/git ~/.config/

# 3. 重新加载shell
source ~/.zshrc
```

**按需添加功能：**
```bash
# 桌面环境（需要Hyprland）
ln -sf ~/dotfiles/config/hypr ~/.config/
ln -sf ~/dotfiles/config/waybar ~/.config/

# 健康提醒
~/dotfiles/scripts/periodic-reminders.sh start
```

---

## ⚙️ 配置说明

### 必须修改的配置
在 `.env.local` 中修改以下配置：

```bash
# 通知主题（必须唯一）
NTFY_TOPIC="your_unique_topic_name"

# 根据使用习惯调整提醒间隔
BREAK_INTERVAL=120    # 休息提醒（分钟）
WATER_INTERVAL=180    # 喝水提醒（分钟）
EYE_INTERVAL=60       # 护眼提醒（分钟）
```

### 可选配置
```bash
# 系统监控阈值
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80

# 日志级别
LOG_LEVEL=INFO        # DEBUG, INFO, WARN, ERROR

# 是否启用调试模式
DEBUG_MODE=false
```

---

## 🔧 设备差异处理

### 不同的硬件配置
```bash
# 在 .env.local 中针对不同设备调整：

# 笔记本电脑
BATTERY_THRESHOLD=20
CPU_THRESHOLD=70

# 台式机
BATTERY_THRESHOLD=0   # 禁用电池监控
CPU_THRESHOLD=80
```

### 不同的桌面环境
```bash
# 只有支持 Hyprland 的设备才会应用桌面配置
# dotfiles.sh setup 会自动检测并跳过不支持的配置
```

---

## 📋 快速同步清单

### 新设备部署（5分钟）
- [ ] `git clone` 项目
- [ ] `cp .env.example .env.local`
- [ ] 编辑 `NTFY_TOPIC` 为唯一值
- [ ] 运行 `./dotfiles.sh setup`
- [ ] 重新打开终端

### 配置同步
- [ ] 定期 `git pull` 获取更新
- [ ] 检查 `.env.example` 是否有新配置项
- [ ] 运行 `./dotfiles.sh setup` 应用更新

---

## 🚨 注意事项

### 安全提醒
1. **永远不要提交 `.env.local`** - 它包含个人配置
2. **TOTP密钥需要手动导入** - 不会自动同步
3. **检查文件权限** - `chmod 600 ~/.config/totp/secrets.conf`

### 常见问题
```bash
# 权限错误
chmod +x ~/dotfiles/scripts/*.sh

# 配置冲突
diff .env.example .env.local  # 检查新配置项

# 服务异常
periodic-reminders.sh restart
```

---

## 🎯 最佳实践

### 多设备管理
1. **统一配置** - 大部分配置保持一致
2. **个性化差异** - 在 `.env.local` 中调整设备特定配置
3. **定期同步** - 每周 git pull 一次
4. **备份重要** - 定期备份 `.env.local` 和 TOTP 配置

### 更新流程
```bash
# 标准更新流程
cd ~/dotfiles
git stash            # 保存本地修改
git pull             # 拉取更新
git stash pop        # 恢复本地修改
./dotfiles.sh setup           # 重新应用配置
```

---

## 🆘 故障恢复

### 配置损坏
```bash
# 重置配置
cp .env.example .env.local
vim .env.local  # 重新配置
./dotfiles.sh setup
```

### 服务异常
```bash
# 重启所有服务
pkill -f "periodic-reminders"
periodic-reminders.sh start
```

### 权限问题
```bash
# 修复权限
chmod 700 ~/.config/totp
chmod 600 ~/.config/totp/secrets.conf
chmod +x ~/dotfiles/scripts/*.sh
```

---

## 💡 总结

**超简单同步流程：**
1. `cp .env.example .env.local`
2. 编辑 `.env.local`
3. `./dotfiles.sh setup`
4. 完成！

这就是全部步骤，其他都是自动处理的！