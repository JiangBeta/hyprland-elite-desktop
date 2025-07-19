#!/bin/bash

# 通知中心状态脚本 - 支持 mako
# 使用 mako 通知守护进程

if ! command -v makoctl &> /dev/null; then
    echo "{\"text\": \"󰂜\", \"tooltip\": \"mako未安装\"}"
    exit 0
fi

# 检查 mako 是否运行
if ! pgrep -x mako > /dev/null; then
    echo "{\"text\": \"󰂜\", \"tooltip\": \"mako未运行\"}"
    exit 0
fi

# 获取通知历史（已关闭的通知数量）
HISTORY_COUNT=$(makoctl history 2>/dev/null | jq -r '.data[0] | length' 2>/dev/null || echo "0")

# 检查是否有活动通知（显示中的通知）
# mako 会在有通知时创建临时窗口，我们通过检查 mako 进程状态来判断
if [[ "$HISTORY_COUNT" -gt 0 ]]; then
    echo "{\"text\": \"󰂚 $HISTORY_COUNT\", \"tooltip\": \"有 $HISTORY_COUNT 条历史通知\\n左键：清除所有\\n右键：恢复最近\"}"
else
    echo "{\"text\": \"󰂜\", \"tooltip\": \"无通知\"}"
fi