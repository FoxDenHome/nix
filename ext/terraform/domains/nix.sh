#!/usr/bin/env bash
set -euo pipefail

rdir="$(dirname "$(realpath "$0")")"
nixdir="$(realpath "$rdir/../../..")"

cd "$rdir"
rm -f result
nix build "$nixdir#dnsRecords.json"
jq -n --arg json "$(jq .external result)" '{"json":$json}'
rm -f result
