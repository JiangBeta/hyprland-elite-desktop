# 🔔 智能通知系统详细文档

Hyprland Elite Desktop 集成了一个功能强大的智能通知系统，基于 `mako` 通知守护进程，并在 Waybar 中提供了直观的管理界面。

## 🎯 核心功能

### 📱 智能通知管理
- **自动分类**：区分系统通知、应用通知和重要提醒
- **智能过滤**：自动过滤重复和无关紧要的系统控制通知
- **状态显示**：实时显示通知数量和状态

### 🔄 通知恢复系统
- **防重复机制**：避免相同通知重复恢复
- **批量恢复**：一键恢复所有被关闭的通知
- **状态记忆**：记住通知的查看状态

### 🎨 视觉状态指示
- 🔔 **活跃状态**：有新通知时显示
- 🕰️ **历史状态**：有历史通知但无新通知
- 🔕 **静默状态**：无任何通知时显示

## ⚙️ 配置文件结构

### Mako 配置 (`~/.config/mako/config`)
```ini
# 基础样式设置
background-color=#2d3748ee
text-color=#e2e8f0
border-color=#4a5568
border-size=2
border-radius=10

# 位置和大小
anchor=top-right
margin=10,20,0,0
width=350
height=120

# 行为设置
default-timeout=5000
ignore-timeout=1
layer=overlay
```

### Waybar 通知模块 (`~/.config/waybar/config.jsonc`)
```json
"custom/notifications": {
    "format": "{}",
    "exec": "~/.config/waybar/notifications.sh",
    "interval": 2,
    "on-click": "~/.config/waybar/notifications.sh --restore",
    "on-click-right": "~/.config/waybar/notifications.sh --clear",
    "tooltip": true
}
```

## 🖱️ 交互操作

### 鼠标操作
| 操作 | 功能 | 说明 |
|------|------|------|
| **左键点击** | 恢复通知 | 恢复所有被关闭的通知 |
| **右键点击** | 清空历史 | 清除所有通知历史记录 |
| **滚轮** | 浏览通知 | 在多个通知间切换（如果支持） |

### 键盘快捷键
```bash
# 查看通知（需要在 Hyprland 配置中设置）
bind = $mainMod, N, exec, makoctl restore

# 清除所有通知
bind = $mainMod SHIFT, N, exec, makoctl dismiss --all
```

## 🔧 脚本工作原理

### 主要脚本：`notifications.sh`
```bash
#!/bin/bash
# 智能通知管理脚本

# 获取当前通知状态
get_notification_status() {
    local dismissed_count=$(makoctl history | jq '.data[][] | select(.["app-name"].data != "mako") | .summary.data' | wc -l)
    local visible_count=$(makoctl list | jq '.data[][] | .summary.data' | wc -l)
    
    # 返回状态信息
    echo "$dismissed_count,$visible_count"
}

# 恢复通知逻辑
restore_notifications() {
    # 防重复恢复机制
    local last_restore_file="$HOME/.cache/mako_last_restore"
    local current_time=$(date +%s)
    
    if [ -f "$last_restore_file" ]; then
        local last_restore=$(cat "$last_restore_file")
        if [ $((current_time - last_restore)) -lt 5 ]; then
            return  # 5秒内不重复恢复
        fi
    fi
    
    # 执行恢复
    makoctl restore
    echo "$current_time" > "$last_restore_file"
}
```

### 状态检测算法
1. **读取 mako 状态**：使用 `makoctl` 获取当前和历史通知
2. **过滤系统通知**：排除 mako 自身和系统控制相关通知
3. **计算显示状态**：根据通知数量决定图标和颜色
4. **生成 JSON 输出**：为 Waybar 提供格式化的状态信息

## 🎨 主题定制

### 颜色主题
通知系统使用与整体桌面环境一致的配色方案：

```css
/* Waybar 通知样式 */
#custom-notifications {
    background: rgba(40, 44, 52, 0.8);
    color: #abb2bf;
    border-radius: 20px;
    padding: 0 12px;
    margin: 0 4px;
}

#custom-notifications.warning {
    color: #e5c07b;  /* 有通知时的颜色 */
}

#custom-notifications.critical {
    color: #e06c75;  /* 重要通知的颜色 */
}
```

### Mako 主题
```ini
# 与 Hyprland 窗口效果一致
background-color=#282c34ee
border-color=#61afef
border-radius=10
font=JetBrainsMono Nerd Font 11

# 渐变效果（如果支持）
background-color=#282c34
border-gradient=#61afef,#98c379
```

## 🚀 高级功能

### 通知优先级管理
```bash
# 高优先级通知（系统警告等）
[urgency=critical]
border-color=#e06c75
default-timeout=0

# 普通通知
[urgency=normal]
default-timeout=5000

# 低优先级通知
[urgency=low]
default-timeout=3000
```

### 应用特定规则
```ini
# 为不同应用设置不同样式
[app-name="Firefox"]
border-color=#ff7139

[app-name="Discord"]
border-color=#7289da

[app-name="VS Code"]
border-color=#007acc
```

## 🔍 故障排除

### 常见问题

#### 1. 通知不显示
```bash
# 检查 mako 服务状态
pgrep mako || mako &

# 测试通知
notify-send "测试" "通知功能正常"
```

#### 2. Waybar 模块不更新
```bash
# 重启 Waybar
pkill waybar && waybar &

# 检查脚本权限
chmod +x ~/.config/waybar/notifications.sh
```

#### 3. 通知历史丢失
```bash
# 检查 mako 配置
makoctl reload

# 查看错误日志
journalctl --user -u mako
```

### 调试模式
启用详细日志输出：
```bash
# 启动调试模式的 mako
mako --help  # 查看调试选项

# 查看通知系统状态
./test-notification-logic.sh
```

## 📈 性能优化

### 减少资源占用
- 通知历史自动清理（超过 100 条）
- 脚本执行间隔优化（2秒）
- 智能状态缓存机制

### 内存管理
```bash
# 定期清理通知历史
makoctl dismiss --all
```

## 🔮 未来计划

- [ ] 通知分组功能
- [ ] 自定义通知声音
- [ ] 通知规则图形化配置
- [ ] 与手机同步功能
- [ ] 机器学习智能过滤

---

这个通知系统是 Hyprland Elite Desktop 的重要组成部分，为用户提供了现代化、智能化的通知管理体验。