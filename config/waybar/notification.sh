#!/bin/bash

# 通知中心状态脚本 - 支持 mako
# 使用 mako 通知守护进程

if ! command -v makoctl &>/dev/null; then
    echo "{\"text\": \"󰂜\", \"tooltip\": \"mako未安装\"}"
    exit 0
fi

# 检查 mako 是否运行
if ! pgrep -x mako > /dev/null; then
    echo "{\"text\": \"󰂜\", \"tooltip\": \"mako未运行\"}"
    exit 0
fi

# 获取当前显示的通知数量
VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
    VISIBLE_COUNT=0
fi

# 获取历史通知数量
HISTORY_JSON=$(makoctl history 2>/dev/null)
if [[ $? -eq 0 ]] && [[ -n "$HISTORY_JSON" ]]; then
    HISTORY_COUNT=$(echo "$HISTORY_JSON" | jq '.data[]?.[] | length' 2>/dev/null | awk '{sum += $1} END {print sum+0}')
else
    HISTORY_COUNT=0
fi

# 生成显示内容
if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
    # 有可见通知
    echo "{\"text\": \"󰂚 $VISIBLE_COUNT\", \"tooltip\": \"$VISIBLE_COUNT 条当前通知\\n$HISTORY_COUNT 条历史通知\\n\\n左键：关闭所有\\n中键：清除历史\\n右键：恢复最近\", \"class\": \"notification-active\"}"
elif [[ "$HISTORY_COUNT" -gt 0 ]]; then
    # 没有可见通知，但有历史
    echo "{\"text\": \"󰂛\", \"tooltip\": \"$HISTORY_COUNT 条历史通知\\n\\n左键：清除历史\\n右键：恢复最近\", \"class\": \"notification-history\"}"
else
    # 无通知
    echo "{\"text\": \"󰂜\", \"tooltip\": \"无通知\", \"class\": \"notification-empty\"}"
fi
