#!/bin/bash

# 通知系统增强设置脚本
# 一键配置各种通知功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔔 增强通知系统配置"
echo "===================="

# 检查 mako 是否运行
if ! pgrep -x mako > /dev/null; then
    echo "⚠️  mako 未运行，正在启动..."
    mako &
    sleep 2
fi

# 1. 配置浏览器通知
echo ""
echo "🌐 1. 配置浏览器通知"
echo "-------------------"
if [[ -f "$SCRIPT_DIR/enable-browser-notifications.sh" ]]; then
    bash "$SCRIPT_DIR/enable-browser-notifications.sh"
else
    echo "❌ 浏览器通知配置脚本未找到"
fi

# 2. 配置 Thunderbird 邮件通知
echo ""
echo "📧 2. 配置邮件通知"
echo "-----------------"
if [[ -f "$SCRIPT_DIR/setup-thunderbird-notifications.sh" ]]; then
    bash "$SCRIPT_DIR/setup-thunderbird-notifications.sh"
else
    echo "❌ Thunderbird 配置脚本未找到"
fi

# 3. 设置系统监控通知
echo ""
echo "💻 3. 设置系统监控"
echo "------------------"
if [[ -f "$SCRIPT_DIR/system-monitor-notify.sh" ]]; then
    # 创建 cron 任务进行系统监控
    echo "设置系统监控 cron 任务..."
    
    # 检查是否已有监控任务
    if ! crontab -l 2>/dev/null | grep -q "system-monitor-notify.sh"; then
        # 添加每5分钟检查一次的任务
        (crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_DIR/system-monitor-notify.sh") | crontab -
        echo "✅ 系统监控任务已添加到 crontab"
    else
        echo "ℹ️  系统监控任务已存在"
    fi
    
    # 运行一次测试
    bash "$SCRIPT_DIR/system-monitor-notify.sh" --status
else
    echo "❌ 系统监控脚本未找到"
fi

# 4. 启动定期健康提醒
echo ""
echo "💡 4. 启动健康提醒"
echo "------------------"
if [[ -f "$SCRIPT_DIR/periodic-reminders.sh" ]]; then
    # 测试提醒功能
    echo "测试提醒功能..."
    bash "$SCRIPT_DIR/periodic-reminders.sh" test
    
    sleep 3
    
    echo ""
    echo "是否启动定期健康提醒服务？(y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/periodic-reminders.sh" start
    fi
else
    echo "❌ 定期提醒脚本未找到"
fi

# 5. 优化 mako 配置
echo ""
echo "⚙️  5. 优化通知配置"
echo "------------------"
MAKO_CONFIG="$HOME/.config/mako/config"

if [[ -f "$MAKO_CONFIG" ]]; then
    # 备份原配置
    cp "$MAKO_CONFIG" "$MAKO_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 添加更多应用特定配置
    cat >> "$MAKO_CONFIG" << 'EOF'

# GitHub 通知
[app-name=GitHub]
default-timeout=12000
background-color=#24292e88
border-color=#f85149

# Gmail 通知
[app-name=Gmail]
default-timeout=10000
background-color=#ea433588
border-color=#ea4335

# Discord 通知
[app-name=Discord]
default-timeout=8000
background-color=#5865f288
border-color=#5865f2

# Slack 通知
[app-name=Slack]
default-timeout=10000
background-color=#4a154b88
border-color=#4a154b

# VS Code 通知
[app-name=Code]
default-timeout=6000
background-color=#007acc88
border-color=#007acc

# 系统监控通知
[app-name=system-monitor]
default-timeout=15000
background-color=#ff6b3588
border-color=#ff6b35

# 健康提醒通知
[summary~="提醒"]
default-timeout=12000
background-color=#10b98188
border-color=#10b981
EOF

    echo "✅ mako 配置已优化"
    
    # 重新加载配置
    if pgrep -x mako > /dev/null; then
        pkill mako
        mako &
        echo "🔄 mako 配置已重新加载"
    fi
else
    echo "⚠️  mako 配置文件未找到"
fi

# 6. 创建快捷测试命令
echo ""
echo "🧪 6. 创建测试命令"
echo "-----------------"

# 创建别名文件
ALIAS_FILE="$HOME/.config/notification-aliases.sh"
cat > "$ALIAS_FILE" << EOF
#!/bin/bash

# 通知系统测试别名
alias test-notification='notify-send "测试通知" "通知系统正常工作" -i dialog-information -u normal'
alias test-urgent='notify-send "紧急测试" "这是一个紧急通知" -i dialog-warning -u critical'
alias test-low='notify-send "低优先级测试" "这是一个低优先级通知" -i dialog-information -u low'

# 健康提醒控制
alias start-reminders='$SCRIPT_DIR/periodic-reminders.sh start'
alias stop-reminders='$SCRIPT_DIR/periodic-reminders.sh stop'
alias reminder-status='$SCRIPT_DIR/periodic-reminders.sh status'

# 系统状态检查
alias check-system='$SCRIPT_DIR/system-monitor-notify.sh --status'
EOF

echo "✅ 测试命令已创建: $ALIAS_FILE"
echo "   添加到 shell 配置中以使用别名"

# 7. 安装推荐的通知相关软件包
echo ""
echo "📦 7. 推荐软件包"
echo "---------------"
echo "建议安装以下软件包以增强通知体验："
echo "• libnotify-bin - 命令行通知工具"
echo "• dunst - 备用通知管理器" 
echo "• notify-osd - Ubuntu 风格通知"
echo "• xfce4-notifyd - XFCE 通知管理器"

echo ""
echo "安装命令："
echo "sudo pacman -S libnotify"

# 最终总结
echo ""
echo "🎉 通知系统增强完成！"
echo "===================="
echo ""
echo "📋 已配置的功能："
echo "• 浏览器网站通知"
echo "• Thunderbird 邮件通知" 
echo "• 系统监控警告通知"
echo "• 定期健康提醒"
echo "• 优化的 mako 配置"
echo "• 测试命令和别名"
echo ""
echo "💡 使用提示："
echo "• 运行 'source ~/.config/notification-aliases.sh' 启用测试别名"
echo "• 配置浏览器访问常用网站时启用通知权限"
echo "• 在 Thunderbird 中添加邮件账户"
echo "• 系统监控每5分钟自动检查一次"
echo ""
echo "🔧 配置文件位置："
echo "• mako: ~/.config/mako/config"
echo "• 系统监控: ~/.config/system-monitor-notify.conf"
echo "• 健康提醒: ~/.config/periodic-reminders.conf"

# 发送完成通知
notify-send "🔔 通知系统增强" "所有配置已完成！\n\n现在你应该能收到更多通知了" -i dialog-information -u normal -t 10000
