#!/usr/bin/env bash
# Test: `pdda-sync.sh push` never reports a stale target as a clean skip, and never overwrites a
# target without a backup (GH-59).
#
# Reproduces the live failure that motivated the fix: push writes a file, the target copy is changed
# out-of-band (a relay containment revert, a `git checkout`, a manual edit), and every later push
# reports `skip` with a clean summary while the target stays stale forever — because the skip branch
# tested the SOURCE hash against the last stamp without ever consulting the target's content.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
# Overridable so the pre-fix binary can be pointed at to prove this test actually catches GH-59.
SYNC="${PDDA_SYNC_BIN:-$REPO_ROOT/utils/pdda/pdda-sync.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

dump() { printf '%s\n' "--- output ---" "$1" "--------------"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; dump "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; dump "$1" ;; *) pass "$3" ;; esac; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

SRC="" TGT="" SYNCTMP=""

# A miniature canonical repo (its own git root + manifest) and a target repo.
new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-sync-div.XXXXXX")"
  SRC="$SBOX/canonical"; TGT="$SBOX/target"; SYNCTMP="$SBOX/synctmp"
  mkdir -p "$SRC/utils/pdda" "$SRC/PROJECT" "$TGT/utils/pdda" "$TGT/PROJECT" "$SYNCTMP"

  printf 'v1\n' > "$SRC/PROJECT/PDDA.md"
  printf 'runtime v1\n' > "$SRC/utils/pdda/pdda.sh"
  # Manifest the real expander understands; sync-machinery excludes mirror the shipped conf.
  cat > "$SRC/utils/pdda/pdda-sync-manifest.conf" <<'CONF'
dir     utils/pdda
file    PROJECT/PDDA.md
exclude utils/pdda/pdda-sync.sh
exclude utils/pdda/pdda-manifest.sh
exclude utils/pdda/pdda-sync-manifest.conf
CONF
  # pdda-sync.sh derives SOURCE_DIR from its OWN location (not an env var), so the sandbox canonical
  # repo must carry its own copy of the sync machinery and be driven through that copy.
  cp "$REPO_ROOT/utils/pdda/pdda-manifest.sh" "$SRC/utils/pdda/pdda-manifest.sh"
  cp "$REPO_ROOT/utils/pdda/pdda-lib.sh"      "$SRC/utils/pdda/pdda-lib.sh"
  cp "$SYNC"                                   "$SRC/utils/pdda/pdda-sync.sh"
  chmod +x "$SRC/utils/pdda/pdda-sync.sh"

  (
    cd "$SRC" || exit 1
    git init -q; git config user.name "PDDA Test"; git config user.email "pdda@example.com"
    git add -A; git commit -q -m "seed"
  ) || exit 1

  cp "$SRC/PROJECT/PDDA.md" "$TGT/PROJECT/PDDA.md"
  cp "$SRC/utils/pdda/pdda.sh" "$TGT/utils/pdda/pdda.sh"
}

run_push() {
  PDDA_SYNC_TMP="$SYNCTMP" bash "$SRC/utils/pdda/pdda-sync.sh" push "$TGT" "$@" 2>&1
}

advance_source() { printf '%s\n' "$1" > "$SRC/PROJECT/PDDA.md"; ( cd "$SRC" && git add -A && git commit -q -m "advance" ); }

# --- 1. baseline: source advances, target updates, and a stamp is recorded ------------------------
new_sandbox
advance_source "v2"
out="$(run_push)"
assert_contains "$out" "PROJECT/PDDA.md" "an advanced source updates the target"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "v2" ] \
  && pass "the target holds the new content" || fail "the target was not updated"

# --- 2. THE BUG: target changed out-of-band is reported, not silently skipped ---------------------
# Source has NOT advanced since the stamp; the target was reverted behind sync's back.
printf 'reverted-out-of-band\n' > "$TGT/PROJECT/PDDA.md"
out="$(run_push)"
assert_contains "$out" "diverged" "a target changed out-of-band is reported as diverged"
assert_contains "$out" "diverged=1" "the summary line carries a non-zero diverged count"
assert_contains "$out" "left DIVERGED" "a non-zero diverged count also warns in words"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "reverted-out-of-band" ] \
  && pass "the diverged target is preserved, not clobbered (local edits survive)" \
  || fail "the diverged target was overwritten without being asked"

# Running again must STILL report it — the stamp stays anchored, so divergence can't launder itself
# into "current" on the next pass.
out="$(run_push)"
assert_contains "$out" "diverged=1" "divergence is still reported on a subsequent run"

# --- 3. --force-resync overwrites it, and backs it up first ---------------------------------------
out="$(run_push --force-resync)"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "v2" ] \
  && pass "--force-resync restores the target to canonical" || fail "--force-resync did not overwrite"
if find "$SYNCTMP/pdda-sync-backups" -name 'PDDA.md' 2>/dev/null | grep -q .; then
  pass "the overwritten diverged copy was backed up"
else
  fail "no backup was written for the overwritten diverged copy"
fi
out="$(run_push)"
assert_contains "$out" "diverged=0" "once resynced, the target reports zero diverged"

# --- 4. an overwrite with NO stamp is backed up too ------------------------------------------------
# The recovery path: the state file is cleared (which is what the bug forced operators to do), so
# there is no `last` to compare against. The old code took the no-backup branch here and clobbered.
new_sandbox
advance_source "v2"
run_push >/dev/null
rm -rf "$SYNCTMP/pdda-sync-state"
printf 'precious-local-content\n' > "$TGT/PROJECT/PDDA.md"
out="$(run_push)"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "v2" ] \
  && pass "with no stamp, an out-of-sync target is brought to canonical" \
  || fail "with no stamp, the target was not updated"
# grep -r over the directory, NOT `find | xargs grep` — with no matching files xargs still runs grep
# with zero file args, which falls through to reading stdin and can report a false success.
if [ -d "$SYNCTMP/pdda-sync-backups" ] && grep -rq 'precious-local-content' "$SYNCTMP/pdda-sync-backups" 2>/dev/null; then
  pass "the clobbered content was backed up even with no prior stamp"
else
  fail "content was overwritten with NO backup when no stamp existed (the GH-59 second defect)"
fi

# --- 5. a genuine no-op is still a silent skip ----------------------------------------------------
# The fix must not turn every unchanged file into noise.
new_sandbox
out="$(run_push)"
assert_contains "$out" "diverged=0" "an already-current target reports zero diverged"
assert_absent "$out" "left DIVERGED" "an already-current target does not warn"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
