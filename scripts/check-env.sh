#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/check-env.sh (read-only Xcode/SDK/simulator inventory)"; exit 0; fi
[[ $(uname -s) == Darwin ]] || { echo "BLOCKED: macOS with Xcode required" >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "BLOCKED: Xcode CLI unavailable" >&2; exit 1; }
xcodebuild -version
xcodebuild -showsdks
xcrun --sdk iphoneos --show-sdk-version
xcrun simctl list devices available
