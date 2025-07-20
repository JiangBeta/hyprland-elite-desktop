#!/bin/bash

# 通知管理工具 - 查看、统计和管理通知

set -e

LOG_FILE="$HOME/.local/share/notification-log.txt"

# 显示帮助
show_help() {
    cat << 'EOF'
通知管理工具

用法: notification-manager.sh [命令] [选项]

命令:
    list [N]         显示最近 N 条通知 (默认 20)
    stats            显示通知统计信息
    filter CATEGORY  按类别筛选通知
    search KEYWORD   搜索通知内容
    clear            清空通知日志
    watch            实时监控新通知
    export FILE      导出通知到文件

选项:
    -h, --help       显示帮助

类别:
    Email, Social, System, Updates, Health, Work, Calendar,
    News, SocialMedia, Errors, Success, Finance, Weather, General

示例:
    notification-manager.sh list 50
    notification-manager.sh filter System
    notification-manager.sh search "邮件"

EOF
}

# 列出通知
list_notifications() {
    local count=${1:-20}
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📝 还没有通知历史"
        return 0
    fi
    
    echo "📋 最近 $count 条通知:"
    echo "=========================="
    tail -n "$count" "$LOG_FILE" | nl -s ". "
}

# 显示统计信息
show_stats() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📊 还没有通知数据"
        return 0
    fi
    
    echo "📊 通知统计信息"
    echo "================="
    
    local total=$(wc -l < "$LOG_FILE")
    echo "总通知数: $total"
    
    echo ""
    echo "📅 按日期统计:"
    awk '{print substr($1, 1, 10)}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -7
    
    echo ""
    echo "🏷️  按类别统计:"
    grep -o '\[.*:.*\]' "$LOG_FILE" | sed 's/\[//g' | sed 's/\]//g' | cut -d: -f1 | sort | uniq -c | sort -nr
    
    echo ""
    echo "⚡ 按级别统计:"
    grep -o '\[.*:.*\]' "$LOG_FILE" | sed 's/\[//g' | sed 's/\]//g' | cut -d: -f2 | sort | uniq -c | sort -nr
    
    echo ""
    echo "⏰ 按小时统计 (最近7天):"
    awk -v date="$(date -d '7 days ago' '+%Y-%m-%d')" '$1 >= date {print substr($2, 1, 2)}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10
}

# 按类别筛选
filter_by_category() {
    local category="$1"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📝 还没有通知历史"
        return 0
    fi
    
    echo "🔍 类别: $category 的通知"
    echo "========================"
    grep "\[$category:" "$LOG_FILE" | nl -s ". "
}

# 搜索通知
search_notifications() {
    local keyword="$1"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📝 还没有通知历史"
        return 0
    fi
    
    echo "🔍 搜索: '$keyword'"
    echo "=================="
    grep -i "$keyword" "$LOG_FILE" | nl -s ". "
}

# 清空日志
clear_log() {
    if [[ -f "$LOG_FILE" ]]; then
        echo "⚠️  确定要清空通知日志吗? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            > "$LOG_FILE"
            echo "✅ 通知日志已清空"
        else
            echo "❌ 操作已取消"
        fi
    else
        echo "📝 通知日志已经为空"
    fi
}

# 实时监控
watch_notifications() {
    echo "👁️  实时监控通知 (按 Ctrl+C 退出)"
    echo "================================"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
    
    tail -f "$LOG_FILE"
}

# 导出通知
export_notifications() {
    local output_file="$1"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📝 还没有通知历史"
        return 1
    fi
    
    if [[ -z "$output_file" ]]; then
        output_file="notifications_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    cp "$LOG_FILE" "$output_file"
    echo "✅ 通知已导出到: $output_file"
    
    # 添加统计信息
    {
        echo ""
        echo "=== 统计信息 ==="
        echo "导出时间: $(date)"
        show_stats
    } >> "$output_file"
}

# 生成今日报告
daily_report() {
    local today=$(date '+%Y-%m-%d')
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "📝 今天还没有通知"
        return 0
    fi
    
    echo "📊 今日通知报告 ($today)"
    echo "========================="
    
    local today_notifications=$(grep "^$today" "$LOG_FILE")
    local count=$(echo "$today_notifications" | grep -c . 2>/dev/null || echo "0")
    
    if [[ $count -eq 0 ]]; then
        echo "📝 今天还没有通知"
        return 0
    fi
    
    echo "总计: $count 条通知"
    echo ""
    
    echo "🏷️  按类别:"
    echo "$today_notifications" | grep -o '\[.*:.*\]' | sed 's/\[//g' | sed 's/\]//g' | cut -d: -f1 | sort | uniq -c | sort -nr
    
    echo ""
    echo "⚡ 按级别:"
    echo "$today_notifications" | grep -o '\[.*:.*\]' | sed 's/\[//g' | sed 's/\]//g' | cut -d: -f2 | sort | uniq -c | sort -nr
    
    echo ""
    echo "⏰ 按小时:"
    echo "$today_notifications" | awk '{print substr($2, 1, 2)}' | sort | uniq -c | sort -nr
    
    echo ""
    echo "📋 最新 10 条:"
    echo "$today_notifications" | tail -10 | nl -s ". "
}

# 主函数
main() {
    case "${1:-}" in
        "list")
            list_notifications "${2:-20}"
            ;;
        "stats")
            show_stats
            ;;
        "filter")
            if [[ -z "$2" ]]; then
                echo "错误: 请指定类别"
                echo "用法: $0 filter CATEGORY"
                exit 1
            fi
            filter_by_category "$2"
            ;;
        "search")
            if [[ -z "$2" ]]; then
                echo "错误: 请指定搜索关键词"
                echo "用法: $0 search KEYWORD"
                exit 1
            fi
            search_notifications "$2"
            ;;
        "clear")
            clear_log
            ;;
        "watch")
            watch_notifications
            ;;
        "export")
            export_notifications "$2"
            ;;
        "daily"|"today")
            daily_report
            ;;
        "-h"|"--help"|"help")
            show_help
            ;;
        "")
            # 默认显示最近通知和今日统计
            echo "🔔 通知管理工具"
            echo "==============="
            echo ""
            daily_report
            echo ""
            list_notifications 10
            echo ""
            echo "💡 使用 '$0 --help' 查看更多命令"
            ;;
        *)
            echo "未知命令: $1"
            echo "使用 '$0 --help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
