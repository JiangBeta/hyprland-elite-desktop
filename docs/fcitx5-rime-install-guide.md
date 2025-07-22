# Fcitx5 + Rime 输入法安装指南

本指南提供多种fcitx5+rime输入法的安装方式，适合不同需求的用户。

## 🚀 快速安装

### 新手推荐：一键安装脚本

```bash
cd ~/dotfiles
./scripts/install-fcitx5-rime.sh
```

这个脚本提供交互式界面，可以选择不同的安装方式。

## 📋 安装方式对比

| 安装方式 | 软件包 | 万象拼音 | 配置优化 | 适合用户 |
|---------|--------|----------|----------|----------|
| **完整安装** | fcitx5全套 | ✅ | ✅ | 一般用户（推荐） |
| **基础安装** | fcitx5全套 | ❌ | ✅ | 仅需基础功能 |
| **最小安装** | 核心包 | ❌ | ✅ | 资源受限环境 |
| **仅更新配置** | 不安装 | 根据现有 | ✅ | 已有fcitx5用户 |
| **修复现有** | 不安装 | 保持现有 | ✅ | 有问题的配置 |

## 🎯 详细安装步骤

### 方式一：交互式安装（推荐）

```bash
cd ~/dotfiles
./scripts/install-fcitx5-rime.sh
```

按提示选择安装类型，脚本会自动完成所有配置。

### 方式二：命令行直接安装

```bash
# 完整安装
./scripts/install-fcitx5-rime.sh full

# 基础安装  
./scripts/install-fcitx5-rime.sh basic

# 最小安装
./scripts/install-fcitx5-rime.sh minimal

# 仅更新配置
./scripts/install-fcitx5-rime.sh config-only

# 修复现有配置
./scripts/install-fcitx5-rime.sh fix
```

### 方式三：分步手动安装

```bash
# 1. 安装软件包
sudo pacman -S fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool

# 2. 配置基础Rime
cd ~/dotfiles
./scripts/setup-rime.sh

# 3. 安装万象词库（可选）
./scripts/setup-rime-wanxiang.sh install

# 4. 部署配置
rime_deployer --build ~/.local/share/fcitx5/rime/

# 5. 重启输入法
fcitx5-remote -r
```

### 方式四：使用dotfiles主脚本

```bash
cd ~/dotfiles
./dotfiles.sh input-method
```

## 🔧 软件包说明

### 必需包
- `fcitx5` - 核心输入法框架
- `fcitx5-rime` - Rime输入法引擎

### 推荐包
- `fcitx5-gtk` - GTK应用支持
- `fcitx5-qt` - Qt应用支持  
- `fcitx5-configtool` - 图形配置工具
- `fcitx5-chinese-addons` - 中文输入增强（可选）

### 可选包
- `rime-pinyin-simp` - 简体拼音词库（通常已包含）

## 📁 配置文件说明

安装后会创建以下配置：

```
~/.local/share/fcitx5/rime/
├── default.yaml              # 主配置文件
├── wanxiang.custom.yaml       # 万象拼音配置
├── wanxiang_pro.custom.yaml   # 万象拼音专业版
├── luna_pinyin_simp.custom.yaml # 明月拼音配置
├── wanxiang.schema.yaml       # 万象拼音方案
└── build/                     # 编译后的文件
```

## ✨ 功能特色

### 已修复问题（2025-01-22）
- ✅ **标点符号显示英文** - 现在正确显示中文标点
- ✅ **Shift键行为异常** - 现在按Shift临时输入英文，不提交候选词
- ✅ **云拼音不工作** - 简化配置，移除错误组件

### 优化功能
- 🎯 **智能候选词** - 9个候选词，支持整句输入
- ⚡ **用户词典** - 自动学习和词频调整
- 🔤 **中英混输** - Shift键临时英文输入
- 📝 **中文标点** - 自动中文标点符号（，。？！；：）
- 🌐 **云拼音接口** - 预留云拼音扩展接口

## 🔍 测试和诊断

### 安装后测试
```bash
# 运行配置测试
./scripts/test-fcitx5-rime.sh

# 系统诊断
fcitx5-diagnose
```

### 常用管理命令
```bash
# 重新部署Rime
rime_deployer --build ~/.local/share/fcitx5/rime/

# 重启fcitx5
fcitx5-remote -r

# 检查fcitx5状态
pgrep fcitx5

# 智能输入法管理
./scripts/input-method-manager.sh interactive
```

## 🎮 使用说明

### 基本操作
- **Ctrl+Space** - 切换中英文输入法
- **Ctrl+\`** - 选择输入方案（万象拼音/明月拼音等）
- **Shift** - 临时输入英文（inline_ascii模式）
- **F4** - 切换简繁体

### 高级功能
- **翻页** - `-=` 或 `,`  `.`
- **符号输入** - `/fh` 输入符号，`/sx` 输入数学符号
- **候选词选择** - 数字键 1-9

## 🆘 故障排除

### 输入法无法启动
```bash
# 检查进程
pgrep fcitx5

# 手动启动
fcitx5 -d

# 检查环境变量
echo $GTK_IM_MODULE $QT_IM_MODULE
```

### 无候选词或乱码
```bash  
# 重新部署
rime_deployer --build ~/.local/share/fcitx5/rime/

# 检查配置语法
./scripts/test-fcitx5-rime.sh

# 修复配置
./scripts/install-fcitx5-rime.sh fix
```

### 环境变量问题
确保以下环境变量已设置（通常由dotfiles自动配置）：
```bash
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx  
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx
```

## 📚 相关文档

- [详细配置说明](./fcitx5-rime-config.md)
- [问题修复记录](./fcitx5-rime-wanxiang-fix.md)  
- [更新历史](./fcitx5-rime-wanxiang-update.md)

## 🤝 支持

如遇到问题：
1. 首先运行 `./scripts/test-fcitx5-rime.sh` 进行诊断
2. 查看相关文档寻找解决方案
3. 尝试 `./scripts/install-fcitx5-rime.sh fix` 修复配置

---

*该安装指南涵盖了从新手到高级用户的各种需求，选择适合你的安装方式即可！*