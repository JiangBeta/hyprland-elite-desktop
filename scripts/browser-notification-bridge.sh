#!/bin/bash

# 浏览器通知桥接脚本
# 将浏览器中的通知转发到系统通知管理器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.local/share/browser-notifications.log"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log_notification() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

# Claude 通知处理
handle_claude_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    # 记录日志
    log_notification "Claude: $title - $message"
    
    # 发送系统通知
    "$SCRIPT_DIR/enhanced-notify.sh" \
        -c AI -l "$urgency" \
        -t "🤖 Claude" \
        -m "$title\n\n$message" \
        --timeout 12000
}

# GitHub 通知处理
handle_github_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    log_notification "GitHub: $title - $message"
    
    "$SCRIPT_DIR/enhanced-notify.sh" \
        -c Development -l "$urgency" \
        -t "🐙 GitHub" \
        -m "$title\n\n$message" \
        --timeout 10000
}

# Gmail 通知处理
handle_gmail_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    log_notification "Gmail: $title - $message"
    
    "$SCRIPT_DIR/enhanced-notify.sh" \
        -c Email -l "$urgency" \
        -t "✉️ Gmail" \
        -m "$title\n\n$message" \
        --timeout 15000
}

# Discord 通知处理
handle_discord_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    log_notification "Discord: $title - $message"
    
    "$SCRIPT_DIR/enhanced-notify.sh" \
        -c Social -l "$urgency" \
        -t "💬 Discord" \
        -m "$title\n\n$message" \
        --timeout 8000
}

# 通用浏览器通知处理
handle_browser_notification() {
    local source="$1"
    local title="$2"
    local message="$3"
    local urgency="${4:-normal}"
    
    case "$source" in
        *claude*|*anthropic*)
            handle_claude_notification "$title" "$message" "$urgency"
            ;;
        *github*)
            handle_github_notification "$title" "$message" "$urgency"
            ;;
        *gmail*|*mail.google*)
            handle_gmail_notification "$title" "$message" "$urgency"
            ;;
        *discord*)
            handle_discord_notification "$title" "$message" "$urgency"
            ;;
        *)
            # 通用处理
            log_notification "$source: $title - $message"
            "$SCRIPT_DIR/enhanced-notify.sh" \
                -c Web -l "$urgency" \
                -t "🌐 $source" \
                -m "$title\n\n$message" \
                --timeout 8000
            ;;
    esac
}

# 监听浏览器通知的函数
monitor_browser_notifications() {
    echo "🔍 启动浏览器通知监听..."
    
    # 创建命名管道用于接收通知
    local pipe="/tmp/browser-notifications.pipe"
    if [[ ! -p "$pipe" ]]; then
        mkfifo "$pipe"
    fi
    
    echo "📡 监听管道: $pipe"
    echo "💡 浏览器可以通过以下方式发送通知："
    echo "   echo 'claude|需要确认|请确认操作|urgent' > $pipe"
    
    # 持续监听管道
    while true; do
        if read -r line < "$pipe"; then
            if [[ -n "$line" ]]; then
                # 解析通知格式: source|title|message|urgency
                IFS='|' read -r source title message urgency <<< "$line"
                
                # 设置默认值
                source="${source:-unknown}"
                title="${title:-通知}"
                message="${message:-}"
                urgency="${urgency:-normal}"
                
                # 处理通知
                handle_browser_notification "$source" "$title" "$message" "$urgency"
            fi
        fi
    done
}

# 创建浏览器扩展或用户脚本
create_browser_script() {
    local script_file="$HOME/.local/share/browser-notification-sender.js"
    
    cat > "$script_file" << 'EOF'
// 浏览器通知发送脚本
// 可以作为用户脚本或浏览器扩展使用

(function() {
    'use strict';
    
    const NOTIFICATION_PIPE = '/tmp/browser-notifications.pipe';
    
    // 发送通知到系统
    function sendNotificationToSystem(source, title, message, urgency = 'normal') {
        // 通过fetch发送到本地服务器（需要配合后端服务）
        const data = `${source}|${title}|${message}|${urgency}`;
        
        // 方法1: 使用 fetch 发送到本地服务器
        fetch('http://localhost:8765/notification', {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain' },
            body: data
        }).catch(e => console.log('Notification bridge not available'));
        
        // 方法2: 存储到 localStorage，让后台脚本读取
        const notifications = JSON.parse(localStorage.getItem('pendingNotifications') || '[]');
        notifications.push({
            source, title, message, urgency,
            timestamp: Date.now()
        });
        localStorage.setItem('pendingNotifications', JSON.stringify(notifications));
    }
    
    // 监听页面通知
    const originalNotification = window.Notification;
    if (originalNotification) {
        window.Notification = function(title, options = {}) {
            // 发送到系统
            const source = window.location.hostname;
            const message = options.body || '';
            const urgency = options.tag === 'urgent' ? 'critical' : 'normal';
            
            sendNotificationToSystem(source, title, message, urgency);
            
            // 调用原始通知
            return new originalNotification(title, options);
        };
        
        // 复制原型方法
        Object.setPrototypeOf(window.Notification, originalNotification);
        Object.defineProperty(window.Notification, 'prototype', {
            value: originalNotification.prototype,
            writable: false
        });
    }
    
    // 监听特定网站的通知
    if (window.location.hostname.includes('claude.ai') || window.location.hostname.includes('anthropic')) {
        // Claude 特定监听
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1) {
                        // 查找确认按钮或重要消息
                        const confirmButtons = node.querySelectorAll('[data-testid*="confirm"], button:contains("确认"), button:contains("Confirm")');
                        const warningMessages = node.querySelectorAll('.warning, .alert, .error, [class*="warning"], [class*="alert"]');
                        
                        if (confirmButtons.length > 0) {
                            sendNotificationToSystem('claude.ai', '需要确认', '有操作需要您的确认', 'urgent');
                        }
                        
                        if (warningMessages.length > 0) {
                            const message = warningMessages[0].textContent.substring(0, 100);
                            sendNotificationToSystem('claude.ai', '警告信息', message, 'normal');
                        }
                    }
                });
            });
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
})();
EOF

    echo "✅ 浏览器通知脚本已创建: $script_file"
}

# 启动简单的HTTP服务器接收通知
start_notification_server() {
    local port=8765
    
    echo "🚀 启动通知服务器 (端口: $port)..."
    
    # 使用 Python 启动简单HTTP服务器
    python3 << EOF &
import http.server
import socketserver
import subprocess
import os
from urllib.parse import urlparse, parse_qs

class NotificationHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/notification':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            
            # 解析通知数据
            parts = post_data.split('|')
            if len(parts) >= 3:
                source, title, message = parts[:3]
                urgency = parts[3] if len(parts) > 3 else 'normal'
                
                # 调用通知脚本
                script_path = "$SCRIPT_DIR/browser-notification-bridge.sh"
                subprocess.run([
                    'bash', script_path, 'handle',
                    source, title, message, urgency
                ])
            
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

with socketserver.TCPServer(("", $port), NotificationHandler) as httpd:
    print(f"Notification server running on port {port}")
    httpd.serve_forever()
EOF

    echo "✅ 通知服务器已启动"
}

# 显示使用说明
show_usage() {
    cat << 'EOF'
浏览器通知桥接工具

用法:
    browser-notification-bridge.sh [命令]

命令:
    monitor     - 启动通知监听器
    server      - 启动HTTP通知服务器
    handle      - 处理单个通知 (内部使用)
    script      - 创建浏览器用户脚本
    status      - 显示服务状态
    logs        - 查看通知日志

手动发送测试通知:
    echo 'claude.ai|测试标题|测试消息|normal' > /tmp/browser-notifications.pipe

浏览器集成:
    1. 安装 Tampermonkey 或 Greasemonkey 扩展
    2. 运行 'browser-notification-bridge.sh script' 创建用户脚本
    3. 将生成的脚本添加到扩展中

EOF
}

# 显示服务状态
show_status() {
    echo "🔍 浏览器通知桥接状态"
    echo "======================"
    
    # 检查服务器进程
    if pgrep -f "python3.*8765" > /dev/null; then
        echo "✅ HTTP通知服务器: 运行中 (端口: 8765)"
    else
        echo "❌ HTTP通知服务器: 未运行"
    fi
    
    # 检查管道
    if [[ -p "/tmp/browser-notifications.pipe" ]]; then
        echo "✅ 通知管道: 存在"
    else
        echo "❌ 通知管道: 不存在"
    fi
    
    # 检查日志文件
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(wc -l < "$LOG_FILE")
        echo "📊 通知日志: $log_size 条记录"
        
        if [[ $log_size -gt 0 ]]; then
            echo ""
            echo "📋 最近5条通知:"
            tail -5 "$LOG_FILE"
        fi
    else
        echo "📝 通知日志: 无记录"
    fi
}

# 查看日志
show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo "📋 浏览器通知日志:"
        echo "=================="
        tail -50 "$LOG_FILE"
    else
        echo "📝 还没有通知日志"
    fi
}

# 主函数
case "${1:-}" in
    "monitor")
        monitor_browser_notifications
        ;;
    "server")
        start_notification_server
        ;;
    "handle")
        handle_browser_notification "$2" "$3" "$4" "$5"
        ;;
    "script")
        create_browser_script
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "")
        show_usage
        ;;
    *)
        echo "未知命令: $1"
        show_usage
        exit 1
        ;;
esac
