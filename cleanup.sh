#!/bin/bash

# Dotfiles 清理脚本
# 手动清理各种备份文件和临时数据

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "🧹 开始清理 dotfiles 备份和临时文件..."

# 清理install.sh产生的备份目录
cleanup_install_backups() {
    local backup_pattern="$HOME/dotfiles_backup_*"
    local keep_backups=2
    
    echo "检查 install.sh 备份目录..."
    
    local backup_dirs=($(ls -dt $backup_pattern 2>/dev/null))
    local backup_count=${#backup_dirs[@]}
    
    if [[ $backup_count -gt $keep_backups ]]; then
        echo "发现 $backup_count 个备份目录，保留最新的 $keep_backups 个..."
        
        for ((i=$keep_backups; i<$backup_count; i++)); do
            local old_backup="${backup_dirs[$i]}"
            if [[ -d "$old_backup" ]]; then
                echo "删除旧备份目录: $(basename "$old_backup")"
                rm -rf "$old_backup"
            fi
        done
        
        echo "✅ install.sh 备份清理完成"
    else
        echo "install.sh 备份数量正常 ($backup_count/$keep_backups)"
    fi
}

# 清理CLAUDE.md备份文件
cleanup_claude_md_backups() {
    local backup_pattern="$DOTFILES_DIR/CLAUDE.md.backup.*"
    local keep_backups=2
    
    echo "检查 CLAUDE.md 备份文件..."
    
    local backup_files=($(ls -t $backup_pattern 2>/dev/null))
    local backup_count=${#backup_files[@]}
    
    if [[ $backup_count -gt $keep_backups ]]; then
        echo "发现 $backup_count 个 CLAUDE.md 备份，保留最新的 $keep_backups 个..."
        
        for ((i=$keep_backups; i<$backup_count; i++)); do
            local old_backup="${backup_files[$i]}"
            if [[ -f "$old_backup" ]]; then
                echo "删除旧备份: $(basename "$old_backup")"
                rm -f "$old_backup"
            fi
        done
        
        echo "✅ CLAUDE.md 备份清理完成"
    else
        echo "CLAUDE.md 备份数量正常 ($backup_count/$keep_backups)"
    fi
}

# 清理Claude配置Git历史
cleanup_claude_git() {
    local claude_dir="$DOTFILES_DIR/claude"
    
    if [[ -d "$claude_dir/.git" ]]; then
        echo "检查 Claude 配置 Git 仓库..."
        cd "$claude_dir"
        
        local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        local max_commits=15
        
        if [[ $commit_count -gt $max_commits ]]; then
            echo "Claude Git 仓库有 $commit_count 个提交，建议清理..."
            
            read -p "是否要清理 Git 历史？(y/N): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                local keep_commits=$((max_commits - 5))
                local cutoff_commit=$(git rev-list HEAD | sed -n "${keep_commits}p")
                
                if [[ -n "$cutoff_commit" ]]; then
                    git checkout --orphan temp_branch "$cutoff_commit"
                    git commit -m "清理历史: 保留最近 $keep_commits 次提交 $(date '+%Y-%m-%d')"
                    git branch -D master 2>/dev/null || true
                    git branch -m master
                    git gc --aggressive --prune=all
                    
                    echo "✅ Claude Git 历史清理完成"
                fi
            else
                echo "跳过 Git 历史清理"
            fi
        else
            echo "Claude Git 仓库提交数量正常 ($commit_count/$max_commits)"
        fi
    else
        echo "Claude 配置目录没有 Git 仓库"
    fi
}

# 清理临时文件
cleanup_temp_files() {
    echo "检查临时文件..."
    
    local temp_patterns=(
        "$DOTFILES_DIR/**/*.tmp"
        "$DOTFILES_DIR/**/*.bak"
        "$DOTFILES_DIR/**/*~"
        "$HOME/.config/**/*.backup"
    )
    
    local found_files=0
    
    for pattern in "${temp_patterns[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                echo "删除临时文件: $file"
                rm -f "$file"
                ((found_files++))
            fi
        done
    done
    
    if [[ $found_files -gt 0 ]]; then
        echo "✅ 清理了 $found_files 个临时文件"
    else
        echo "未发现临时文件"
    fi
}

# 显示磁盘空间使用情况
show_disk_usage() {
    echo "📊 磁盘空间使用情况:"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        echo "dotfiles 目录: $(du -sh "$DOTFILES_DIR" | cut -f1)"
    fi
    
    local backup_dirs=($(ls -d $HOME/dotfiles_backup_* 2>/dev/null))
    if [[ ${#backup_dirs[@]} -gt 0 ]]; then
        local total_backup_size=$(du -sh "${backup_dirs[@]}" 2>/dev/null | awk '{sum+=$1} END {print sum "M"}')
        echo "备份目录总大小: $total_backup_size"
    fi
    
    if [[ -d "$DOTFILES_DIR/claude" ]]; then
        echo "Claude 配置: $(du -sh "$DOTFILES_DIR/claude" | cut -f1)"
    fi
}

# 主清理流程
main() {
    echo "选择清理模式:"
    echo "1) 快速清理 (推荐)"
    echo "2) 深度清理 (包括 Git 历史)"
    echo "3) 仅显示使用情况"
    echo "4) 退出"
    
    read -p "请选择 (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            cleanup_install_backups
            cleanup_claude_md_backups
            cleanup_temp_files
            show_disk_usage
            ;;
        2)
            cleanup_install_backups
            cleanup_claude_md_backups
            cleanup_claude_git
            cleanup_temp_files
            show_disk_usage
            ;;
        3)
            show_disk_usage
            ;;
        4)
            echo "退出清理"
            exit 0
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac
    
    echo "🎉 清理完成!"
}

# 检查参数
if [[ "$1" == "--auto" ]]; then
    # 自动模式，执行快速清理
    cleanup_install_backups
    cleanup_claude_md_backups
    cleanup_temp_files
    echo "🎉 自动清理完成!"
else
    # 交互模式
    main
fi