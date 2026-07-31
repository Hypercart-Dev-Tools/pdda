#!/usr/bin/env bash
# Test: the RELEASES.md `Iterations:` reserved band and `Milestone:` join key.
#
# Covers the two properties the contract promises (PROJECT/PDDA.md "RELEASES.md — release ledger"):
#   1. both fields are ADDITIVE — a ledger that omits them behaves exactly as before, and a ledger
#      that uses them correctly stays at errors=0 warns=0 (this is what makes the change safe to
#      sync into repos that have never heard of either field);
#   2. the admission rule is MECHANICAL — a block whose version falls inside another block's
#      reserved band warns as a duplicate, which is the whole reason the band exists.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '----\n%s\n----\n' "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf '----\n%s\n----\n' "$1" ;; *) pass "$3" ;; esac; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-releases.XXXXXX")"
}

# Writes $SBOX/RELEASES.md from stdin, then runs the check against it.
run_check() {
  cat > "$SBOX/RELEASES.md"
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_RELEASES_FILE="$SBOX/RELEASES.md" \
  PDDA_MODE=observe \
  PDDA_FORMAT=text \
    bash "$PDDA" releases 2>&1
}

run_current() {
  cat > "$SBOX/RELEASES.md"
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_RELEASES_FILE="$SBOX/RELEASES.md" \
    bash "$PDDA" releases-current 2>&1
}

# --- 1. a ledger with neither new field is untouched ---------------------------------------------
new_sandbox
out="$(run_check <<'EOF'
Release: 1.0.0
Status: Shipped
Target Date:
Codename: Bronze
Description: baseline
GH_URL:
EOF
)"
assert_contains "$out" "errors=0 warns=0 info=0" "a ledger with no Iterations/Milestone still passes clean"

# --- 2. both fields present and well-formed stay silent ------------------------------------------
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft
Milestone: Quicksilver
Description: a named arc
EOF
)"
assert_contains "$out" "errors=0 warns=0 info=0" "a valid band plus a Milestone adds no findings"

# --- 3. a malformed band warns -------------------------------------------------------------------
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0 through 0.2.4
Status: Draft
EOF
)"
assert_contains "$out" "is not a valid <lo>-<hi> version band" "a non-band Iterations value warns"

# A reversed range is malformed too — a band the containment test can't trust must not pass silently.
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.4-0.2.0
Status: Draft
EOF
)"
assert_contains "$out" "is not a valid <lo>-<hi> version band" "a reversed band warns"

# --- 4. the admission rule: a block inside another block's band is a duplicate --------------------
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft

Release: 0.2.3
Status: Draft
Description: restates what changed
EOF
)"
assert_contains "$out" "is inside the Iterations band 0.2.0-0.2.4" "an in-band block warns as a duplicate"
assert_contains "$out" "record it in CHANGELOG.md" "the duplicate warning names the right destination"

# --- 5. the band owner does not flag itself, and the next release outside it is fine --------------
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft

Release: 0.3.0
Iterations: 0.3.0-0.3.9
Status: Draft
EOF
)"
assert_contains "$out" "errors=0 warns=0 info=0" "a band owner does not flag itself and adjacent bands are clean"

# --- 6. non-numeric versions are left to human judgment ------------------------------------------
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft

Release: 0.2.1-rc1
Status: Draft
EOF
)"
assert_absent "$out" "is inside the Iterations band" "a prerelease version is not band-tested"

# --- 6b. the band OWNER is identified by line, not by version text --------------------------------
# A second block repeating the owner's own version is a genuine duplicate. Suppressing by version
# text would let it hide behind the owner; suppressing by line catches it. (Codex review, round 1.)
new_sandbox
out="$(run_check <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft

Release: 0.2.0
Status: Draft
Description: a second block reusing the band owner version
EOF
)"
assert_contains "$out" "is inside the Iterations band 0.2.0-0.2.4" "a duplicate of the band owner's own version is still caught"

# A release value with trailing whitespace must compare as its trimmed self, not fall through.
new_sandbox
out="$(printf 'Release: 0.2.0\nIterations: 0.2.0-0.2.4\nStatus: Draft\n\nRelease: 0.2.3   \nStatus: Draft\n' | run_check)"
assert_contains "$out" "is inside the Iterations band 0.2.0-0.2.4" "a trailing-space release value is still band-tested"
assert_absent "$out" "release '0.2.3   '" "the warning reports the trimmed release value"

# --- 7. a block-less ledger is a VALID state and must report exactly as clean as before -----------
# The contract's whole point is that sparse is fine, so this must not even emit an info finding —
# the guard exists only to stop the here-doc loops faking a "block near line 0" error.
new_sandbox
out="$(run_check <<'EOF'
# Major Releases

No blocks yet — a sparse ledger is a valid state.
EOF
)"
assert_contains "$out" "errors=0 warns=0 info=0" "a header-only ledger reports exactly zero findings"
assert_absent "$out" "has no version" "a block-less ledger does not fake a malformed block"

new_sandbox
out="$(printf '' | run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "a completely empty ledger reports exactly zero findings"

# --- 8. releases-current surfaces the band and the milestone -------------------------------------
new_sandbox
out="$(run_current <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft
Milestone: Quicksilver
EOF
)"
assert_contains "$out" "Iterations: 0.2.0-0.2.4" "releases-current shows the reserved band"
assert_contains "$out" "Milestone: Quicksilver" "releases-current shows the milestone join key"

# --- 9. pin the pdda_releases_list row shape ------------------------------------------------------
# The row is read POSITIONALLY by check_releases and cmd_releases_current, and no position is safe to
# extend (a field before <line> shifts it; one after it gets folded into <line> by bash's
# last-variable-absorbs-the-rest rule). So the field count is pinned here: a future addition fails
# this test and forces the author to update every reader in the same change, rather than discovering
# it as a misparsed line number. (Codex review, round 1 — blocker.)
new_sandbox
cat > "$SBOX/RELEASES.md" <<'EOF'
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft
Target Date: 2026-08-01
Codename: Quicksilver
Milestone: Q3
Description: d
GH_URL: u
Front-door reviewed: Yes
Shakedown reviewed: No
License file: Yes
EOF
row="$(
  # shellcheck disable=SC1090
  PDDA_REPO_ROOT="$SBOX" . "$REPO_ROOT/utils/pdda/pdda-lib.sh" >/dev/null 2>&1
  pdda_releases_list "$SBOX/RELEASES.md"
)"
field_count="$(printf '%s' "$row" | tr '\037' '\n' | wc -l | tr -d ' ')"
field_count=$((field_count + 1))
if [ "$field_count" -eq 12 ]; then
  pass "pdda_releases_list emits exactly 12 fields per row (readers are positional)"
else
  fail "pdda_releases_list field count changed: expected 12, got $field_count — update check_releases AND cmd_releases_current"
fi

# ...and that <line> is still LAST, since that is the record terminator both readers rely on.
last_field="$(printf '%s' "$row" | tr '\037' '\n' | tail -1)"
case "$last_field" in
  1) pass "the final row field is still the block's line number" ;;
  *) fail "the final row field is '$last_field', expected the line number 1" ;;
esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
