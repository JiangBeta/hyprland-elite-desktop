# Fcitx5 + Rime 输入法配置说明

## 当前配置

### 万象拼音（主要输入法）
- **候选词数量**：8个
- **输入方案**：全拼
- **快捷键**：
  - `左Shift`：切换到英文输入法（并清空当前输入）
  - `Ctrl+Space`：切换中英文
  - `Ctrl+``：选择输入方案
- **特性**：
  - 支持整句输入
  - 用户词典自动学习
  - 中英文混输
  - 默认半角字符

### 明月拼音·简化字（备用）
标准的简体中文拼音输入法

## 新电脑部署

```bash
# 1. 安装fcitx5和rime
sudo pacman -S fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool

# 2. 部署dotfiles配置
cd ~/dotfiles
./dotfiles.sh input-method

# 3. 重启系统或重新登录
```

## 配置文件位置

- 自定义配置：`config/fcitx5-rime/wanxiang.custom.yaml`
- 默认配置：`config/fcitx5-rime/default.yaml`
- fcitx5主配置：`config/fcitx5/config`

## 故障排除

如果输入法无法正常工作：

1. 检查环境变量是否设置正确
2. 运行 `fcitx5-diagnose` 检查问题
3. 重新部署：`rime_deployer --build ~/.local/share/fcitx5/rime/`
4. 重启fcitx5：`fcitx5-remote -r`