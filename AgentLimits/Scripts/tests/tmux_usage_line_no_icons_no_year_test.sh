#!/usr/bin/env bash
set -euo pipefail

real_home="$HOME"
script_path="${TMUX_AGENTLIMITS_USAGE_LINE:-$real_home/.local/bin/tmux-agentlimits-usage-line}"

if [[ ! -x "$script_path" ]]; then
  echo "skip: not found: $script_path"
  exit 0
fi

tmp_home="$(mktemp -d)"
cleanup() { rm -rf "$tmp_home"; }
trap cleanup EXIT

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
HOME="$tmp_home" bash "$script_path" claude >"$tmp_home/out.txt" 2>"$tmp_home/err.txt"
status=$?
set -e

if [[ $status -ne 0 ]]; then
  echo "tmux usage line script failed (exit=$status)" >&2
  cat "$tmp_home/err.txt" >&2
  exit 1
fi

out="$(cat "$tmp_home/out.txt")"
if [[ -z "$out" ]]; then
  echo "expected output, got empty" >&2
  exit 1
fi

if [[ "$out" == *$'\U0001F554'* ]]; then
  echo "output contains unexpected icon: U+1F554" >&2
  echo "output: $out" >&2
  exit 1
fi

if [[ "$out" == *$'\U0001F4C5'* ]]; then
  echo "output contains unexpected icon: U+1F4C5" >&2
  echo "output: $out" >&2
  exit 1
fi

if printf '%s' "$out" | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  echo "output contains unexpected YYYY-MM-DD date" >&2
  echo "output: $out" >&2
  exit 1
fi

echo "ok"

