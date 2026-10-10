#!/bin/bash
# Build this exact commit using the pinned macOS 11-capable CI toolchain.
set -euo pipefail
ref=${1:?Usage: build-release-remotely.sh REF}
expected_commit=$(git rev-parse "$ref^{commit}")
expected_version=$(git show "$ref:.version")
run_url=$(gh workflow run release-build.yml --ref "$ref")
printf '%s\n' "$run_url" >&2
run_id=${run_url##*/}
[[ "$run_id" =~ ^[0-9]+$ ]] || { echo 'Missing workflow run ID' >&2; exit 1; }
gh run watch "$run_id" --exit-status >&2
actual_commit=$(gh run view "$run_id" --json headSha --jq .headSha)
[ "$actual_commit" = "$expected_commit" ] || { echo 'Workflow commit mismatch' >&2; exit 1; }
output="$PWD/build/remote-release-$run_id"
mkdir -p "$output"
gh run download "$run_id" -n release-app -D "$output"
[ "$(cat "$output/commit.txt")" = "$expected_commit" ] || exit 1
[ "$(cat "$output/version.txt")" = "$expected_version" ] || exit 1
checksum=$(awk '{print $1}' "$output/SHA256SUMS")
[ "$(shasum -a 256 "$output/FluxMarkdown.app.zip" | awk '{print $1}')" = "$checksum" ] || exit 1
ditto -x -k "$output/FluxMarkdown.app.zip" "$output"
app="$output/FluxMarkdown.app"
[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$expected_version" ] || exit 1
scripts/verify-release-entitlements.sh "$app" >&2
for binary in "$app/Contents/MacOS/FluxMarkdown" \
    "$app/Contents/PlugIns/MarkdownPreview.appex/Contents/MacOS/MarkdownPreview" \
    "$app/Contents/PlugIns/MarkdownPreview.appex/Contents/XPCServices/FluxMarkdownSearchLauncher.xpc/Contents/MacOS/FluxMarkdownSearchLauncher"; do
    lipo "$binary" -verify_arch arm64 x86_64
    xcrun vtool -show-build "$binary" > "$output/deployment-check.txt"
    [ "$(awk '$1 == "minos" && $2 == "11.0" {n++} END {print n+0}' "$output/deployment-check.txt")" -eq 2 ] || { echo "Unexpected deployment target: $binary" >&2; exit 1; }
done
printf '%s\n' "$app"
