#!/bin/bash

# 通知中心状态脚本
# 需要安装 swaync: yay -S swaync

if ! command -v swaync-client &> /dev/null; then
    echo "{\"text\": \"󰂜\", \"tooltip\": \"swaync未安装\"}"
    exit 0
fi

# 获取通知状态
if swaync-client -D &> /dev/null; then
    # Do Not Disturb 模式
    if swaync-client -c &> /dev/null; then
        echo "{\"text\": \"󰂛\", \"tooltip\": \"勿扰模式 - 有通知\"}"
    else
        echo "{\"text\": \"󰂜\", \"tooltip\": \"勿扰模式\"}"
    fi
else
    # 正常模式
    if swaync-client -c &> /dev/null; then
        echo "{\"text\": \"󰂚\", \"tooltip\": \"有新通知\"}"
    else
        echo "{\"text\": \"󰂜\", \"tooltip\": \"无通知\"}"
    fi
fi