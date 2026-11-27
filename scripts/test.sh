#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/test.sh <simulator-UDID> [Debug|Release] (XCTest + XCUITest)"; exit 0; fi
cd "$(dirname "$0")/.."
id=${1:-}
config=${2:-Debug}
[[ $id =~ ^[0-9A-Fa-f-]{36}$ ]] || { echo "Specify an available simulator UDID from check-env.sh" >&2; exit 2; }
[[ $config == Debug || $config == Release ]] || { echo "Invalid configuration" >&2; exit 2; }
scripts/check-env.sh
xcodebuild -project iPadScreenTorch.xcodeproj -scheme iPadScreenTorch -configuration "$config" -destination "platform=iOS Simulator,id=$id" -derivedDataPath "build/simulator-$config" -parallel-testing-enabled NO -enableCodeCoverage YES test
