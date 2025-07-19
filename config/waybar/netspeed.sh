#!/bin/bash

# 网络速度监控脚本
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

if [ -z "$INTERFACE" ]; then
    echo "{\"text\": \"󰖪\", \"tooltip\": \"无网络连接\"}"
    exit 0
fi

# 获取网络统计
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

sleep 1

RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# 计算速度 (bytes/sec)
RX_SPEED=$((RX2 - RX1))
TX_SPEED=$((TX2 - TX1))

# 转换为可读格式
format_speed() {
    local speed=$1
    if [ $speed -lt 1024 ]; then
        echo "${speed}B/s"
    elif [ $speed -lt 1048576 ]; then
        echo "$((speed / 1024))K/s"
    else
        echo "$((speed / 1048576))M/s"
    fi
}

DOWN=$(format_speed $RX_SPEED)
UP=$(format_speed $TX_SPEED)

echo "{\"text\": \"󰇚 $DOWN 󰕒 $UP\", \"tooltip\": \"下载: $DOWN\\n上传: $UP\"}"