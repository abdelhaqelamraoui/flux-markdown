#!/bin/bash
# Produce a locally signed acceptance bundle without changing release/build numbers.
set -euo pipefail
[ "$#" -eq 2 ] || { echo 'Usage: prepare-acceptance-app.sh BUILT_APP OUTPUT_APP' >&2; exit 2; }
source_app="$1"
output_app="$2"
[ ! -e "$output_app" ] || { echo 'Output already exists' >&2; exit 2; }
/usr/bin/ditto "$source_app" "$output_app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$output_app/Contents/Info.plist")
display="$version-dev-$(date '+%Y%m%d-%H%M%S')"
for info in "$output_app/Contents/Info.plist" "$output_app/Contents/PlugIns/MarkdownPreview.appex/Contents/Info.plist"; do
    /usr/libexec/PlistBuddy -c "Set :FMDisplayVersion $display" "$info" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :FMDisplayVersion string $display" "$info"
done
entitlements=$(mktemp)
trap 'rm -f "$entitlements"' EXIT
/usr/bin/sed "s|\$HOME|$HOME|g" Sources/MarkdownPreview/MarkdownPreview.entitlements > "$entitlements"
/usr/bin/codesign --force --sign - --entitlements "$entitlements" "$output_app/Contents/PlugIns/MarkdownPreview.appex"
/usr/bin/codesign --force --sign - --entitlements Sources/Markdown/Markdown.entitlements "$output_app"
/usr/bin/codesign --verify --deep --strict "$output_app"
printf '%s\n' "$display"
