#!/bin/bash

# SDDM 配置脚本 - 简化版确保稳定性
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

DOTFILES_DIR="${HOME}/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

echo "需要 sudo 权限来配置 SDDM..."

# 1. 禁用有问题的 UWSM 会话
if [ -f "/usr/share/wayland-sessions/hyprland-uwsm.desktop" ]; then
    echo "禁用有问题的 UWSM 会话..."
    sudo mv "/usr/share/wayland-sessions/hyprland-uwsm.desktop" "/usr/share/wayland-sessions/hyprland-uwsm.desktop.disabled" 2>/dev/null || true
fi

# 2. 应用简化的 SDDM 配置
echo "应用 SDDM 配置..."
sudo cp "$DOTFILES_DIR/config/sddm/sddm.conf" "/etc/sddm.conf"

# 3. 应用 Sugar Candy 主题配置
echo "应用 Sugar Candy 主题配置..."
sudo cp "$DOTFILES_DIR/config/sddm/sugar-candy/theme.conf" "/usr/share/sddm/themes/sugar-candy/theme.conf"

# 4. 启用并启动 SDDM
echo "启用 SDDM 服务..."
sudo systemctl enable sddm

echo "✅ SDDM 配置完成！"
echo ""
echo "📋 接下来："
echo "  sudo systemctl restart sddm"
echo ""
echo "🔧 如需重新启用 UWSM 会话："
echo "  sudo mv /usr/share/wayland-sessions/hyprland-uwsm.desktop.disabled /usr/share/wayland-sessions/hyprland-uwsm.desktop"