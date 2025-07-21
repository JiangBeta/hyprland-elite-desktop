#!/bin/bash

# Obsidian Quick Capture Script
# 快速捕获想法到 Obsidian Inbox
# 
# 使用方法:
#   obsidian-quick-capture.sh "你的想法"
#   obsidian-quick-capture.sh --task "待办任务" 
#   obsidian-quick-capture.sh --link "https://example.com"
#   obsidian-quick-capture.sh --interactive  # 交互式输入

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$DOTFILES_DIR/.env.local" ]; then
    source "$DOTFILES_DIR/.env.local"
elif [ -f "$DOTFILES_DIR/.env" ]; then
    source "$DOTFILES_DIR/.env"
else
    echo "❌ 配置文件未找到，请创建 .env.local"
    exit 1
fi

# 检查必需的配置变量
if [ -z "$OBSIDIAN_VAULT_PATH" ] || [ -z "$OBSIDIAN_INBOX_FILE" ]; then
    echo "❌ Obsidian 配置不完整，请检查 .env.local"
    exit 1
fi

INBOX_PATH="$OBSIDIAN_VAULT_PATH/$OBSIDIAN_INBOX_FILE"
TIMESTAMP=$(date "$QUICK_CAPTURE_TIMESTAMP_FORMAT")

# 检查 Inbox 文件是否存在
if [ ! -f "$INBOX_PATH" ]; then
    echo "❌ Inbox 文件不存在: $INBOX_PATH"
    exit 1
fi

# 显示帮助信息
show_help() {
    cat << EOF
📥 Obsidian Quick Capture

用法:
  $0 "你的想法"                    # 添加到想法区域
  $0 --task "待办任务"             # 添加到任务区域
  $0 --link "https://example.com"  # 添加到链接区域
  $0 --contact "联系人信息"        # 添加到联系人区域
  $0 --learn "学习内容"            # 添加到学习区域
  $0 --interactive               # 交互式输入
  $0 --help                     # 显示帮助

快捷方式:
  $0 -t "任务"     # 等同于 --task
  $0 -l "链接"     # 等同于 --link
  $0 -c "联系人"   # 等同于 --contact
  $0 -s "学习"     # 等同于 --learn
  $0 -i           # 等同于 --interactive
EOF
}

# 交互式输入
interactive_mode() {
    echo "📥 Obsidian Quick Capture - 交互模式"
    echo ""
    echo "选择类型:"
    echo "  1) 💡 想法/思考"
    echo "  2) 🚀 任务"
    echo "  3) 🔗 链接"
    echo "  4) 📚 学习内容"
    echo "  5) 📞 联系人"
    echo ""
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1) read -p "💡 输入你的想法: " content && add_idea "$content" ;;
        2) read -p "🚀 输入任务: " content && add_task "$content" ;;
        3) read -p "🔗 输入链接: " content && add_link "$content" ;;
        4) read -p "📚 输入学习内容: " content && add_learning "$content" ;;
        5) read -p "📞 输入联系人信息: " content && add_contact "$content" ;;
        *) echo "❌ 无效选择"; exit 1 ;;
    esac
}

# 添加任务
add_task() {
    local content="$1"
    local line="- [ ] $content #inbox 📅 $TIMESTAMP"
    
    # 在 "## 🚀 Quick Tasks" 行后插入
    sed -i "/^## 🚀 Quick Tasks/a\\$line" "$INBOX_PATH"
    echo "✅ 已添加任务: $content"
    notify_success "任务已添加到 Inbox"
}

# 添加想法
add_idea() {
    local content="$1"
    local line="- **$TIMESTAMP**: $content"
    
    # 在 "## 💡 Ideas & Thoughts" 行后插入
    sed -i "/^## 💡 Ideas & Thoughts/a\\$line" "$INBOX_PATH"
    echo "💡 已添加想法: $content"
    notify_success "想法已添加到 Inbox"
}

# 添加链接
add_link() {
    local content="$1"
    local line="- [$TIMESTAMP] $content"
    
    # 在 "## 🔗 Links to Process" 行后插入
    sed -i "/^## 🔗 Links to Process/a\\$line" "$INBOX_PATH"
    echo "🔗 已添加链接: $content"
    notify_success "链接已添加到 Inbox"
}

# 添加学习内容
add_learning() {
    local content="$1"
    local line="- **$TIMESTAMP**: $content"
    
    # 在 "## 📚 To Learn Later" 行后插入
    sed -i "/^## 📚 To Learn Later/a\\$line" "$INBOX_PATH"
    echo "📚 已添加学习内容: $content"
    notify_success "学习内容已添加到 Inbox"
}

# 添加联系人
add_contact() {
    local content="$1"
    local line="- **$TIMESTAMP**: $content"
    
    # 在 "## 📞 People to Contact" 行后插入
    sed -i "/^## 📞 People to Contact/a\\$line" "$INBOX_PATH"
    echo "📞 已添加联系人: $content"
    notify_success "联系人已添加到 Inbox"
}

# 发送通知
notify_success() {
    local message="$1"
    # 如果有 notify-send，发送桌面通知
    if command -v notify-send &> /dev/null; then
        notify-send "📥 Obsidian" "$message" --icon=obsidian
    fi
    
    # 如果配置了 ntfy，发送推送通知
    if [ -n "$NTFY_TOPIC" ] && [ -n "$NTFY_SERVER" ]; then
        curl -s "$NTFY_SERVER/$NTFY_TOPIC" \
            -d "$message" \
            -H "Title: 📥 Obsidian Quick Capture" \
            -H "Priority: low" \
            -H "Tags: inbox" &
    fi
}

# 尝试打开 Obsidian (如果未运行)
open_obsidian() {
    if ! pgrep -x "$OBSIDIAN_EXECUTABLE" > /dev/null; then
        if command -v "$OBSIDIAN_EXECUTABLE" &> /dev/null; then
            echo "🚀 正在启动 Obsidian..."
            "$OBSIDIAN_EXECUTABLE" "obsidian://open?vault=$OBSIDIAN_VAULT_NAME&file=$OBSIDIAN_INBOX_FILE" &
        fi
    fi
}

# 主逻辑
main() {
    case "$1" in
        --help|-h)
            show_help
            ;;
        --interactive|-i)
            interactive_mode
            ;;
        --task|-t)
            shift
            add_task "$*"
            ;;
        --link|-l)
            shift
            add_link "$*"
            ;;
        --contact|-c)
            shift
            add_contact "$*"
            ;;
        --learn|-s)
            shift
            add_learning "$*"
            ;;
        "")
            interactive_mode
            ;;
        *)
            # 智能判断内容类型
            content="$*"
            if [[ "$content" =~ ^https?:// ]]; then
                add_link "$content"
            elif [[ "$content" =~ ^\s*-?\s*\[.\]\s* ]] || [[ "$content" =~ [Tt][Oo][Dd][Oo] ]]; then
                add_task "$content"
            else
                add_idea "$content"
            fi
            ;;
    esac
    
    # 可选：自动打开 Obsidian
    # open_obsidian
}

# 执行主函数
main "$@"