#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/install-device.sh <file.ipa> (verify and print manual installation guidance; no device changes)"; exit 0; fi
[[ $# == 1 ]] || { echo "Provide an IPA path" >&2; exit 2; }
script_dir=$(cd "$(dirname "$0")" && pwd)
"$script_dir/verify-ipa.sh" "$1"
cat <<'GUIDE'
No installation was attempted. For stock iPadOS, use Xcode with your personal Team and trusted device, or a compatible personal signing tool. An unsigned or ad-hoc IPA is not directly installable on stock iPadOS. See docs/INSTALLATION.md. Back up the device before installation; do not upload credentials or provisioning profiles to Git.
GUIDE
