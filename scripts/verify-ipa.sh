#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/verify-ipa.sh <file.ipa> (structure, arm64, iOS 15.0, signature classification, SHA256; no install)"; exit 0; fi
[[ $# == 1 && -f $1 ]] || { echo "Provide an existing IPA" >&2; exit 2; }
[[ $(uname -s) == Darwin ]] || { echo "BLOCKED: macOS/Xcode Mach-O tools required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "BLOCKED: python3 required for safe ZIP inspection" >&2; exit 1; }
ipa=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/screen-torch.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
python3 - "$ipa" "$tmp" <<'PY'
import pathlib, plistlib, stat, subprocess, sys, zipfile
ipa, destination = sys.argv[1:]
with zipfile.ZipFile(ipa) as archive:
    entries = archive.infolist()
    names = set()
    for entry in entries:
        p = pathlib.PurePosixPath(entry.filename)
        if p.is_absolute() or '..' in p.parts or '\\' in entry.filename or stat.S_ISLNK(entry.external_attr >> 16):
            raise SystemExit('Invalid ZIP path or symbolic link')
        if str(p) in names:
            raise SystemExit('Duplicate ZIP path')
        names.add(str(p))
subprocess.run(["ditto", "-x", "-k", ipa, destination], check=True)
root = pathlib.Path(destination) / 'Payload'
apps = list(root.glob('*.app'))
if len(apps) != 1 or apps[0].name != 'iPadScreenTorch.app':
    raise SystemExit('Expected exactly one iPadScreenTorch.app in Payload')
app = apps[0]
with (app / 'Info.plist').open('rb') as file:
    info = plistlib.load(file)
expected = {'CFBundleIdentifier': 'com.jason22432150.ipadscreentorch', 'MinimumOSVersion': '15.0', 'UIDeviceFamily': [2], 'CFBundleExecutable': 'iPadScreenTorch', 'UIRequiresFullScreen': True}
for key, value in expected.items():
    if info.get(key) != value:
        raise SystemExit(f'Unexpected {key}: {info.get(key)!r}')
if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
    raise SystemExit('Not an iPhoneOS device build')
if not (app / info['CFBundleExecutable']).is_file():
    raise SystemExit('Executable missing')
print('PASS: IPA structure, bundle ID, minimum OS and iPad device family')
PY
app="$tmp/Payload/iPadScreenTorch.app"
binary="$app/iPadScreenTorch"
[[ $(xcrun lipo -archs "$binary") == arm64 ]] || { echo "Expected arm64 only" >&2; exit 1; }
build=$(xcrun vtool -arch arm64 -show-build "$binary")
printf '%s\n' "$build"
printf '%s\n' "$build" | grep -Eq 'platform[[:space:]]+(IOS|2)$' || { echo "Expected iOS Mach-O platform" >&2; exit 1; }
printf '%s\n' "$build" | grep -Eq 'minos[[:space:]]+15\.0(\.0)?$' || { echo "Expected Mach-O minOS 15.0" >&2; exit 1; }
if signature=$(codesign -dv --verbose=4 "$app" 2>&1); then
    codesign --verify --deep --strict "$app"
    if printf '%s\n' "$signature" | grep -q 'Signature=adhoc'; then
        echo 'SIGNING=AD_HOC (not an Apple-provisioned install)'
    elif [[ -f "$app/embedded.mobileprovision" ]]; then
        echo 'SIGNING=SIGNED_WITH_PROFILE (device eligibility and installation not verified)'
    else
        echo 'SIGNING=SIGNED_WITHOUT_PROFILE (installation not verified)'
    fi
else
    echo 'SIGNING=UNSIGNED (not directly installable on standard iPadOS)'
fi
shasum -a 256 "$ipa"
