#!/bin/bash

# SDDM Xsetup脚本 - 登录前的系统初始化
# 这个脚本会在SDDM显示登录界面前执行

# 设置高DPI
xrandr --dpi 120 2>/dev/null || true

# 启动蓝牙服务
systemctl start bluetooth.service 2>/dev/null || true

# 启动fcitx5输入法守护进程
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
fcitx5 -d 2>/dev/null || true

# 设置键盘布局（如果需要）
setxkbmap us 2>/dev/null || true

# 加载X资源
xrdb -merge ~/.Xresources 2>/dev/null || true

exit 0