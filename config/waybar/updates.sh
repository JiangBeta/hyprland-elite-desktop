#!/bin/bash

# 系统更新检查脚本 - 没有更新时隐藏

# 检查系统更新数量
UPDATES=$(checkupdates 2>/dev/null | wc -l)

if [ "$UPDATES" -gt 0 ]; then
    echo "{\"text\": \"󰏖 $UPDATES\", \"tooltip\": \"有 $UPDATES 个更新可用\", \"class\": \"updates-available\"}"
else
    # 没有更新时返回空，waybar会隐藏模块
    echo "{\"text\": \"\", \"tooltip\": \"系统已是最新\"}"
fi