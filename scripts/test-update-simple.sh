#!/bin/bash
set -e

echo "🧪 Sparkle 更新测试（简易版）"
echo ""
echo "原理：降低本地版本号，触发更新到远端 v1.6.93"
echo ""

read -p "这会临时修改本地安装的应用。继续？[y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

APP_PATH="/Applications/Markdown Preview Enhanced.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 应用未安装在 /Applications"
    exit 1
fi

echo "📋 当前版本信息："
defaults read "$INFO_PLIST" CFBundleShortVersionString
defaults read "$INFO_PLIST" CFBundleVersion

echo ""
echo "🔧 修改版本号为 1.6.90 (build 90)..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.6.90" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 90" "$INFO_PLIST"

echo "✅ 版本号已降低"
echo ""
echo "📋 修改后版本："
defaults read "$INFO_PLIST" CFBundleShortVersionString
defaults read "$INFO_PLIST" CFBundleVersion

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  🧪 开始测试"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "1. 打开 'Markdown Preview Enhanced' 应用"
echo "2. 点击 '检查更新...' 或按 ⌘U"
echo "3. 应该检测到 v1.6.93"
echo "4. 点击 'Install' 按钮"
echo "5. 观察安装是否成功"
echo ""
echo "注意："
echo "  • 远端 v1.6.93 没有修复（会失败）"
echo "  • 这个测试只能验证「检查更新」功能"
echo "  • 要测试修复效果，需要发布新版本"
echo ""
echo "恢复方法："
echo "  ./scripts/install.sh"
echo ""
