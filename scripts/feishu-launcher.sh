#!/usr/bin/bash
# Feishu launcher - Wayland optimized
# 飞书启动器，支持多种安装方式

# Wayland compatibility settings
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=1.25  # 适配高DPI

# 强制使用 Wayland 后端
export WINIT_UNIX_BACKEND=wayland
export GDK_BACKEND=wayland

# 输入法支持
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# 创建配置目录
mkdir -p "$HOME/.config/feishu"

# 检测飞书安装方式并启动
if command -v feishu >/dev/null 2>&1; then
    echo "启动飞书..."
    exec feishu --no-sandbox "$@"
elif command -v bytedance-feishu >/dev/null 2>&1; then
    echo "启动字节飞书..."
    exec bytedance-feishu --no-sandbox "$@"
elif [[ -f "/opt/bytedance/feishu/feishu" ]]; then
    echo "启动飞书 (opt安装)..."
    exec /opt/bytedance/feishu/feishu --no-sandbox "$@"
elif [[ -f "/usr/bin/lark" ]]; then
    echo "启动 Lark..."
    exec lark --no-sandbox "$@"
else
    echo "❌ 未找到飞书安装，请先安装飞书"
    echo "推荐安装方式："
    echo "  yay -S feishu"
    echo "  或者"
    echo "  yay -S bytedance-feishu"
    exit 1
fi