#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/build.sh [Debug|Release] (unsigned arm64 device build, no install)"; exit 0; fi
cd "$(dirname "$0")/.."
config=${1:-Debug}
[[ $config == Debug || $config == Release ]] || { echo "Invalid configuration" >&2; exit 2; }
scripts/check-env.sh
xcodebuild -project iPadScreenTorch.xcodeproj -scheme iPadScreenTorch -configuration "$config" -destination 'generic/platform=iOS' -derivedDataPath "build/device-$config" CODE_SIGNING_ALLOWED=NO build
