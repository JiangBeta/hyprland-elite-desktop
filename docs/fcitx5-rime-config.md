# Fcitx5 + Rime 输入法配置说明

## 当前配置

### 万象拼音（主要输入法）
- **候选词数量**：9个
- **输入方案**：全拼
- **快捷键**：
  - `Shift`：临时输入英文（inline_ascii模式，不提交候选词）
  - `Ctrl+Space`：切换中英文
  - `Ctrl+``：选择输入方案
  - `F4`：切换简繁体
- **特性**：
  - 支持整句输入和智能补全
  - 用户词典自动学习和调频
  - 中文标点符号（，。？！；：）
  - 预留云拼音接口
  - 默认半角字符

### 万象拼音专业版（可选）
增强版万象拼音，包含更多优化设置

### 明月拼音·简化字（备用）
标准的简体中文拼音输入法

## 安装方式

### 方式一：一键安装（推荐）

```bash
# 1. 安装基础包
sudo pacman -S fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool

# 2. 一键配置
cd ~/dotfiles
./dotfiles.sh input-method

# 3. 重启系统或重新登录
```

### 方式二：分步安装

```bash
# 1. 安装基础fcitx5包
sudo pacman -S fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool

# 2. 配置基础Rime
cd ~/dotfiles
./scripts/setup-rime.sh

# 3. 安装万象词库（可选）
./scripts/setup-rime-wanxiang.sh install

# 4. 测试配置
./scripts/test-fcitx5-rime.sh

# 5. 重启fcitx5
fcitx5-remote -r
```

### 方式三：仅基础配置（最小化）

```bash
# 1. 安装最小包
sudo pacman -S fcitx5 fcitx5-rime

# 2. 仅配置基础Rime
cd ~/dotfiles
./scripts/setup-rime.sh

# 3. 重启
fcitx5-remote -r
```

## 配置文件位置

- **万象自定义配置**：`config/fcitx5-rime/wanxiang.custom.yaml`
- **万象专业版配置**：`config/fcitx5-rime/wanxiang_pro.custom.yaml`
- **默认配置**：`config/fcitx5-rime/default.yaml`
- **明月拼音配置**：`config/fcitx5-rime/luna_pinyin_simp.custom.yaml`
- **fcitx5主配置**：`config/fcitx5/config`

## 管理命令

```bash
# 测试当前配置
./scripts/test-fcitx5-rime.sh

# 智能输入法管理
./scripts/input-method-manager.sh interactive

# 重新部署Rime
rime_deployer --build ~/.local/share/fcitx5/rime/

# 重启fcitx5
fcitx5-remote -r
```

## 最新修复（2025-01-22）

已修复以下问题：
1. ✅ **云拼音不工作** - 简化配置，移除错误组件
2. ✅ **标点符号变英文** - 修复YAML语法，正确配置中文标点
3. ✅ **Shift键行为异常** - 配置为inline_ascii模式

## 故障排除

如果输入法无法正常工作：

1. **检查进程**：`pgrep fcitx5`
2. **系统诊断**：`fcitx5-diagnose`
3. **重新部署**：`rime_deployer --build ~/.local/share/fcitx5/rime/`
4. **重启输入法**：`fcitx5-remote -r`
5. **运行测试**：`./scripts/test-fcitx5-rime.sh`

## 环境变量

确保以下环境变量已设置（通常由dotfiles自动配置）：
```bash
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx  
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx
```