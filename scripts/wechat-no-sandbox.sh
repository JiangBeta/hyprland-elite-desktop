#!/usr/bin/bash
# WeChat launcher without sandbox - Wayland optimized
# 支持多种微信安装方式

# 创建配置目录
mkdir -p "$HOME/.config/wechat"
export _portableConfig="$HOME/.config/wechat/portable-config"

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

# 检测微信安装方式并启动
if command -v wechat-uos >/dev/null 2>&1; then
    # UOS 版微信
    echo "启动 UOS 版微信..."
    exec wechat-uos --no-sandbox "$@"
elif command -v wechat >/dev/null 2>&1; then
    # 其他版本微信
    echo "启动微信..."
    exec wechat --no-sandbox "$@"
elif [[ -f "/usr/bin/portable" ]]; then
    # Portable 版微信
    echo "启动 Portable 版微信..."
    exec /usr/bin/portable "$@"
elif [[ -f "/opt/wechat-devtools/wechat" ]]; then
    # 开发者工具版
    echo "启动微信开发者工具..."
    exec /opt/wechat-devtools/wechat --no-sandbox "$@"
else
    echo "❌ 未找到微信安装，请先安装微信"
    echo "推荐安装方式："
    echo "  yay -S wechat-uos"
    echo "  或者"
    echo "  yay -S electronic-wechat"
    exit 1
fi