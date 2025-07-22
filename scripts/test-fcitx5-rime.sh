#!/bin/bash
# fcitx5+rime配置测试脚本

echo "🧪 测试fcitx5+rime配置..."

# 检查进程状态
echo "📝 检查fcitx5进程状态:"
if pgrep fcitx5 > /dev/null; then
    echo "✅ fcitx5 正在运行"
else
    echo "❌ fcitx5 未运行"
fi

# 检查配置文件
echo "📝 检查配置文件:"
RIME_DIR="$HOME/.local/share/fcitx5/rime"

configs=(
    "$RIME_DIR/wanxiang.custom.yaml"
    "$RIME_DIR/wanxiang_pro.custom.yaml" 
    "$RIME_DIR/default.yaml"
    "$RIME_DIR/wanxiang.schema.yaml"
)

for config in "${configs[@]}"; do
    if [[ -f "$config" ]]; then
        echo "✅ $(basename "$config") 存在"
    else
        echo "❌ $(basename "$config") 缺失"
    fi
done

# 检查方案部署
echo "📝 检查方案部署状态:"
build_dir="$RIME_DIR/build"
if [[ -d "$build_dir" ]]; then
    echo "✅ build目录存在"
    
    schemas=(
        "wanxiang.prism.bin"
        "wanxiang.table.bin" 
        "luna_pinyin_simp.prism.bin"
    )
    
    for schema in "${schemas[@]}"; do
        if [[ -f "$build_dir/$schema" ]]; then
            echo "✅ $schema 已编译"
        else
            echo "⚠️  $schema 未编译"
        fi
    done
else
    echo "❌ build目录不存在"
fi

echo ""
echo "🔧 修复建议:"
echo "1. 云拼音: 需要安装librime-predict或配置在线云拼音"
echo "2. 标点符号: 已修复为中文标点符号"
echo "3. Shift键: 已配置为inline_ascii模式"
echo ""
echo "📋 使用方法:"
echo "• Ctrl+Space: 切换输入法"
echo "• Ctrl+\`: 切换输入方案"
echo "• Shift: 临时输入英文"
echo "• F4: 切换简繁体"