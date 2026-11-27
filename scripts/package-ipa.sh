#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then echo "Usage: scripts/package-ipa.sh <device.app> <output.ipa> (package existing build; does not sign or install)"; exit 0; fi
[[ $# == 2 && -d $1 && $2 == *.ipa ]] || { echo "Provide device .app and output .ipa" >&2; exit 2; }
[[ $(uname -s) == Darwin ]] || { echo "BLOCKED: macOS required" >&2; exit 1; }
script_dir=$(cd "$(dirname "$0")" && pwd)
app=$(cd "$1" && pwd)
[[ $(basename "$app") == iPadScreenTorch.app ]] || { echo "Unexpected app name" >&2; exit 2; }
mkdir -p "$(dirname "$2")"
output=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
[[ ! -e "$output" ]] || { echo "Refusing to overwrite existing IPA: $output" >&2; exit 2; }
tmp=$(mktemp -d "${TMPDIR:-/tmp}/screen-torch.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/Payload"
cp -R "$app" "$tmp/Payload/"
(cd "$tmp" && zip -qry "$tmp/archive.ipa" Payload)
"$script_dir/verify-ipa.sh" "$tmp/archive.ipa"
cp "$tmp/archive.ipa" "$output"
echo "Created: $output"
shasum -a 256 "$output"
