#!/bin/bash
set -euo pipefail
# This gate never changes xcode-select or the product deployment target.
TARGET=${1:-11.0}
XCODE_MAJOR=$(xcodebuild -version | awk '/^Xcode / {split($2, v, "."); print v[1]}')
if [ "$XCODE_MAJOR" -ge 27 ] && [ "${TARGET%%.*}" -lt 12 ]; then
    echo 'This Xcode cannot build the macOS 11 product target. Use DEVELOPER_DIR pointing to Xcode 16.4 (the release CI toolchain).' >&2
    echo 'For local diagnostics only, make app LOCAL_DEPLOYMENT_TARGET=12.0 explicitly opts into a higher local minimum; do not distribute that build as macOS 11-compatible.' >&2
    exit 1
fi
