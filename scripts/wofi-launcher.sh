#!/bin/bash

# Wofi 启动器 - 防止重复启动

# 如果已经运行则直接退出，不做任何操作
if pidof wofi > /dev/null 2>&1; then
    exit 0
fi

# 启动 wofi
exec wofi --show drun --conf ~/.config/wofi/config --style ~/.config/wofi/style.css