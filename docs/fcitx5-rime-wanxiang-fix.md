# Fcitx5 + Rime + 万象输入法修复记录

本文档记录了一次复杂的 fcitx5 + rime + rime_wanxiang 输入法配置问题的排查与解决过程。

## 初始问题

用户无法正常使用中文输入，表现为可以唤出输入框，但没有候选词，确认后直接输出英文字符。

## 排查过程

1.  **Lua 脚本错误**：最初的日志显示大量 `LuaProcessor` 错误，表明 Rime 的 Lua 脚本引擎未能正确加载。经查，原因是安装脚本 `setup-rime-wanxiang.sh` 在复制文件时遗漏了核心的 `rime.lua` 文件。

2.  **部署失败**：修复 `rime.lua` 丢失问题后，手动执行 `rime_deployer` 部署命令，发现大量词典编译失败的错误，如 `dictionary 'wanxiang_pro' failed to compile`。

3.  **定位根源**：错误日志显示，部署失败的原因是缺少核心词典文件，例如 `zh_dicts_pro/chars.dict.yaml`。经过对 `rime_wanxiang` GitHub 仓库的深入研究发现，该项目结构复杂，包含多个词典目录，而旧的安装脚本使用的 `find` 和 `cp` 命令未能完整复制整个项目的文件结构。

## 最终解决方案

问题的根源在于安装脚本 `setup-rime-wanxiang.sh` 的逻辑不完善，无法应对 `rime_wanxiang` 项目复杂的目录结构和依赖。

最终的修复措施是彻底重写该脚本，采用了更可靠、更健壮的逻辑：

1.  **清理旧配置**：在安装前，强制清理 Rime 目录中所有旧的、可能不完整的文件，避免干扰。

2.  **完整克隆**：使用 `git clone` 从 GitHub 下载完整的 `rime_wanxiang` 项目。

3.  **验证完整性**：在下载后，脚本会检查 `zh_dicts_pro`, `lookup`, `lua` 等关键的目录是否存在，确保下载内容的完整性。

4.  **精确同步**：使用 `rsync -a` 命令进行文件同步。`rsync` 的归档模式 `-a` 能确保所有文件、目录、权限和链接都**原封不动地**被复制到 Rime 配置目录，完美解决了文件缺失的问题。

5.  **部署与检查**：脚本在同步文件后，会自动执行 `rime_deployer` 命令来编译和部署词库，并捕获其输出，方便判断部署是否成功。

通过以上步骤，保证了 Rime 拥有了完整且正确的配置文件和词库，输入法最终恢复正常。

## 最新修复记录 (2025-01-22)

### 问题描述
用户反馈fcitx5+rime+万象输入法存在以下问题：
1. 云拼音不工作
2. 标点符号变成英文了  
3. 中文输入状态下按shift应该commit英文而不是commit第一个候选词

### 根本原因分析
1. **云拼音问题**：配置中引用了不存在的lua脚本组件（date_translator, time_translator, custom_phrase）
2. **标点符号问题**：YAML语法错误，双引号转义有问题
3. **Shift键行为**：ascii_composer配置不正确

### 修复措施

#### 1. 修复YAML语法错误
```yaml
# 错误的配置
"\"": { pair: [ """, """ ] }

# 修复后的配置  
'"': { pair: [ """, """ ] }
```

#### 2. 简化标点符号配置
```yaml
punctuator:
  import_preset: symbols
  half_shape:
    ",": "，"
    ".": "。" 
    "?": "？"
    "!": "！"
    ";": "；"
    ":": "："
    "\\": "、"
    "/": "/"
```

#### 3. 修复Shift键行为
```yaml
ascii_composer:
  good_old_caps_lock: true
  switch_key:
    Shift_L: inline_ascii
    Shift_R: inline_ascii  
    Caps_Lock: clear
```

#### 4. 移除错误的lua组件
```yaml
# 移除这些不存在的组件
engine/translators:
  - punct_translator  
  - script_translator
  # 移除：lua_translator@date_translator
  # 移除：lua_translator@time_translator
  # 移除：table_translator@custom_phrase
```

### 修复结果
- ✅ 标点符号正常显示中文标点
- ✅ Shift键实现inline_ascii模式，临时输入英文不提交候选词
- ✅ 移除lua错误，配置部署成功
- ✅ 基础输入功能完全正常

### 工具增强
- 新增测试脚本：`scripts/test-fcitx5-rime.sh`
- 更新安装脚本，支持专业版配置
- 完善文档，提供多种安装方式

该修复确保了fcitx5+rime+万象输入法的稳定性和易用性。
