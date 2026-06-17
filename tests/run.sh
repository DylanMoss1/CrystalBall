#!/usr/bin/env bash
# Runs the whole Crystal Ball regression suite (stdlib only):
#   - Lua  : query-builder golden tests, under the real CrystalBall.lua
#   - Python: watcher contract (fake searcher) + GPU-backed pipeline/semantics
#             (those auto-skip if Immolate isn't built / no GPU).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
rc=0

LUA="$(command -v lua || command -v luajit || true)"
if [[ -n "$LUA" ]]; then
  for t in tests/lua/test_*.lua; do
    echo "== Lua: $t ($LUA) =="
    CB_REPO_ROOT="$ROOT" "$LUA" "$t" || rc=1
    echo
  done
else
  echo "== Lua tests == SKIP (no lua/luajit on PATH)"
fi

echo
echo "== Python (watcher contract + pipeline + semantics) =="
python3 -m unittest discover -s tests -t tests -v || rc=1

exit $rc
