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

# 获取历史通知数量（简单有效的方法）
HISTORY_COUNT=$(makoctl history 2>/dev/null | grep "^Notification" | wc -l)
if [[ -z "$HISTORY_COUNT" ]]; then
    HISTORY_COUNT=0
fi

# 生成显示内容
if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
    # 有可见通知
    echo "{\"text\": \"󰂚 $VISIBLE_COUNT\", \"tooltip\": \"$VISIBLE_COUNT 条当前通知\\n$HISTORY_COUNT 条历史通知\\n\\n左键：关闭当前通知\\n中键：仅关闭当前通知\\n右键：清空所有通知\", \"class\": \"notification-active\"}"
elif [[ "$HISTORY_COUNT" -gt 0 ]]; then
    # 没有可见通知，但有历史
    echo "{\"text\": \"󰌐 $HISTORY_COUNT\", \"tooltip\": \"$HISTORY_COUNT 条历史通知\\n\\n左键：恢复最近通知\\n中键：无操作\\n右键：清空历史通知\", \"class\": \"notification-history\"}"
else
    # 无通知 - 使用静静的铃铛图标
    echo "{\"text\": \"󰄝\", \"tooltip\": \"无通知\", \"class\": \"notification-empty\"}"
fi
