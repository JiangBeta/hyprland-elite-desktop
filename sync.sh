#!/bin/bash

# Dotfiles 同步脚本
# 用于同步配置文件更改到 dotfiles 目录

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "开始同步 dotfiles..."

# 备份清理函数
cleanup_claude_backups() {
    local backup_pattern="$DOTFILES_DIR/CLAUDE.md.backup.*"
    local max_backups=3
    
    echo "清理 CLAUDE.md 备份文件..."
    
    # 获取所有备份文件，按时间排序
    local backup_files=($(ls -t $backup_pattern 2>/dev/null))
    local backup_count=${#backup_files[@]}
    
    if [[ $backup_count -gt $max_backups ]]; then
        echo "发现 $backup_count 个 CLAUDE.md 备份，保留最新的 $max_backups 个..."
        
        # 删除多余的备份
        for ((i=$max_backups; i<$backup_count; i++)); do
            local old_backup="${backup_files[$i]}"
            if [[ -f "$old_backup" ]]; then
                echo "删除旧备份: $(basename "$old_backup")"
                rm -f "$old_backup"
            fi
        done
        
        echo "✅ CLAUDE.md 备份清理完成"
    fi
}

# Git仓库备份清理函数
cleanup_git_history() {
    local claude_dir="$1"
    
    if [[ -d "$claude_dir/.git" ]]; then
        cd "$claude_dir"
        
        # 获取提交数量
        local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        local max_commits=20
        
        if [[ $commit_count -gt $max_commits ]]; then
            echo "Claude 配置 Git 仓库有 $commit_count 个提交，清理历史..."
            
            # 保留最近的提交，重写历史
            local keep_commits=$((max_commits - 5))
            local cutoff_commit=$(git rev-list HEAD | sed -n "${keep_commits}p")
            
            if [[ -n "$cutoff_commit" ]]; then
                # 创建孤儿分支并重置历史
                git checkout --orphan temp_branch "$cutoff_commit"
                git commit -m "重置历史: 保留最近 $keep_commits 次提交"
                git branch -D master 2>/dev/null || true
                git branch -m master
                git gc --aggressive --prune=all
                
                echo "✅ Git 历史清理完成，保留了最近 $keep_commits 次提交"
            fi
        fi
    fi
}

# 配置文件映射
declare -A CONFIG_FILES=(
    ["$HOME/.config/hypr"]="$DOTFILES_DIR/config/hypr"
    ["$HOME/.config/waybar"]="$DOTFILES_DIR/config/waybar"
    ["$HOME/.config/fcitx5"]="$DOTFILES_DIR/config/fcitx5"
    ["$HOME/.config/kitty"]="$DOTFILES_DIR/config/kitty"
    ["$HOME/.config/swww"]="$DOTFILES_DIR/config/swww"
    ["$HOME/.config/mako"]="$DOTFILES_DIR/config/mako"
    ["$HOME/.config/satty"]="$DOTFILES_DIR/config/satty"
    ["$HOME/.config/swappy"]="$DOTFILES_DIR/config/swappy"
    ["$HOME/.config/wofi"]="$DOTFILES_DIR/config/wofi"
    ["$HOME/.config/Code"]="$DOTFILES_DIR/config/Code"
    ["$HOME/.config/totp"]="$DOTFILES_DIR/config/totp"
    ["$HOME/.config/gtk-3.0"]="$DOTFILES_DIR/config/gtk-3.0"
    ["$HOME/.config/gtk-4.0"]="$DOTFILES_DIR/config/gtk-4.0"
    ["$HOME/.config/qt5ct"]="$DOTFILES_DIR/config/qt5ct"
)

declare -A CLAUDE_FILES=(
    ["$HOME/.claude"]="$DOTFILES_DIR/claude"
)

declare -A SHELL_FILES=(
    ["$HOME/.bashrc"]="$DOTFILES_DIR/shell/bashrc"
    ["$HOME/.zshrc"]="$DOTFILES_DIR/shell/zshrc"
    ["$HOME/.screenrc"]="$DOTFILES_DIR/shell/screenrc"
)

# 同步配置文件
echo "同步配置文件..."
for src in "${!CONFIG_FILES[@]}"; do
    dst="${CONFIG_FILES[$src]}"
    
    if [[ -e "$src" ]]; then
        if [[ -L "$src" ]]; then
            echo "跳过软链接: $src"
            continue
        fi
        
        echo "同步: $src -> $dst"
        rsync -av --delete "$src/" "$dst/"
    else
        echo "警告: $src 不存在"
    fi
done

# 同步 shell 文件
echo "同步 shell 配置文件..."
for src in "${!SHELL_FILES[@]}"; do
    dst="${SHELL_FILES[$src]}"
    
    if [[ -e "$src" ]]; then
        if [[ -L "$src" ]]; then
            echo "跳过软链接: $src"
            continue
        fi
        
        echo "同步: $src -> $dst"
        cp "$src" "$dst"
    else
        echo "警告: $src 不存在"
    fi
done

# 同步 scripts 目录
echo "同步 scripts 目录..."
if [[ -d "$HOME/.local/bin" ]]; then
    mkdir -p "$DOTFILES_DIR/scripts"
    for script in "$HOME/.local/bin"/*; do
        if [[ -L "$script" ]]; then
            # 检查链接是否指向 dotfiles
            link_target=$(readlink -f "$script")
            if [[ "$link_target" == "$DOTFILES_DIR/scripts"/* ]]; then
                echo "跳过指向 dotfiles 的软链接: $script"
            fi
        elif [[ -f "$script" ]]; then
            basename_file=$(basename "$script")
            dst="$DOTFILES_DIR/scripts/$basename_file"
            echo "同步脚本: $script -> $dst"
            cp "$script" "$dst"
            chmod +x "$dst"
        fi
    done
fi

# 同步 desktop 应用程序文件
echo "同步 desktop 应用程序文件..."
mkdir -p "$DOTFILES_DIR/config/applications"

# 同步现有的自定义desktop文件
if [[ -d "$HOME/.local/share/applications" ]]; then
    for desktop_file in "$HOME/.local/share/applications"/*.desktop; do
        if [[ -f "$desktop_file" && ! -L "$desktop_file" ]]; then
            basename_file=$(basename "$desktop_file")
            dst="$DOTFILES_DIR/config/applications/$basename_file"
            
            # 检查是否是自定义的desktop文件（不在系统目录中）
            if [[ ! -f "/usr/share/applications/$basename_file" ]]; then
                echo "同步自定义desktop文件: $desktop_file -> $dst"
                cp "$desktop_file" "$dst"
            else
                # 检查是否被修改过
                if ! diff -q "$desktop_file" "/usr/share/applications/$basename_file" > /dev/null 2>&1; then
                    echo "同步修改过的desktop文件: $desktop_file -> $dst"
                    cp "$desktop_file" "$dst"
                fi
            fi
        fi
    done
fi

# 同步 Claude 配置文件（增强版，支持Git和自动合并）
echo "同步 Claude 配置文件..."

# Claude配置智能同步函数
sync_claude_config() {
    local src="$1"
    local dst="$2"
    
    if [[ ! -e "$src" ]]; then
        echo "警告: $src 不存在"
        return
    fi
    
    if [[ -L "$src" ]]; then
        echo "跳过软链接: $src"
        return
    fi
    
    echo "智能同步 Claude 配置: $src -> $dst"
    
    # 确保目标目录存在
    mkdir -p "$dst"
    
    # 初始化 git 仓库（如果不存在）
    if [[ ! -d "$dst/.git" ]]; then
        echo "初始化 Claude 配置 Git 仓库..."
        (cd "$dst" && git init && git config user.name "dotfiles-sync" && git config user.email "sync@local")
    fi
    
    # 同步文件但排除敏感信息
    echo "同步配置文件（排除敏感信息）..."
    rsync -av --delete \
        --exclude='.credentials.json' \
        --exclude='projects/' \
        --exclude='shell-snapshots/' \
        --exclude='statsig/' \
        --exclude='.git' \
        "$src/" "$dst/"
    
    # Git 操作
    cd "$dst"
    
    # 检查是否有变更
    if git diff --quiet && git diff --cached --quiet; then
        echo "Claude 配置无变更"
        return
    fi
    
    # 提交变更
    echo "检测到 Claude 配置变更，准备提交..."
    git add .
    
    # 生成提交信息
    local commit_msg="sync: Claude 配置更新 $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 检查冲突文件
    local conflict_files=()
    while IFS= read -r -d '' file; do
        if [[ -f "$file" && $(git status --porcelain "$file" | cut -c1-2) == "UU" ]]; then
            conflict_files+=("$file")
        fi
    done < <(find . -name "*.json" -o -name "*.md" -print0)
    
    if [[ ${#conflict_files[@]} -gt 0 ]]; then
        echo "发现冲突文件，尝试自动解决："
        for file in "${conflict_files[@]}"; do
            echo "  解决冲突: $file"
            # 对于JSON文件，优先使用较新的版本
            if [[ "$file" == *.json ]]; then
                git checkout --theirs "$file"
                git add "$file"
            fi
        done
    fi
    
    git commit -m "$commit_msg" 2>/dev/null || echo "Claude 配置提交完成或无需提交"
    
    # 定期清理 Git 历史
    cleanup_git_history "$dst"
    
    echo "✅ Claude 配置同步完成"
}

# 执行 Claude 配置同步
for src in "${!CLAUDE_FILES[@]}"; do
    dst="${CLAUDE_FILES[$src]}"
    sync_claude_config "$src" "$dst"
done

# 特殊处理：同步 CLAUDE.md 到项目根目录
if [[ -f "$HOME/.claude/CLAUDE.md" && ! -L "$HOME/.claude/CLAUDE.md" ]]; then
    echo "同步全局 CLAUDE.md 到项目..."
    if [[ -f "$DOTFILES_DIR/CLAUDE.md" ]]; then
        # 比较文件差异
        if ! diff -q "$HOME/.claude/CLAUDE.md" "$DOTFILES_DIR/CLAUDE.md" > /dev/null 2>&1; then
            echo "检测到 CLAUDE.md 差异，创建备份并更新..."
            cp "$DOTFILES_DIR/CLAUDE.md" "$DOTFILES_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$HOME/.claude/CLAUDE.md" "$DOTFILES_DIR/CLAUDE.md"
            
            # 清理旧的CLAUDE.md备份文件
            cleanup_claude_backups
        fi
    else
        cp "$HOME/.claude/CLAUDE.md" "$DOTFILES_DIR/CLAUDE.md"
    fi
fi

# 检查 CLAUDE.md 文件
if [[ -f "$DOTFILES_DIR/CLAUDE.md" ]]; then
    echo "✅ CLAUDE.md 文件已存在于 dotfiles 目录"
else
    echo "⚠️  未找到 CLAUDE.md 文件，可以运行 'claude code /init' 来创建"
fi

echo "✅ 同步完成!"
echo "现在可以提交更改到 git 仓库"