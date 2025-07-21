#!/bin/bash

# Obsidian 相关 Shell 别名

# 获取脚本目录
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Obsidian 快速捕获别名
alias oq="$DOTFILES_DIR/scripts/obsidian-quick-capture.sh"           # 快速捕获
alias oqi="$DOTFILES_DIR/scripts/obsidian-quick-capture.sh -i"       # 交互模式
alias oqt="$DOTFILES_DIR/scripts/obsidian-quick-capture.sh -t"       # 添加任务
alias oql="$DOTFILES_DIR/scripts/obsidian-quick-capture.sh -l"       # 添加链接
alias oqs="$DOTFILES_DIR/scripts/obsidian-quick-capture.sh -s"       # 添加学习内容

# Obsidian 文件操作
alias ovault='cd "${OBSIDIAN_VAULT_PATH:-$HOME/Documents/vaults/second-brain}"'  # 进入 vault 目录
alias oinbox='${EDITOR:-nano} "${OBSIDIAN_VAULT_PATH:-$HOME/Documents/vaults/second-brain}/Inbox.md"'  # 编辑 Inbox

# 快速打开常用文件
alias otoday="$DOTFILES_DIR/scripts/obsidian-daily-note.sh"          # 创建/打开今日笔记
alias odashboard="$DOTFILES_DIR/scripts/obsidian-open-dashboard.sh"  # 打开仪表板 (待创建)
alias otask="$DOTFILES_DIR/scripts/obsidian-quick-task.sh"           # 快速添加任务

# 显示 Obsidian 别名帮助
alias ohelp='cat << EOF
📥 Obsidian 快捷命令:

快速捕获:
  oq "想法"     - 快速捕获想法
  oqi          - 交互式捕获
  oqt "任务"    - 添加任务
  oql "链接"    - 添加链接  
  oqs "学习"    - 添加学习内容
  otask        - 快速添加任务 (GUI)

文件操作:
  ovault       - 进入 vault 目录
  oinbox       - 编辑 Inbox 文件
  otoday       - 打开今日笔记 (待创建)
  odashboard   - 打开仪表板 (待创建)

查看帮助:
  ohelp        - 显示此帮助
EOF'