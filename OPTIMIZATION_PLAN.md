# Dotfiles 优化计划

## 📋 当前问题分析

### 1. 根目录脚本冗余
- `install.sh` (8.1KB) - 主安装脚本
- `sync.sh` (9.4KB) - 配置同步脚本  
- `cleanup.sh` (5.8KB) - 清理脚本

### 2. 重复/过时文件 ✅ 已清理
- ~~`config/waybar/pomodoro-old.sh`~~ ✅ 已删除
- ~~`config/waybar/pomodoro-control-old.sh`~~ ✅ 已删除
- ~~`config/hypr/screenshot-backup.sh`~~ ✅ 已删除
- ~~`config/hypr/screenshot-simple.sh`~~ ✅ 已删除
- ~~`config/waybar/pomodoro_config.backup`~~ ✅ 已删除

### 3. 🚨 严重的配置污染问题
#### Claude 个人数据污染
- `claude/statsig/` - Claude AI 的个人统计和会话数据
- `claude/settings.local.json` - 个人本地设置
- 这些文件包含个人隐私信息，不应该提交到公共仓库

#### 个人配置文件污染
- `config/waybar/pomodoro_state.json` - 个人番茄钟状态
- `config/fcitx5/pinyin/user.dict` - 个人词典
- `config/fcitx5/pinyin/user.history` - 个人输入历史
- `config/totp/` - 个人二步验证密钥
- `.env.local` - 个人环境变量

#### 缓存和临时文件污染
- `config/fcitx5/conf/cached_layouts` - 系统缓存文件

### 4. 脚本分散
- ntfy相关脚本分布在scripts/和config/mako/
- screenshot脚本分布在config/hypr/
- 部分功能脚本可以合并

## 🎯 优化方案

### 阶段1: 清理过时文件
```bash
# 删除过时的脚本
rm config/waybar/pomodoro-old.sh
rm config/waybar/pomodoro-control-old.sh
rm config/hypr/screenshot-backup.sh
rm config/hypr/screenshot-simple.sh

# 清理备份配置文件
rm config/waybar/pomodoro_config.backup
```

### 阶段2: 重构根目录脚本
创建统一的管理脚本 `manage.sh`:
```bash
./manage.sh install [--module1 --module2]  # 替代 install.sh
./manage.sh sync                           # 替代 sync.sh  
./manage.sh cleanup                        # 替代 cleanup.sh
./manage.sh backup                         # 新功能
./manage.sh restore [backup_name]          # 新功能
```

### 阶段3: 脚本分类整理
```
scripts/
├── core/           # 核心系统脚本
│   ├── install.sh
│   ├── sync.sh
│   └── cleanup.sh
├── desktop/        # 桌面环境脚本
│   ├── sddm/
│   ├── screenshot/
│   └── wallpaper/
├── productivity/   # 生产力工具
│   ├── pomodoro/
│   ├── totp/
│   └── notifications/
└── apps/          # 应用启动器
    ├── launchers/
    └── wrappers/
```

### 阶段4: 配置文件标准化
- 统一环境变量管理 (.env)
- 统一错误处理和日志
- 添加配置验证功能

## 📁 建议的新目录结构

```
dotfiles/
├── bin/                    # 可执行脚本（替代原根目录脚本）
│   └── manage.sh          # 统一管理脚本
├── config/                # 配置文件（保持现状，清理过时文件）
├── scripts/               # 按功能分类的脚本
│   ├── core/
│   ├── desktop/
│   ├── productivity/
│   └── apps/
├── shell/                 # Shell配置（保持现状）
├── docs/                  # 文档目录
│   ├── README.md         # 移动到这里
│   ├── README.en.md
│   ├── CONTRIBUTING.md
│   └── OPTIMIZATION_PLAN.md
└── templates/             # 配置模板
    └── .env.example
```

## 🚀 实施步骤

1. **立即可做**: 清理过时文件
2. **本周内**: 创建manage.sh脚本
3. **下周**: 重新组织scripts目录
4. **后续**: 更新文档和README

## 📈 预期收益

- 减少根目录文件数量 (从20+个减少到10个左右)
- 提高脚本可维护性
- 更清晰的项目结构
- 更好的用户体验
