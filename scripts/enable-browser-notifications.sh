#!/bin/bash

# 启用浏览器通知设置脚本
# 配置常用网站的通知权限

echo "🔔 配置浏览器通知权限..."

# Chrome 配置目录
CHROME_CONFIG="$HOME/.config/google-chrome/Default"
CHROME_PREFS="$CHROME_CONFIG/Preferences"

# 创建备份
if [[ -f "$CHROME_PREFS" ]]; then
    cp "$CHROME_PREFS" "$CHROME_PREFS.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ 已备份 Chrome 配置文件"
fi

# 常用需要通知的网站列表
NOTIFICATION_SITES=(
    "https://github.com"
    "https://gmail.com"
    "https://outlook.com"
    "https://web.whatsapp.com"
    "https://web.telegram.org"
    "https://discord.com"
    "https://slack.com"
    "https://teams.microsoft.com"
    "https://calendar.google.com"
    "https://drive.google.com"
    "https://notion.so"
    "https://trello.com"
    "https://asana.com"
    "https://linear.app"
    "https://figma.com"
)

# 生成网站通知提示
echo ""
echo "📱 建议为以下网站启用通知："
printf '%s\n' "${NOTIFICATION_SITES[@]}"

echo ""
echo "💡 启用步骤："
echo "1. 访问网站"
echo "2. 当网站请求通知权限时点击'允许'"
echo "3. 或者在 Chrome 设置 → 隐私和安全性 → 网站设置 → 通知 中手动添加"

echo ""
echo "🔧 Chrome 通知设置路径："
echo "chrome://settings/content/notifications"

# 测试通知
notify-send "浏览器通知配置" "请按照提示配置网站通知权限" -i web-browser -u normal -t 10000

echo "✅ 配置完成！"
