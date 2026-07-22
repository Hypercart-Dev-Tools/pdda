#!/usr/bin/env bash
# Test: _pdda_gov_resolve_ref's per-name cache fallback (GH-48 round 5) — a cksum-key collision, or a
# cache entry that was simply never written (a stand-in for a partial/total batch-build failure), must
# each fall back to a fresh single-name lookup rather than silently reporting a real file dead. Unit-style
# (sources the functions directly and seeds the cache by hand) because both scenarios need a
# pre-populated cache dir, which the full `pdda.sh governance` subprocess builds internally and doesn't
# accept as external input.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

# Extract just the pure functions under test (glob-escape, cache-key, resolve-ref) — sourcing pdda.sh
# itself would run its dispatcher.
FUNCS="$(mktemp)"
awk '/^_pdda_gov_glob_escape\(\)/,0' "$PDDA" | awk '/^}/{print;c++;if(c==3)exit;next}{print}' > "$FUNCS"

SBOX="$(mktemp -d)"
cleanup() { rm -rf "$SBOX" "$FUNCS"; }
trap cleanup EXIT

mkdir -p "$SBOX/utils/pdda"
: > "$SBOX/utils/pdda/real-target.md"

resolve() {
  bash -c '
    PDDA_REPO_ROOT="$1"
    source "$2"
    _pdda_gov_resolve_ref "$3" "$1" "$4"
  ' _ "$SBOX" "$FUNCS" "$1" "$2"
}

# --- a genuine cksum-key collision must fall back, not report a real file dead ----------------------
CACHE1="$(mktemp -d)"
key="$(bash -c 'source "$1"; _pdda_gov_cache_key "$2"' _ "$FUNCS" "real-target.md")"
printf '%s' "some-other-name.md" > "$CACHE1/$key.name"   # a DIFFERENT name occupying this key's slot
printf '%s' "/nonexistent/path"   > "$CACHE1/$key.path"
result="$(resolve "real-target.md" "$CACHE1")"
if [ -f "$result" ]; then
  pass "a colliding cache entry for a different name falls back and still resolves the real file (GH-48)"
else
  fail "a colliding cache entry for a different name falls back and still resolves the real file (GH-48) (got [$result])"
fi
rm -rf "$CACHE1"

# --- a valid but never-populated cache dir (stand-in for a partial/total batch-build failure) --------
CACHE2="$(mktemp -d)"
result="$(resolve "real-target.md" "$CACHE2")"
if [ -f "$result" ]; then
  pass "a valid but empty cache dir (simulated batch-build failure) falls back and still resolves the real file (GH-48)"
else
  fail "a valid but empty cache dir (simulated batch-build failure) falls back and still resolves the real file (GH-48) (got [$result])"
fi
rm -rf "$CACHE2"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
