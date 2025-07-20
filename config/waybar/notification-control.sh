#!/bin/bash

# 通知中心控制脚本
# 处理通知的各种操作

if ! command -v makoctl &>/dev/null; then
    notify-send "错误" "mako未安装或不可用"
    exit 1
fi

# 检查 mako 是否运行
if ! pgrep -x mako > /dev/null; then
    notify-send "错误" "mako未运行"
    exit 1
fi

case "$1" in
    "left"|"dismiss")
        # 左键：关闭所有当前通知
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
            makoctl dismiss --all
            notify-send "通知" "已关闭 $VISIBLE_COUNT 条通知" -t 2000
        else
            # 如果没有可见通知，清除历史
            HISTORY_COUNT=$(makoctl history 2>/dev/null | jq '.data[]?.[] | length' 2>/dev/null | awk '{sum += $1} END {print sum+0}')
            if [[ "$HISTORY_COUNT" -gt 0 ]]; then
                makoctl dismiss --all
                makoctl reload  # 清除历史的更好方法
                notify-send "通知" "已清除历史通知" -t 2000
            fi
        fi
        ;;
    "middle"|"clear_history")
        # 中键：清除历史通知
        HISTORY_COUNT=$(makoctl history 2>/dev/null | jq '.data[]?.[] | length' 2>/dev/null | awk '{sum += $1} END {print sum+0}')
        if [[ "$HISTORY_COUNT" -gt 0 ]]; then
            makoctl reload  # 这会清除历史
            notify-send "通知" "已清除历史通知" -t 2000
        else
            notify-send "通知" "没有历史通知需要清除" -t 2000
        fi
        ;;
    "right"|"restore")
        # 右键：恢复最近的通知
        LATEST_NOTIFICATION=$(makoctl history 2>/dev/null | jq -r '.data[0][0]?.summary?.data // "无历史通知"')
        if [[ "$LATEST_NOTIFICATION" != "无历史通知" ]] && [[ -n "$LATEST_NOTIFICATION" ]]; then
            makoctl restore
            notify-send "通知" "已恢复最近的通知" -t 2000
        else
            notify-send "通知" "没有可恢复的通知" -t 2000
        fi
        ;;
    "toggle_mode")
        # 切换通知模式（勿扰/正常）
        if [[ -f "$HOME/.config/mako/do_not_disturb" ]]; then
            rm "$HOME/.config/mako/do_not_disturb"
            makoctl reload
            notify-send "通知模式" "正常模式" -t 2000
        else
            touch "$HOME/.config/mako/do_not_disturb"
            makoctl reload
            notify-send "通知模式" "勿扰模式" -t 2000
        fi
        ;;
    *)
        echo "用法: $0 {left|middle|right|toggle_mode}"
        echo "  left   - 关闭所有通知/清除历史"
        echo "  middle - 清除历史通知"
        echo "  right  - 恢复最近通知"
        echo "  toggle_mode - 切换勿扰模式"
        exit 1
        ;;
esac

# 更新waybar显示
pkill -SIGRTMIN+7 waybar 2>/dev/null || true
