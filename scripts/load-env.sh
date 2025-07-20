#!/bin/bash

# ===========================================
# 环境配置加载函数
# ===========================================
# 用于统一加载 .env.local 配置
# 可以被其他脚本 source 使用

# 获取 dotfiles 根目录
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 默认配置文件路径
ENV_LOCAL_FILE="$DOTFILES_DIR/.env.local"
ENV_EXAMPLE_FILE="$DOTFILES_DIR/.env.example"

# 日志函数
log_info() {
    [[ "${LOG_LEVEL:-INFO}" != "DEBUG" ]] || echo "[INFO] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# 加载通用库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    echo "错误: 找不到通用库文件" >&2
    exit 1
fi

# 加载环境配置（使用缓存优化）
load_env_config() {
    # 如果 .env.local 不存在，提示用户创建
    if [[ ! -f "$ENV_LOCAL_FILE" ]]; then
        log_warn ".env.local 配置文件不存在"
        
        if [[ -f "$ENV_EXAMPLE_FILE" ]]; then
            log_info "请复制 .env.example 到 .env.local 并修改配置："
            log_info "  cp $ENV_EXAMPLE_FILE $ENV_LOCAL_FILE"
        else
            log_error "找不到 .env.example 模板文件"
            return 1
        fi
        
        # 使用默认配置继续运行
        return 0
    fi
    
    log_debug "开始加载配置文件: $ENV_LOCAL_FILE"
    perf_start "config_loading"
    
    # 使用缓存机制加载配置
    if load_config_cached "$ENV_LOCAL_FILE"; then
        # 导出重要的环境变量
        export DOTFILES_DIR
        export LOG_LEVEL="${LOG_LEVEL:-INFO}"
        export DEBUG_MODE="${DEBUG_MODE:-false}"
        
        local load_time=$(perf_end "config_loading")
        log_debug "配置加载完成 (${load_time}ms)"
        return 0
    else
        log_error "配置加载失败"
        return 1
    fi
}

# 获取配置值（带默认值和类型验证）
get_config() {
    local key="$1"
    local default="$2"
    local type="${3:-string}"
    
    get_config_value "$key" "$default" "$type"
}

# 检查必需的依赖
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "缺少以下依赖: ${missing[*]}"
        log_info "请安装缺少的依赖后重试"
        return 1
    fi
    
    return 0
}

# 创建必要的目录
ensure_directories() {
    local dirs=(
        "$(get_config LOG_DIR "$HOME/.local/var/log/dotfiles")"
        "$(get_config BACKUP_DIR "$HOME/.local/share/dotfiles/backups")" 
        "$HOME/.config/totp"
        "$HOME/.local/run"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -n "$dir" && ! -d "$dir" ]]; then
            log_info "创建目录: $dir"
            mkdir -p "$dir" || {
                log_error "无法创建目录: $dir"
                return 1
            }
        fi
    done
    
    return 0
}

# 设置日志轮转
setup_log_rotation() {
    local log_file="$1"
    local max_size="${2:-10M}"
    local max_files="${3:-5}"
    
    if [[ -f "$log_file" ]]; then
        local file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
        local max_bytes
        
        case "$max_size" in
            *K|*k) max_bytes=$((${max_size%[Kk]} * 1024)) ;;
            *M|*m) max_bytes=$((${max_size%[Mm]} * 1024 * 1024)) ;;
            *G|*g) max_bytes=$((${max_size%[Gg]} * 1024 * 1024 * 1024)) ;;
            *) max_bytes="$max_size" ;;
        esac
        
        if [[ $file_size -gt $max_bytes ]]; then
            log_info "轮转日志文件: $log_file"
            
            # 删除最老的日志
            [[ -f "${log_file}.${max_files}" ]] && rm -f "${log_file}.${max_files}"
            
            # 轮转现有日志
            for ((i=max_files-1; i>=1; i--)); do
                [[ -f "${log_file}.${i}" ]] && mv "${log_file}.${i}" "${log_file}.$((i+1))"
            done
            
            # 轮转当前日志
            mv "$log_file" "${log_file}.1"
            touch "$log_file"
        fi
    fi
}

# 初始化函数（其他脚本可以调用）
init_dotfiles_env() {
    load_env_config || return 1
    ensure_directories || return 1
    
    # 设置调试模式
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        set -x
        export PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}: '
    fi
    
    return 0
}

# 如果直接运行此脚本，执行初始化
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_dotfiles_env
    echo "环境配置初始化完成"
    echo "DOTFILES_DIR: $DOTFILES_DIR"
    echo "LOG_LEVEL: $(get_config LOG_LEVEL "INFO")"
    echo "DEBUG_MODE: $(get_config DEBUG_MODE "false")"
fi