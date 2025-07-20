#!/bin/bash

# SDDM 配置脚本
# 需要使用 sudo 权限运行

set -e

echo "配置 SDDM 登录管理器..."

# 检查是否安装了 SDDM
if ! command -v sddm >/dev/null 2>&1; then
    echo "错误: SDDM 未安装。请先运行："
    echo "  sudo pacman -S sddm"
    exit 1
fi

# 检查是否安装了 Sugar Candy 主题
if [ ! -d "/usr/share/sddm/themes/sugar-candy" ]; then
    echo "错误: Sugar Candy 主题未安装。请先运行："
    echo "  yay -S sddm-sugar-candy-git"
    exit 1
fi

# 配置文件路径
SDDM_CONF="/etc/sddm.conf"
THEME_CONF="/usr/share/sddm/themes/sugar-candy/theme.conf"
DOTFILES_DIR="$HOME/dotfiles"

echo "需要 sudo 权限来配置 SDDM..."

# 创建 SDDM 主配置文件
sudo tee "$SDDM_CONF" > /dev/null << 'EOF'
[Theme]
Current=sugar-candy

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
InputMethod=fcitx5
# 默认使用标准 Hyprland 会话
DefaultSession=hyprland.desktop

[Users]
MaximumUid=60000
MinimumUid=1000
RememberLastUser=false
RememberLastSession=false

[X11]
# 启用高DPI支持
ServerArguments=-nolisten tcp -dpi 120
DisplayCommand=/usr/share/sddm/scripts/Xsetup

[Wayland]
# Wayland会话支持
SessionCommand=/usr/share/wayland-sessions
SessionDir=/usr/share/wayland-sessions
EOF

# 复制主题配置
if [ -f "$DOTFILES_DIR/config/sddm/sugar-candy/theme.conf" ]; then
    echo "复制自定义主题配置..."
    sudo cp "$DOTFILES_DIR/config/sddm/sugar-candy/theme.conf" "$THEME_CONF"
fi

# 创建 Xsetup 脚本以设置缩放
sudo tee /usr/share/sddm/scripts/Xsetup > /dev/null << 'EOF'
#!/bin/sh
# Set X DPI
xrandr --dpi 120
EOF
sudo chmod +x /usr/share/sddm/scripts/Xsetup

# 设置背景图片
BACKGROUNDS_DIR="/usr/share/backgrounds"
if [ ! -d "$BACKGROUNDS_DIR/archlinux" ]; then
    echo "创建背景图片目录..."
    sudo mkdir -p "$BACKGROUNDS_DIR/archlinux"
fi

# 如果有自定义背景图片，复制过去
if [ -f "$DOTFILES_DIR/wallpapers/login-background.jpg" ]; then
    echo "复制自定义登录背景..."
    sudo cp "$DOTFILES_DIR/wallpapers/login-background.jpg" "$BACKGROUNDS_DIR/archlinux/landscape.jpg"
else
    echo "提示: 可以将登录背景图片放在 $DOTFILES_DIR/wallpapers/login-background.jpg"
fi

# 启用 SDDM 服务
echo "启用 SDDM 服务..."
sudo systemctl enable sddm.service

echo ""
echo "✅ SDDM 配置完成！"
echo ""
echo "注意事项："
echo "1. 重启系统后生效"
echo "2. 可以使用以下命令测试 SDDM："
echo "   sudo systemctl start sddm.service"
echo "3. 如需切换回其他登录管理器："
echo "   sudo systemctl disable sddm.service"
echo ""
echo "自定义选项："
echo "- 登录背景: 将图片放在 ~/dotfiles/wallpapers/login-background.jpg"
echo "- 主题配置: 编辑 ~/dotfiles/config/sddm/sugar-candy/theme.conf"