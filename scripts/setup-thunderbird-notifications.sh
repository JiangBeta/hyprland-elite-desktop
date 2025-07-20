#!/bin/bash

# Thunderbird 邮件通知配置脚本

echo "📧 配置 Thunderbird 邮件通知..."

# 检查 Thunderbird 是否安装
if ! command -v thunderbird &> /dev/null; then
    echo "❌ Thunderbird 未安装"
    echo "安装命令: sudo pacman -S thunderbird"
    exit 1
fi

# Thunderbird 配置目录
THUNDERBIRD_PROFILE_DIR="$HOME/.thunderbird"
PROFILE_INI="$THUNDERBIRD_PROFILE_DIR/profiles.ini"

if [[ ! -f "$PROFILE_INI" ]]; then
    echo "⚠️  Thunderbird 配置文件未找到，请先运行 Thunderbird 创建配置文件"
    echo "💡 运行 'thunderbird' 命令启动应用程序"
    exit 1
fi

# 查找默认配置文件路径
DEFAULT_PROFILE=$(grep -A2 '\[Profile0\]' "$PROFILE_INI" | grep 'Path=' | cut -d'=' -f2)
PROFILE_PATH="$THUNDERBIRD_PROFILE_DIR/$DEFAULT_PROFILE"

echo "📁 配置文件路径: $PROFILE_PATH"

# 创建 user.js 配置文件以启用通知
USER_JS="$PROFILE_PATH/user.js"

echo "🔧 配置 Thunderbird 通知设置..."

cat > "$USER_JS" << 'EOF'
// Thunderbird 通知配置

// 启用桌面通知
user_pref("mail.biff.show_alert", true);
user_pref("mail.biff.use_system_alert", true);

// 新邮件通知设置
user_pref("mail.biff.animate_dock_icon", true);
user_pref("mail.biff.show_tray_icon", true);
user_pref("mail.biff.show_tray_icon_always", true);

// 通知详细信息
user_pref("mail.biff.alert.show_preview", true);
user_pref("mail.biff.alert.show_subject", true);
user_pref("mail.biff.alert.show_sender", true);

// 通知持续时间 (毫秒)
user_pref("alerts.totalOpenTime", 8000);

// 启用声音通知
user_pref("mail.biff.play_sound", true);
user_pref("mail.biff.play_sound.type", 0);  // 0=系统默认声音

// 聊天通知
user_pref("mail.chat.show_desktop_notifications", true);

// 日历通知
user_pref("calendar.alarms.playsound", true);
user_pref("calendar.alarms.showmissed", true);
EOF

echo "✅ Thunderbird 通知配置完成"

# 创建邮件检查频率配置提示
echo ""
echo "📋 邮件检查设置建议:"
echo "1. 打开 Thunderbird"
echo "2. 转到 账户设置 → 服务器设置"
echo "3. 设置 '检查新消息' 间隔为 5-10 分钟"
echo "4. 启用 '启动时检查邮件'"

# 检查是否需要重启 Thunderbird
if pgrep thunderbird > /dev/null; then
    echo ""
    echo "⚠️  请重启 Thunderbird 以应用配置更改"
    echo "   pkill thunderbird && thunderbird &"
fi

echo ""
echo "🔔 测试通知:"
notify-send "Thunderbird 配置" "邮件通知已启用，请重启应用程序" -i thunderbird -u normal -t 8000
