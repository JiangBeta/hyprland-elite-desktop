#!/bin/bash

# 通用的单例启动器
# 用法: singleton-launcher.sh <程序名> <命令>

PROGRAM="$1"
shift
COMMAND="$@"

# 使用 flock 来确保单例运行
LOCK_FILE="/tmp/${PROGRAM}.lock"

exec 200>"$LOCK_FILE"

if ! flock -n 200; then
    # 已经在运行，尝试切换到已存在的窗口或退出
    echo "${PROGRAM} is already running"
    exit 0
fi

# 运行命令
exec $COMMAND