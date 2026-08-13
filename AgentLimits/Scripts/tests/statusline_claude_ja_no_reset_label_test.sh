#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/agentlimits_statusline_claude.sh"

tmp_home="$(mktemp -d)"
cleanup() { rm -rf "$tmp_home"; }
trap cleanup EXIT

# Prepare a minimal snapshot under a temporary HOME so the test doesn't depend on real user data.
snapshot_dir="$tmp_home/Library/Group Containers/group.com.falcon.agentlimits/Library/Application Support/AgentLimit"
mkdir -p "$snapshot_dir"

cat > "$snapshot_dir/usage_snapshot_claude.json" <<'JSON'
{
  "primaryWindow": {
    "usedPercent": 12.3,
    "resetAt": "2030-01-02T03:04:05Z",
    "limitWindowSeconds": 18000
  },
  "secondaryWindow": {
    "usedPercent": 45.6,
    "resetAt": "2030-01-08T03:04:05Z",
    "limitWindowSeconds": 604800
  },
  "fetchedAt": "2030-01-01T00:00:00Z",
  "displayMode": "used"
}
JSON

set +e
HOME="$tmp_home" bash "$SCRIPT_PATH" -ja >"$tmp_home/out.txt" 2>"$tmp_home/err.txt"
status=$?
set -e

if [[ $status -ne 0 ]]; then
  echo "statusline script failed (exit=$status)" >&2
  cat "$tmp_home/err.txt" >&2
  exit 1
fi

out="$(cat "$tmp_home/out.txt")"
if [[ -z "$out" ]]; then
  echo "expected output, got empty" >&2
  exit 1
fi

if [[ "$out" == *"リセット時間"* ]]; then
  echo "output contains unexpected label: リセット時間" >&2
  echo "output: $out" >&2
  exit 1
fi

echo "ok"

