# 网络代理配置指南

## 概述

本dotfiles配置支持为所有GUI应用设置全局网络代理，包括但不限于：
- Chrome/Firefox浏览器
- VSCode/IDEs
- 桌面应用程序
- Electron应用

## 配置步骤

### 1. 基础配置

编辑 `.env.local` 文件：

```bash
vim ~/dotfiles/.env.local
```

设置以下代理参数：

```bash
# 网络代理配置
ENABLE_PROXY=true              # 启用/禁用代理
PROXY_HOST=127.0.0.1          # 代理服务器地址
PROXY_PORT=7897               # 代理端口（常见：7890, 7897, 1080）
NO_PROXY=localhost,127.0.0.1  # 排除地址列表
```

### 2. 应用配置

运行以下命令应用代理设置：

```bash
# 生成代理环境变量配置
~/dotfiles/scripts/generate-proxy-env.sh

# 应用到当前会话
~/dotfiles/scripts/hyprland-startup-env.sh

# 重新加载Hyprland配置
hyprctl reload
```

### 3. 验证配置

```bash
# 检查终端代理
curl -I http://www.google.com

# 检查systemd环境变量
systemctl --user show-environment | grep -i proxy

# 重启应用测试GUI代理
pkill chrome && google-chrome-stable www.google.com
```

## 支持的代理类型

### HTTP/HTTPS代理
```bash
PROXY_HOST=127.0.0.1
PROXY_PORT=8080
```

### SOCKS代理（通过HTTP转换）
需要本地HTTP代理程序如privoxy转换SOCKS到HTTP。

### 常见代理客户端端口
- **Clash**: 7897 (HTTP), 7890 (SOCKS)
- **V2Ray**: 8080 (HTTP), 1080 (SOCKS)  
- **SSR**: 1087 (HTTP), 1080 (SOCKS)
- **Shadowsocks**: 1080 (SOCKS)

## 技术原理

### 环境变量设置层级
1. **shell环境** - zsh配置自动设置终端代理
2. **systemd用户环境** - 系统服务和应用继承
3. **D-Bus激活环境** - GUI应用启动时的关键环境
4. **Hyprland环境** - 窗口管理器层面的环境变量

### 代理变量说明
```bash
http_proxy=http://127.0.0.1:7897       # HTTP代理（小写）
https_proxy=http://127.0.0.1:7897      # HTTPS代理（小写）
HTTP_PROXY=http://127.0.0.1:7897       # HTTP代理（大写，某些应用需要）
HTTPS_PROXY=http://127.0.0.1:7897      # HTTPS代理（大写）
no_proxy=localhost,127.0.0.1           # 排除列表（小写）
NO_PROXY=localhost,127.0.0.1           # 排除列表（大写）
```

## 常见问题

### Q: GUI应用无法使用代理？
**A**: 确保已更新D-Bus激活环境：
```bash
dbus-update-activation-environment --systemd \
    http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
```

### Q: 某些应用仍然直连？
**A**: 检查应用是否有内置代理设置，某些应用会忽略系统环境变量。

### Q: 终端代理正常，GUI不行？
**A**: 终端继承shell环境，GUI需要systemd/D-Bus环境，确保运行了环境设置脚本。

### Q: 如何临时禁用代理？
**A**: 方法1 - 修改配置：
```bash
# 编辑 .env.local，设置 ENABLE_PROXY=false
~/dotfiles/scripts/generate-proxy-env.sh
~/dotfiles/scripts/hyprland-startup-env.sh
```

方法2 - 临时启动应用：
```bash
env -u http_proxy -u https_proxy google-chrome-stable
```

### Q: 如何添加更多排除地址？
**A**: 在 `.env.local` 中修改 `NO_PROXY`：
```bash
NO_PROXY=localhost,127.0.0.1,*.local,192.168.1.0/24
```

## 自动化和脚本

### 启动时自动应用
代理配置会在Hyprland启动时自动应用，无需手动干预。

### 切换代理脚本
创建快速切换脚本：
```bash
#!/bin/bash
# toggle-proxy.sh
current=$(grep "ENABLE_PROXY=" ~/.env.local)
if [[ $current == *"true"* ]]; then
    sed -i 's/ENABLE_PROXY=true/ENABLE_PROXY=false/' ~/dotfiles/.env.local
    echo "代理已禁用"
else
    sed -i 's/ENABLE_PROXY=false/ENABLE_PROXY=true/' ~/dotfiles/.env.local  
    echo "代理已启用"
fi

~/dotfiles/scripts/generate-proxy-env.sh
~/dotfiles/scripts/hyprland-startup-env.sh
```

## 多设备同步

代理配置通过 `.env.local` 文件管理，在新设备上：

1. 克隆dotfiles仓库
2. 复制并编辑 `.env.local` 
3. 运行 `./dotfiles.sh setup`
4. 代理配置会自动应用

## 安全注意事项

- `.env.local` 包含敏感信息，不要提交到公共仓库
- 确保代理服务器的安全性
- 定期检查代理配置，避免意外泄露流量

## 故障排除

### 日志检查
```bash
# 查看Hyprland日志
journalctl --user -u hyprland -f

# 查看systemd用户环境
systemctl --user show-environment

# 测试代理连通性
curl -v --proxy http://127.0.0.1:7897 http://www.google.com
```

### 重置配置
```bash
# 完全重置代理配置
rm ~/.config/hypr/proxy-env.conf
~/dotfiles/scripts/generate-proxy-env.sh
hyprctl reload
```