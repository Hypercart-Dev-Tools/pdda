#!/usr/bin/env bash
# Test: pdda_json_escape (utils/pdda/pdda-lib.sh) — the node-present path is byte-for-byte unchanged,
# and the node-absent pure-shell fallback (GH-48) produces valid, round-trippable JSON for the cases
# that matter: backslash/quote, whitespace escapes, and arbitrary C0 control bytes.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
LIB="$REPO_ROOT/utils/pdda/pdda-lib.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

assert_eq() { [ "$1" = "$2" ] && pass "$3" || fail "$3 (expected [$2], got [$1])"; }

# The escaped output is only ever consumed embedded in a JSON string literal (pdda_json_line wraps it
# in double quotes) - validate the same way: wrap, then round-trip through python's json module.
round_trip() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)["x"])' <<PY
{"x": "$1"}
PY
}

# GH-48 round 2: an earlier version of this test used PATH=/usr/bin:/bin to simulate "no node" - but
# node is commonly installed at /usr/bin/node on some systems, so that could silently exercise the
# node-present branch instead. Use a genuinely empty PATH (the fallback is pure bash builtins, so it
# needs none) and assert "command -v node" really fails inside the subprocess before trusting output.
run_nodeless() {
  env -i PATH= /bin/bash -c '
    if command -v node >/dev/null 2>&1; then
      printf "NODE_STILL_ON_PATH\n"
      exit 1
    fi
    . "$1" 2>/dev/null
    pdda_json_escape "$2"
  ' _ "$LIB" "$1"
}

# --- node-present path is unchanged (this machine has node; skip gracefully if it ever doesn't) ----
if command -v node >/dev/null 2>&1; then
  out="$(bash -c '. "$1"; pdda_json_escape "$2"' _ "$LIB" 'a "quoted" \path\ line
tab	end')"
  assert_eq "$out" 'a \"quoted\" \\path\\ line\ntab\tend' \
    "node-present path escapes quote/backslash/newline/tab as expected"
fi

# --- node-absent fallback: same printable/whitespace case must match the node-present output --------
out="$(run_nodeless 'a "quoted" \path\ line
tab	end')"
assert_eq "$out" 'a \"quoted\" \\path\\ line\ntab\tend' \
  "node-absent fallback matches the node-present output for quote/backslash/newline/tab, node confirmed absent"

# --- node-absent fallback: round-trips through a real JSON parser -----------------------------------
decoded="$(round_trip "$out")"
expected="$(printf 'a "quoted" \\path\\ line\ntab\tend')"
assert_eq "$decoded" "$expected" \
  "node-absent fallback output round-trips through json.loads back to the original string"

# --- node-absent fallback: backspace, form feed, and an arbitrary C0 control byte -------------------
raw="$(printf 'a\x01\x02\bb\x1fc')"
out="$(run_nodeless "$raw")"
assert_eq "$out" 'a\u0001\u0002\bb\u001fc' \
  "node-absent fallback escapes arbitrary C0 control bytes as backslash-u00XX, node confirmed absent"
decoded="$(round_trip "$out")"
assert_eq "$decoded" "$raw" \
  "the C0-control-byte escape round-trips through json.loads back to the original bytes"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
