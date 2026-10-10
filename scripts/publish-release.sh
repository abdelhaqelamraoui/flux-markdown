#!/bin/bash
# Publish an already prepared and checked release without bumping again.
set -euo pipefail
NEW_FULL_VERSION=$(cat .version)
DMG_PATH="build/artifacts/FluxMarkdown.dmg"
MACPORTS_TARBALL="build/artifacts/FluxMarkdown-${NEW_FULL_VERSION}-macports-source.tar.gz"
RELEASE_NOTES_FILE="release_notes_tmp.md"
python3 scripts/release-manifest.py verify
./scripts/verify-release-entitlements.sh "$DMG_PATH"
echo "📦 Creating GitHub Release v$NEW_FULL_VERSION..."
RELEASE_ASSETS="$DMG_PATH"
if [ -n "$MACPORTS_TARBALL" ] && [ -f "$MACPORTS_TARBALL" ]; then
    RELEASE_ASSETS="$RELEASE_ASSETS $MACPORTS_TARBALL"
fi
gh release create "v$NEW_FULL_VERSION" $RELEASE_ASSETS \
    --title "v$NEW_FULL_VERSION" \
    --notes-file "$RELEASE_NOTES_FILE" \
    --draft=false \
    --prerelease=false

rm "$RELEASE_NOTES_FILE"

echo ""
echo "✨ Updating Sparkle appcast..."
# Find sign_update tool (keys are stored in Keychain, not as files)
SIGN_UPDATE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -type f -perm +111 2>/dev/null | grep "Sparkle/bin/sign_update" | head -1)
if [ -z "$SIGN_UPDATE_BIN" ] && [ -x "./sign_update" ]; then
    SIGN_UPDATE_BIN="./sign_update"
fi

if [ -f "./scripts/generate-appcast.sh" ] && [ -x "$SIGN_UPDATE_BIN" ]; then
    ./scripts/generate-appcast.sh "$DMG_PATH"
    
    if [ -f "appcast.xml" ]; then
        git add appcast.xml
        git commit -m "chore(sparkle): update appcast.xml for v$NEW_FULL_VERSION" || true
        git push origin master || true
        echo "✅ Appcast updated and committed"
    fi
else
    echo "⚠️  Skipping appcast update"
    if [ ! -f "./scripts/generate-appcast.sh" ]; then
        echo "   Missing: ./scripts/generate-appcast.sh"
    fi
    if [ -z "$SIGN_UPDATE_BIN" ]; then
        echo "   Missing: sign_update tool (build the project once to download Sparkle via SPM)"
    fi
fi

echo ""
echo "🍺 Updating Homebrew Cask..."
if [ -f "./scripts/update-homebrew-cask.sh" ]; then
    ./scripts/update-homebrew-cask.sh "$NEW_FULL_VERSION" || echo "⚠️  Homebrew update failed (non-fatal)"
else
    echo "⚠️  Skipping Homebrew update (script not found)"
fi

echo ""
echo "🎉 Successfully released v$NEW_FULL_VERSION!"
echo ""
echo "📋 Post-release checklist:"
echo "   ✅ GitHub Release created"
echo "   ✅ DMG uploaded"
echo "   ✅ Sparkle appcast updated (if configured)"
echo "   ✅ Homebrew Cask updated (if configured)"
echo ""
echo "🌐 Release URL: https://github.com/xykong/flux-markdown/releases/tag/v$NEW_FULL_VERSION"
