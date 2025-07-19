#!/usr/bin/bash
# WeChat launcher without sandbox - Wayland optimized
export _portableConfig=/home/laofahai/.config/wechat/portable-config

# Wayland compatibility settings
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=1

# Force proper window handling
export WINIT_UNIX_BACKEND=wayland
export GDK_BACKEND=wayland

/usr/bin/portable $@