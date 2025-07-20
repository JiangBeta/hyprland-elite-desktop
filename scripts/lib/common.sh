#!/bin/bash

# ===========================================
# 通用工具库
# ===========================================
# 提供通用的功能函数，避免代码重复

# 获取脚本目录
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# 获取dotfiles根目录
get_dotfiles_dir() {
    local script_dir=$(get_script_dir)
    echo "$(cd "$script_dir/.." && pwd)"
}

# 配置缓存机制
CACHE_DIR="/tmp/dotfiles_cache"
CONFIG_CACHE="$CACHE_DIR/config_cache"
CONFIG_HASH="$CACHE_DIR/config_hash"

# 初始化缓存目录
init_cache() {
    mkdir -p "$CACHE_DIR"
    chmod 700 "$CACHE_DIR"
}

# 配置缓存加载
load_config_cached() {
    local env_file="$1"
    
    if [[ ! -f "$env_file" ]]; then
        return 1
    fi
    
    init_cache
    
    # 计算配置文件哈希
    local current_hash
    if command -v md5sum >/dev/null 2>&1; then
        current_hash=$(md5sum "$env_file" | cut -d' ' -f1)
    else
        # macOS fallback
        current_hash=$(md5 -q "$env_file" 2>/dev/null || echo "fallback")
    fi
    
    local cached_hash=""
    [[ -f "$CONFIG_HASH" ]] && cached_hash=$(cat "$CONFIG_HASH" 2>/dev/null)
    
    # 检查缓存是否有效
    if [[ "$current_hash" != "$cached_hash" || ! -f "$CONFIG_CACHE" ]]; then
        # 重新生成缓存
        {
            # 安全验证
            if grep -E "(^|[^#].*)(rm |sudo |curl.*\||eval |exec |bash |sh |\$\(|\`)" "$env_file" >/dev/null 2>&1; then
                echo "# 配置文件包含不安全的命令" >&2
                return 1
            fi
            
            # 加载并导出变量
            set -a  # 自动导出变量
            source "$env_file"
            set +a
            
            # 保存环境变量到缓存
            declare -p | grep -E '^declare -x' | grep -v '^declare -x [A-Z_]*PATH'
        } > "$CONFIG_CACHE" 2>/dev/null || {
            echo "# 配置缓存生成失败" >&2
            return 1
        }
        
        echo "$current_hash" > "$CONFIG_HASH"
    else
        # 使用缓存
        source "$CONFIG_CACHE" 2>/dev/null || {
            # 缓存损坏，删除并重试
            rm -f "$CONFIG_CACHE" "$CONFIG_HASH"
            load_config_cached "$env_file"
            return $?
        }
    fi
    
    return 0
}

# 清理过期缓存
cleanup_cache() {
    # 清理超过1小时的缓存文件
    find "$CACHE_DIR" -type f -mmin +60 -delete 2>/dev/null || true
}

# 统一日志函数
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# 获取当前日志级别
get_log_level() {
    local level="${LOG_LEVEL:-INFO}"
    echo "${LOG_LEVELS[$level]:-1}"
}

# 通用日志函数
log_message() {
    local level="$1"
    shift
    local message="$*"
    
    local current_level=$(get_log_level)
    local msg_level="${LOG_LEVELS[$level]:-1}"
    
    # 只输出等于或高于当前级别的日志
    if [[ $msg_level -ge $current_level ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local script_name=$(basename "${BASH_SOURCE[2]}" .sh)
        
        case "$level" in
            DEBUG) echo -e "\033[0;37m[$timestamp] [$script_name] [DEBUG]\033[0m $message" >&2 ;;
            INFO)  echo -e "\033[0;34m[$timestamp] [$script_name] [INFO]\033[0m $message" ;;
            WARN)  echo -e "\033[1;33m[$timestamp] [$script_name] [WARN]\033[0m $message" >&2 ;;
            ERROR) echo -e "\033[0;31m[$timestamp] [$script_name] [ERROR]\033[0m $message" >&2 ;;
            FATAL) echo -e "\033[1;31m[$timestamp] [$script_name] [FATAL]\033[0m $message" >&2 ;;
        esac
        
        # 记录到日志文件
        local log_file="${LOG_DIR:-$HOME/.local/var/log/dotfiles}/dotfiles.log"
        if [[ -n "$LOG_DIR" ]]; then
            mkdir -p "$(dirname "$log_file")" 2>/dev/null
            echo "[$timestamp] [$script_name] [$level] $message" >> "$log_file" 2>/dev/null || true
        fi
    fi
}

# 便捷日志函数
log_debug() { log_message "DEBUG" "$@"; }
log_info() { log_message "INFO" "$@"; }
log_warn() { log_message "WARN" "$@"; }
log_error() { log_message "ERROR" "$@"; }
log_fatal() { log_message "FATAL" "$@"; exit 1; }

# 锁机制通用函数
acquire_lock() {
    local lock_name="$1"
    local lock_timeout="${2:-10}"
    local lock_dir="${3:-$HOME/.local/run}"
    
    local lock_file="$lock_dir/$lock_name.lock"
    local count=0
    
    mkdir -p "$lock_dir"
    
    while [[ $count -lt $lock_timeout ]]; do
        if mkdir "$lock_file" 2>/dev/null; then
            echo $$ > "$lock_file/pid"
            echo "$lock_file"  # 返回锁文件路径
            return 0
        fi
        
        # 检查锁是否过期
        if [[ -f "$lock_file/pid" ]]; then
            local lock_pid=$(cat "$lock_file/pid" 2>/dev/null)
            if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
                log_info "清理僵尸锁: $lock_file"
                rm -rf "$lock_file"
                continue
            fi
        fi
        
        sleep 1
        ((count++))
    done
    
    return 1
}

# 释放锁
release_lock() {
    local lock_file="$1"
    [[ -d "$lock_file" ]] && rm -rf "$lock_file"
}

# 进程管理
declare -a MANAGED_PROCESSES=()

# 启动管理的后台进程
start_managed_process() {
    local command="$1"
    local description="${2:-Background process}"
    
    eval "$command" &
    local pid=$!
    MANAGED_PROCESSES+=("$pid")
    
    log_debug "启动进程: $description (PID: $pid)"
    echo "$pid"
}

# 清理管理的进程
cleanup_managed_processes() {
    local signal="${1:-TERM}"
    
    if [[ ${#MANAGED_PROCESSES[@]} -gt 0 ]]; then
        log_info "清理 ${#MANAGED_PROCESSES[@]} 个管理进程"
        
        for pid in "${MANAGED_PROCESSES[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "-$signal" "$pid" 2>/dev/null || true
                log_debug "发送 $signal 信号到进程 $pid"
            fi
        done
        
        # 等待进程退出
        if [[ "$signal" == "TERM" ]]; then
            sleep 2
            # 强制杀死仍在运行的进程
            for pid in "${MANAGED_PROCESSES[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    kill -KILL "$pid" 2>/dev/null || true
                    log_debug "强制终止进程 $pid"
                fi
            done
        fi
        
        MANAGED_PROCESSES=()
    fi
}

# 网络请求管理
make_http_request() {
    local url="$1"
    local timeout="${2:-8}"
    local retries="${3:-2}"
    local cache_key="$4"
    local cache_duration="${5:-300}"  # 5分钟缓存
    
    # 缓存检查
    if [[ -n "$cache_key" ]]; then
        local cache_file="$CACHE_DIR/http_${cache_key}"
        if [[ -f "$cache_file" ]]; then
            local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
            if [[ $cache_age -lt $cache_duration ]]; then
                cat "$cache_file"
                return 0
            fi
        fi
    fi
    
    local attempt=0
    while [[ $attempt -le $retries ]]; do
        local result
        if result=$(curl -sSf --max-time "$timeout" --connect-timeout 5 "$url" 2>/dev/null); then
            # 缓存结果
            if [[ -n "$cache_key" ]]; then
                init_cache
                echo "$result" > "$cache_file"
            fi
            echo "$result"
            return 0
        fi
        
        ((attempt++))
        [[ $attempt -le $retries ]] && sleep 1
    done
    
    log_warn "HTTP请求失败: $url (尝试 $((retries + 1)) 次)"
    return 1
}

# 配置值获取（带类型验证）
get_config_value() {
    local key="$1"
    local default="$2"
    local type="${3:-string}"  # string, int, bool, url, path
    local value="${!key:-$default}"
    
    # 类型验证
    case "$type" in
        int)
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                log_warn "配置 $key 不是有效整数: $value，使用默认值: $default"
                value="$default"
            fi
            ;;
        bool)
            if ! [[ "$value" =~ ^(true|false)$ ]]; then
                log_warn "配置 $key 不是有效布尔值: $value，使用默认值: $default"
                value="$default"
            fi
            ;;
        url)
            if ! [[ "$value" =~ ^https?:// ]]; then
                log_warn "配置 $key 不是有效URL: $value，使用默认值: $default"
                value="$default"
            fi
            ;;
        path)
            if [[ -n "$value" && ! -e "$value" ]]; then
                log_warn "配置 $key 路径不存在: $value，使用默认值: $default"
                value="$default"
            fi
            ;;
    esac
    
    echo "$value"
}

# 性能监控
declare -A PERF_TIMERS=()

# 开始性能计时
perf_start() {
    local name="$1"
    PERF_TIMERS["$name"]=$(date +%s%N)
}

# 结束性能计时
perf_end() {
    local name="$1"
    local start_time="${PERF_TIMERS[$name]}"
    
    if [[ -n "$start_time" ]]; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # 毫秒
        
        log_debug "性能计时 [$name]: ${duration}ms"
        unset PERF_TIMERS["$name"]
        
        # 如果超过阈值，记录警告
        if [[ $duration -gt 1000 ]]; then
            log_warn "性能警告: $name 执行时间过长 (${duration}ms)"
        fi
        
        echo "$duration"
    else
        log_error "性能计时器 $name 未启动"
        return 1
    fi
}

# 系统信息获取
get_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        platform)
            uname -s
            ;;
        distro)
            if [[ -f /etc/os-release ]]; then
                grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"'
            else
                echo "unknown"
            fi
            ;;
        desktop)
            echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
            ;;
        memory_mb)
            local mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
            echo $((mem_kb / 1024))
            ;;
        cpu_cores)
            nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1
            ;;
    esac
}

# 优雅退出处理
setup_exit_handler() {
    local cleanup_function="$1"
    
    # 设置多个信号的处理器
    trap "$cleanup_function" EXIT INT TERM HUP
}

# 默认清理函数
default_cleanup() {
    cleanup_managed_processes
    cleanup_cache
    
    # 清理临时文件
    local temp_files=(/tmp/dotfiles_*.tmp)
    for file in "${temp_files[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "通用工具库已加载"
    echo "可用函数: load_config_cached, log_*, acquire_lock, make_http_request 等"
fi