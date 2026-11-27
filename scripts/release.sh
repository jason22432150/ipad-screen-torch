#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/release.sh (unsigned Release device build, local IPA and build evidence; does not publish)"; exit 0; fi
cd "$(dirname "$0")/.."
[[ -z $(git status --porcelain) ]] || { echo "Commit or stash changes before producing release evidence" >&2; exit 2; }
scripts/build.sh Release
mkdir -p build/release
ipa=build/release/iPadScreenTorch-0.1.0-unsigned.ipa
scripts/package-ipa.sh build/device-Release/Build/Products/Release-iphoneos/iPadScreenTorch.app "$ipa"
scripts/verify-ipa.sh "$ipa" | tee build/release/verify-ipa.txt
(cd build/release && shasum -a 256 iPadScreenTorch-0.1.0-unsigned.ipa > SHA256SUMS.txt)
python3 - "$(git rev-parse HEAD)" "$(xcodebuild -version)" "$(xcrun --sdk iphoneos --show-sdk-version)" <<'PY'
import json, pathlib, plistlib, sys
commit, xcode, sdk = sys.argv[1:]
path = pathlib.Path('build/release/verify-ipa.txt')
signing = next((line.split('=', 1)[1] for line in path.read_text().splitlines() if line.startswith('SIGNING=')), 'UNKNOWN')
with open('build/device-Release/Build/Products/Release-iphoneos/iPadScreenTorch.app/Info.plist', 'rb') as f:
    bundle = plistlib.load(f)
info = {'commit': commit, 'xcode': xcode, 'sdk': sdk, 'minimumOS': bundle['MinimumOSVersion'], 'version': bundle['CFBundleShortVersionString'], 'build': bundle['CFBundleVersion'], 'signing': signing, 'deviceTest': 'NOT RUN', 'releaseGate': 'NOT PASSED'}
pathlib.Path('build/release/build-info.json').write_text(json.dumps(info, indent=2) + '\n')
PY
echo 'Local unsigned artifact only. No GitHub Release created; device and native test gates remain separate.'
