#!/bin/bash
# Rime输入法配置脚本

set -e

echo "🚀 配置 Rime 输入法..."

# 检查是否安装了必要的包
if ! command -v fcitx5 &> /dev/null; then
    echo "❌ fcitx5 未安装，请先安装 fcitx5"
    exit 1
fi

if ! command -v rime_deployer &> /dev/null; then
    echo "❌ rime 未安装，请先安装 fcitx5-rime"
    exit 1
fi

# 创建Rime配置目录
RIME_DIR="$HOME/.local/share/fcitx5/rime"
mkdir -p "$RIME_DIR"

echo "📝 配置基础方案列表..."

# 创建基础配置文件
cat > "$RIME_DIR/default.custom.yaml" << 'EOF'
# 用户自定义配置，覆盖默认配置
patch:
  schema_list:
    - schema: luna_pinyin_simp
    - schema: wanxiang
EOF

echo "🎯 创建万象拼音方案..."

# 创建简化版万象拼音方案
cat > "$RIME_DIR/wanxiang.schema.yaml" << 'EOF'
# Rime schema
# encoding: utf-8

schema:
  schema_id: wanxiang
  name: 万象拼音
  version: "1.0"
  author:
    - 简化版
  description: |
    万象拼音简化版，基于luna_pinyin
  dependencies:
    - luna_pinyin

switches:
  - name: ascii_mode
    reset: 0
    states: [ 中文, 西文 ]
  - name: full_shape
    states: [ 半角, 全角 ]
  - name: simplification
    reset: 1
    states: [ 漢字, 汉字 ]
  - name: ascii_punct
    states: [ 。，, ．， ]

engine:
  processors:
    - ascii_composer
    - recognizer
    - key_binder
    - speller
    - punctuator
    - selector
    - navigator
    - express_editor
  segmentors:
    - ascii_segmentor
    - matcher
    - abc_segmentor
    - punct_segmentor
    - fallback_segmentor
  translators:
    - punct_translator
    - script_translator
  filters:
    - simplifier
    - uniquifier

speller:
  alphabet: zyxwvutsrqponmlkjihgfedcba
  delimiter: " '"
  algebra:
    - erase/^xx$/
    - abbrev/^([a-z]).+$/$1/
    - abbrev/^([zcs]h).+$/$1/
    - derive/^([nl])ve$/$1ue/
    - derive/^([jqxy])u/$1v/
    - derive/un$/uen/
    - derive/ui$/uei/
    - derive/iu$/iou/
    - derive/([aeiou])ng$/$1gn/
    - derive/([dtngkhrzcs])o(u|ng)$/$1o/
    - derive/ong$/on/
    - derive/ao$/oa/
    - derive/([iu])a(o|ng?)$/a$1$2/

translator:
  dictionary: luna_pinyin
  prism: wanxiang

punctuator:
  import_preset: symbols

key_binder:
  import_preset: default

recognizer:
  import_preset: default
EOF

echo "🔄 部署Rime配置..."
rime_deployer --build "$RIME_DIR"

echo "🔄 重启fcitx5..."
fcitx5-remote -r

echo "✅ Rime配置完成！"
echo ""
echo "📋 使用说明："
echo "   • 按 Ctrl+Space 切换中英文"
echo "   • 按 Ctrl+\` 选择输入方案"
echo "   • 可选择：万象拼音 或 明月拼音·简化字"
echo ""
echo "🔧 后续优化建议："
echo "   • 添加云拼音支持"
echo "   • 增加候选词数量"
echo "   • 导入专业词库"