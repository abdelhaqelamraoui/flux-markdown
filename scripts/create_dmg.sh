#!/bin/bash
set -e

APP_NAME="FluxMarkdown"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="${HOME}/Library/Developer/Xcode/DerivedData/FluxMarkdown-*"
DMG_NAME="FluxMarkdown.dmg"
OUTPUT_DIR="build/artifacts"

echo "🚀 Starting DMG creation for ${APP_NAME}..."

# 1. Ensure clean build
echo "📦 Building application..."
if [ -z "${RELEASE_APP_PATH:-}" ]; then make app; fi

# 2. Locate the built app
EXPECTED_VERSION="$(cat .version 2>/dev/null || true)"
APP_PATH="${RELEASE_APP_PATH:-}"
if [ -z "$APP_PATH" ]; then
    APP_PATH="$(xcodebuild -project FluxMarkdown.xcodeproj -scheme Markdown -configuration Release -showBuildSettings -json 2>/dev/null | python3 -c 'import json,sys; s=next(x["buildSettings"] for x in json.load(sys.stdin) if x["target"]=="Markdown"); print(s["TARGET_BUILD_DIR"]+"/"+s["FULL_PRODUCT_NAME"])')"
fi
[ -d "$APP_PATH" ] || { echo "Missing release application: $APP_PATH" >&2; exit 1; }
actual_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
[ "$actual_version" = "$EXPECTED_VERSION" ] || { echo 'Release application version mismatch' >&2; exit 1; }
if /usr/libexec/PlistBuddy -c 'Print :FMDisplayVersion' "$APP_PATH/Contents/Info.plist" >/dev/null 2>&1; then
    echo 'Refusing to package a development acceptance application' >&2; exit 1
fi
./scripts/verify-release-entitlements.sh "$APP_PATH"

echo "✅ Found app at: $APP_PATH"

# 3. Create artifacts directory
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$DMG_NAME"

# 4. Prepare temporary folder
TMP_DIR=$(mktemp -d)
echo "📂 Preparing DMG content in $TMP_DIR..."
cp -R "$APP_PATH" "$TMP_DIR/"
cp scripts/install-flux-markdown.sh "$TMP_DIR/install-flux-markdown.sh"
chmod +x "$TMP_DIR/install-flux-markdown.sh"
# 4.5. Pre-seed the background directory with Retina asset for Finder
mkdir -p "$TMP_DIR/.background"
cp assets/dmg/background@2x.png "$TMP_DIR/.background/background@2x.png"

# 5. Create DMG using create-dmg
echo "💿 Creating styled DMG using create-dmg..."

# Volume name must change to bypass Finder cache for the layout
VOLUME_NAME="Install ${APP_NAME}"
create-dmg \
  --volname "${VOLUME_NAME}" \
  --background "assets/dmg/background.tiff" \
  --window-pos 200 120 \
  --window-size 660 468 \
  --icon-size 100 \
  --icon "${APP_BUNDLE}" 180 220 \
  --app-drop-link 480 220 \
  --icon ".background" 120 120 \
  "$OUTPUT_DIR/$DMG_NAME" \
  "$TMP_DIR/"

echo "🔐 Verifying release entitlements..."
./scripts/verify-release-entitlements.sh "$OUTPUT_DIR/$DMG_NAME"

# 6. Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "✅ DMG created successfully at: $OUTPUT_DIR/$DMG_NAME"
echo ""
