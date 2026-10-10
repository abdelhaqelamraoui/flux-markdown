#!/bin/bash
set -e

VERSION_FILE=".version"
DMG_PATH="build/artifacts/FluxMarkdown.dmg"
CASK_FILE="../homebrew-tap/Casks/flux-markdown.rb"
OFFICIAL_CASK_FILE="../homebrew-tap/Drafts/flux-markdown-official.rb"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ Error: Version file not found: $VERSION_FILE"
    exit 1
fi

VERSION=$(cat "$VERSION_FILE")

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: DMG not found at $DMG_PATH"
    echo "Please build the DMG first with: make dmg"
    exit 1
fi

if [ ! -f "$CASK_FILE" ]; then
    echo "❌ Error: Homebrew Cask file not found at $CASK_FILE"
    echo "Please ensure homebrew-tap repository is cloned at ../homebrew-tap"
    exit 1
fi

echo "🍺 Updating Homebrew Cask for v$VERSION..."
echo ""

SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo "✅ Calculated SHA256: $SHA256"
echo ""

CURRENT_VERSION=$(grep "version \"" "$CASK_FILE" | head -1 | sed 's/.*version "\(.*\)"/\1/')
CURRENT_SHA256=$(grep "sha256 \"" "$CASK_FILE" | head -1 | sed 's/.*sha256 "\(.*\)"/\1/')

echo "📊 Current Cask Info:"
echo "   Version: $CURRENT_VERSION"
echo "   SHA256:  $CURRENT_SHA256"
echo ""
echo "📊 New Cask Info:"
echo "   Version: $VERSION"
echo "   SHA256:  $SHA256"
echo ""

if [ "$CURRENT_VERSION" = "$VERSION" ] && [ "$CURRENT_SHA256" = "$SHA256" ]; then
    echo "✅ Homebrew Cask is already up to date!"
    exit 0
fi

echo "🔧 Updating tap cask file..."
if ! hdiutil imageinfo "$DMG_PATH" >/dev/null 2>&1; then
    echo "Invalid DMG; refusing cask update" >&2; exit 1
fi
verify_mount=$(mktemp -d)
hdiutil attach "$DMG_PATH" -mountpoint "$verify_mount" -nobrowse -readonly -quiet
trap 'hdiutil detach "$verify_mount" -quiet >/dev/null 2>&1 || true; rmdir "$verify_mount" 2>/dev/null || true' EXIT
if [ ! -x "$verify_mount/install-flux-markdown.sh" ]; then
    echo "DMG lacks the vendor installer; refusing migration" >&2; exit 1
fi
hdiutil detach "$verify_mount" -quiet
rmdir "$verify_mount"
trap - EXIT
python3 - "$VERSION" "$SHA256" "$CASK_FILE" <<'PY_CASK'
import pathlib,sys
version,checksum,target=sys.argv[1:]
template=pathlib.Path('scripts/homebrew/flux-markdown-installer.rb.in').read_text()
pathlib.Path(target).write_text(template.replace('@VERSION@',version).replace('@SHA256@',checksum))
PY_CASK
echo "✅ Tap cask updated: $CASK_FILE"

if [ -f "$OFFICIAL_CASK_FILE" ]; then
    echo "🔧 Updating official cask file..."
    sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$OFFICIAL_CASK_FILE"
    sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$OFFICIAL_CASK_FILE"
    echo "✅ Official cask updated: $OFFICIAL_CASK_FILE"
fi

echo ""

cd "$(dirname "$CASK_FILE")/.."

CHANGED_FILES=()
(git diff --quiet Casks/flux-markdown.rb && git diff --cached --quiet Casks/flux-markdown.rb) || CHANGED_FILES+=("Casks/flux-markdown.rb")
(git diff --quiet Drafts/flux-markdown-official.rb && git diff --cached --quiet Drafts/flux-markdown-official.rb) 2>/dev/null || CHANGED_FILES+=("Drafts/flux-markdown-official.rb")

if [ ${#CHANGED_FILES[@]} -gt 0 ]; then
    echo "📝 Changes detected in: ${CHANGED_FILES[*]}"
    for f in "${CHANGED_FILES[@]}"; do
        git diff "$f"
    done
    echo ""

    if [ -n "${CI:-}" ] || [ ! -t 0 ]; then
        echo "⚠️  Non-interactive mode: skipping commit/push. Please commit manually:"
        echo "   cd $(pwd)"
        echo "   git add ${CHANGED_FILES[*]}"
        echo "   git commit -m 'chore(cask): update flux-markdown to v$VERSION'"
        echo "   git push origin master"
        exit 2
    else
        read -p "👉 Commit and push changes? (y/n) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add "${CHANGED_FILES[@]}"
            git commit -m "chore(cask): update flux-markdown to v$VERSION"
            git push origin master
            echo "✅ Changes committed and pushed to homebrew-tap"
        else
            echo "⚠️  Changes not committed. Please commit manually:"
            echo "   cd $(pwd)"
            echo "   git add ${CHANGED_FILES[*]}"
            echo "   git commit -m 'chore(cask): update flux-markdown to v$VERSION'"
            echo "   git push origin master"
            exit 2
        fi
    fi
else
    git fetch origin master
    if ! git diff --quiet FETCH_HEAD -- Casks/flux-markdown.rb Drafts/flux-markdown-official.rb; then
        echo "Cask files differ from the published tap; commit/push the prepared changes before reporting success." >&2
        exit 2
    fi
    echo "Cask files match the published tap."
fi

echo ""
echo "Cask changes completed. Verify the tap remote before announcing availability. Update command:"
echo "   brew update && brew upgrade flux-markdown"
echo ""
echo "📋 To submit to official homebrew-cask:"
echo "   ./scripts/submit-to-homebrew.sh"
