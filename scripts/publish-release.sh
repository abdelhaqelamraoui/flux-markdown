#!/bin/bash
# Resume publication of the exact artifacts recorded by release-manifest.py.
set -euo pipefail
NEW_FULL_VERSION=$(cat .version)
TAG="v$NEW_FULL_VERSION"
DMG_PATH="build/artifacts/FluxMarkdown.dmg"
MACPORTS_TARBALL="build/artifacts/FluxMarkdown-${NEW_FULL_VERSION}-macports-source.tar.gz"
RELEASE_NOTES_FILE="release_notes_tmp.md"
STATE_FILE="build/artifacts/publication-status.txt"
STAGE=preflight
record() { printf '%s\n' "$1" > "$STATE_FILE"; }
failed() {
    code=$?
    record "incomplete: $STAGE"
    echo "Publication incomplete at $STAGE. Fix the error and rerun scripts/publish-release.sh; existing assets will be verified." >&2
    exit "$code"
}
trap failed ERR
python3 scripts/release-manifest.py verify
./scripts/verify-release-entitlements.sh "$DMG_PATH"
# Fail before making a release public if the signing tool/key is unavailable.
./scripts/generate-appcast.sh "$DMG_PATH"

STAGE=github
ASSETS=("$DMG_PATH" "$MACPORTS_TARBALL")
if gh release view "$TAG" >/dev/null 2>&1; then
    VERIFY_DIR=$(mktemp -d)
    trap 'rm -rf "${VERIFY_DIR:-}"' EXIT
    for asset in "${ASSETS[@]}"; do
        name=$(basename "$asset")
        gh release download "$TAG" --pattern "$name" --dir "$VERIFY_DIR"
        cmp "$asset" "$VERIFY_DIR/$name"
    done
else
    gh release create "$TAG" "${ASSETS[@]}" --verify-tag \
        --title "$TAG" --notes-file "$RELEASE_NOTES_FILE" --draft --prerelease=false
fi
# Idempotent, including resuming a draft left by a prior attempt.
gh release edit "$TAG" --draft=false
record 'github complete; sparkle and homebrew pending'

STAGE=sparkle
# Commit only the feed, never unrelated staged files. A retry also pushes an
# existing local commit if the previous push failed.
if ! git diff --quiet -- appcast.xml; then
    git add appcast.xml
    git commit --only appcast.xml -m "chore(sparkle): update appcast.xml for $TAG"
fi
git push origin HEAD:master
record 'github and sparkle complete; homebrew pending'

STAGE=homebrew
./scripts/update-homebrew-cask.sh "$NEW_FULL_VERSION"
record 'github and sparkle complete; homebrew updater completed'
printf 'GitHub and Sparkle published: %s\nHomebrew updater completed; consult its channel-specific result.\n' "$TAG"
# Retain the notes: the manifest binds their bytes and retries need them.
