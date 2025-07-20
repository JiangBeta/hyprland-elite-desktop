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
    "left"|"restore")
        # 左键：恢复最近的通知（仅在有历史且无可见通知时）
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        
        if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
            # 如果有可见通知，先关闭它们
            makoctl dismiss --all
            notify-send "通知" "已关闭 $VISIBLE_COUNT 条通知" -t 2000
        else
            # 没有可见通知时，尝试恢复历史通知
            # 获取历史通知数量，过滤系统控制通知
            HISTORY_COUNT=$(makoctl history 2>/dev/null | grep -A2 "^Notification" | grep -v "已清空" | grep -v "没有可恢复" | grep -v "已关闭" | grep -v "没有通知" | grep -v "通知模式" | grep -v "正在清空" | grep "^Notification" | wc -l)
            STATE_FILE="$HOME/.cache/mako_restore_state"
            
            if [[ "$HISTORY_COUNT" -gt 0 ]]; then
                # 检查是否已经恢复过相同数量的通知
                LAST_RESTORED_COUNT=0
                if [[ -f "$STATE_FILE" ]]; then
                    LAST_RESTORED_COUNT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
                fi
                
                if [[ "$HISTORY_COUNT" != "$LAST_RESTORED_COUNT" ]]; then
                makoctl restore
                    echo "$HISTORY_COUNT" > "$STATE_FILE"
                    notify-send "通知" "已恢复最近的通知" -t 2000
                else
                    notify-send "通知" "没有新的通知可恢复" -t 2000
                fi
            else
                # 清理状态文件
                [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
                notify-send "通知" "没有可恢复的通知" -t 2000
            fi
        fi
        ;;
    "middle"|"dismiss")
        # 中键：关闭所有当前通知（不影响历史）
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        
        if [[ "$VISIBLE_COUNT" -gt 0 ]]; then
            makoctl dismiss --all
            notify-send "通知" "已关闭 $VISIBLE_COUNT 条通知" -t 2000
        else
            notify-send "通知" "没有可见通知需要关闭" -t 2000
        fi
        ;;
    "right"|"clear")
        # 右键：清空所有（当前+历史）
        VISIBLE_COUNT=$(makoctl list 2>/dev/null | jq '.data[][] | length' 2>/dev/null | head -1)
        if [[ -z "$VISIBLE_COUNT" ]] || [[ "$VISIBLE_COUNT" == "null" ]]; then
            VISIBLE_COUNT=0
        fi
        # 获取历史通知数量，过滤系统控制通知
        HISTORY_COUNT=$(makoctl history 2>/dev/null | grep -A2 "^Notification" | grep -v "已清空" | grep -v "没有可恢复" | grep -v "已关闭" | grep -v "没有通知" | grep -v "通知模式" | grep -v "正在清空" | grep "^Notification" | wc -l)
        
        TOTAL_COUNT=$((VISIBLE_COUNT + HISTORY_COUNT))
        if [[ "$TOTAL_COUNT" -gt 0 ]]; then
            makoctl dismiss --all
            
            # 清空历史的方法：使用临时配置禁用历史
            if [[ "$HISTORY_COUNT" -gt 0 ]]; then
                # 创建临时配置文件禁用历史
                TEMP_CONFIG="/tmp/mako_no_history_$$.conf"
                # 在配置文件开头添加全局配置
                echo "max-history=0" > "$TEMP_CONFIG"
                cat "$HOME/.config/mako/config" >> "$TEMP_CONFIG"
                
                # 重新加载配置
                pkill mako
                sleep 0.3
                mako -c "$TEMP_CONFIG" &
                sleep 0.5
                
                # 恢复原配置
                pkill mako
                sleep 0.3
                mako &
                sleep 0.3
                
                # 清理临时文件
                rm -f "$TEMP_CONFIG"
                
                # 不再显示通知，避免死循环
                echo "已清空所有通知 ($TOTAL_COUNT 条)" >&2
            else
                notify-send "通知" "已关闭所有通知 ($VISIBLE_COUNT 条)" -t 2000
            fi
            
            # 清理状态文件
            STATE_FILE="$HOME/.cache/mako_restore_state"
            [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
        else
            notify-send "通知" "没有通知需要清空" -t 2000
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
        echo "  left   - 智能操作：有通知时关闭，无通知时恢复"
        echo "  middle - 关闭当前可见通知"
        echo "  right  - 清空所有通知（当前+历史）"
        echo "  toggle_mode - 切换勿扰模式"
        exit 1
        ;;
esac

# 更新waybar显示
pkill -SIGRTMIN+7 waybar 2>/dev/null || true
