# Dotfiles

个人配置文件管理仓库

## 目录结构

```
dotfiles/
├── config/          # ~/.config 下的配置文件
│   ├── hypr/        # Hyprland 配置
│   ├── waybar/      # Waybar 配置
│   ├── fcitx5/      # 输入法配置
│   └── kitty/       # 终端配置
├── shell/           # Shell 配置文件
│   ├── bashrc       # Bash 配置
│   ├── zshrc        # Zsh 配置
│   └── screenrc     # Screen 配置
├── scripts/         # 脚本文件
├── install.sh       # 安装脚本
├── sync.sh          # 同步脚本
└── README.md        # 说明文档
```

## 使用方法

### 首次设置

1. 克隆仓库到家目录：
   ```bash
   git clone <your-repo-url> ~/dotfiles
   ```

2. 运行安装脚本：
   ```bash
   chmod +x ~/dotfiles/install.sh
   ~/dotfiles/install.sh
   ```

### 同步更改

当你修改了配置文件后，运行同步脚本：
```bash
chmod +x ~/dotfiles/sync.sh
~/dotfiles/sync.sh
```

然后提交更改：
```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

### 在新机器上使用

1. 克隆仓库
2. 运行 `install.sh`
3. 重新登录或重新加载配置

## 包含的配置

- **Hyprland**: 窗口管理器配置
- **Waybar**: 状态栏配置
- **Fcitx5**: 输入法配置
- **Kitty**: 终端模拟器配置
- **Bash/Zsh**: Shell 配置
- **Screen**: 终端复用器配置

## 注意事项

- 安装脚本会自动备份现有配置
- 所有配置文件都使用软链接，修改会直接反映到 dotfiles 目录
- 定期运行 `sync.sh` 来保持同步