#!/bin/bash

# ==============================================================================
# Hyprland Startup Environment Script
# ==============================================================================
# This script is executed by Hyprland on startup to dynamically set environment
# variables based on the user's local configuration in .env.local.
# It specifically handles dynamic proxy configuration.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory of the current script to reliably source other scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the environment loader to get config values
if [[ -f "$SCRIPT_DIR/load-env.sh" ]]; then
    # shellcheck source=./load-env.sh
    source "$SCRIPT_DIR/load-env.sh"
    # Initialize the environment, which loads .env.local
    init_dotfiles_env
else
    # If the loader script is not found, we can't proceed.
    # Log to stderr, which might be visible in Hyprland's logs.
    echo "FATAL: load-env.sh not found in $SCRIPT_DIR. Cannot set dynamic environment." >&2
    exit 1
fi

# --- Dynamic Proxy Configuration ---
# The 'load-env.sh' script, which was sourced above, already exports the necessary
# proxy variables (http_proxy, https_proxy, no_proxy) if ENABLE_PROXY is true
# in .env.local. We just need to pass them to the Hyprland session.

# Check if the http_proxy variable was set and exported by load-env.sh
if [[ -n "$http_proxy" ]]; then
    echo "Hyprland Startup: Proxy is ENABLED. Propagating environment variables to Hyprland session..."

    # Use hyprctl to set environment variables for the running Hyprland session.
    # We set both lowercase and uppercase versions for maximum compatibility.
    # The variables ($http_proxy, $https_proxy, $no_proxy) are already populated
    # by the sourced load-env.sh script.
    # 更新systemd用户环境
    systemctl --user set-environment http_proxy="$http_proxy"
    systemctl --user set-environment https_proxy="$https_proxy"
    systemctl --user set-environment HTTP_PROXY="$http_proxy"
    systemctl --user set-environment HTTPS_PROXY="$https_proxy"
    systemctl --user set-environment no_proxy="$no_proxy"
    systemctl --user set-environment NO_PROXY="$no_proxy"
    
    # 更新D-Bus激活环境（GUI应用的关键）
    dbus-update-activation-environment --systemd \
        http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
    
    # 尝试设置Hyprland环境（可能不支持所有命令）
    hyprctl setenv http_proxy "$http_proxy" 2>/dev/null || true
    hyprctl setenv https_proxy "$https_proxy" 2>/dev/null || true
    hyprctl setenv HTTP_PROXY "$http_proxy" 2>/dev/null || true
    hyprctl setenv HTTPS_PROXY "$https_proxy" 2>/dev/null || true
    hyprctl setenv no_proxy "$no_proxy" 2>/dev/null || true
    hyprctl setenv NO_PROXY "$no_proxy" 2>/dev/null || true
    
    echo "Hyprland Startup: Proxy environment variables have been set for systemd and D-Bus."
else
    echo "Hyprland Startup: Proxy is DISABLED or not configured. Skipping environment variable setup."
fi

# --- Add other dynamic environment variable setups below if needed ---
