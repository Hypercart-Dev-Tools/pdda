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

# --- 2b. dry-run reports the divergence but writes nothing -----------------------------------------
before_state="$(cat "$SYNCTMP/pdda-sync-state/"*.tsv 2>/dev/null)"
before_baks="$(find "$SYNCTMP/pdda-sync-backups" -type f 2>/dev/null | LC_ALL=C sort)"
out="$(run_push --dry-run)"
assert_contains "$out" "diverged=1" "dry-run still reports the divergence"
assert_contains "$out" "nothing written" "dry-run says nothing was written"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "reverted-out-of-band" ] \
  && pass "dry-run leaves the target untouched" || fail "dry-run modified the target"
[ "$(cat "$SYNCTMP/pdda-sync-state/"*.tsv 2>/dev/null)" = "$before_state" ] \
  && pass "dry-run leaves the state file untouched" || fail "dry-run rewrote the state file"
[ "$(find "$SYNCTMP/pdda-sync-backups" -type f 2>/dev/null | LC_ALL=C sort)" = "$before_baks" ] \
  && pass "dry-run writes no backup" || fail "dry-run wrote a backup"

# --force-resync must ALSO write nothing under --dry-run.
out="$(run_push --dry-run --force-resync)"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "reverted-out-of-band" ] \
  && pass "dry-run --force-resync leaves the target untouched" || fail "dry-run --force-resync overwrote the target"
[ "$(find "$SYNCTMP/pdda-sync-backups" -type f 2>/dev/null | LC_ALL=C sort)" = "$before_baks" ] \
  && pass "dry-run --force-resync writes no backup" || fail "dry-run --force-resync wrote a backup"

# --- 3. --force-resync overwrites it, and backs THAT content up -----------------------------------
out="$(run_push --force-resync)"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "v2" ] \
  && pass "--force-resync restores the target to canonical" || fail "--force-resync did not overwrite"
# Assert the backup holds the DIVERGED bytes specifically. Merely finding some PDDA.md under the
# backup root passes even when --force-resync backed up nothing, because an earlier step in this
# same sandbox may already have left one there.
if [ -d "$SYNCTMP/pdda-sync-backups" ] && grep -rq 'reverted-out-of-band' "$SYNCTMP/pdda-sync-backups" 2>/dev/null; then
  pass "the overwritten diverged content is what got backed up"
else
  fail "--force-resync overwrote the diverged content without backing that content up"
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

# --- 6. a ROUTINE update must NOT consume a backup slot -------------------------------------------
# prune_backups keeps only PDDA_SYNC_BACKUPS (default 5) snapshot dirs per target. Backing up an
# in-sync target on every ordinary release would evict the snapshots that hold genuinely
# unrecoverable local content within five releases — trading the data loss this guards against for a
# slower one. So: target byte-identical to its stamp => overwrite with NO backup, and labelled
# `updated`, not `updated+bak`. (Codex review, round 1.)
new_sandbox
advance_source "v2"
run_push >/dev/null                     # target now in sync AND stamped
advance_source "v3"
out="$(run_push)"
[ "$(cat "$TGT/PROJECT/PDDA.md")" = "v3" ] \
  && pass "a routine update still lands" || fail "a routine update did not land"
if [ -d "$SYNCTMP/pdda-sync-backups" ] && grep -rq 'v2' "$SYNCTMP/pdda-sync-backups" 2>/dev/null; then
  fail "a routine in-sync update burned a backup slot (evicts real diverged snapshots)"
else
  pass "a routine in-sync update consumes no backup slot"
fi
assert_absent "$out" "updated+bak PROJECT/PDDA.md" "a routine update is labelled 'updated', not 'updated+bak'"

# ...and the label must track the ACTUAL backup: an unstamped target that gets backed up must be
# reported as updated+bak, not laundered as a plain `updated`.
new_sandbox
advance_source "v2"
run_push >/dev/null
rm -rf "$SYNCTMP/pdda-sync-state"
printf 'unstamped-local\n' > "$TGT/PROJECT/PDDA.md"
out="$(run_push)"
assert_contains "$out" "updated+bak PROJECT/PDDA.md" "an unstamped overwrite is labelled updated+bak because it DID back up"
if [ -d "$SYNCTMP/pdda-sync-backups" ] && grep -rq 'unstamped-local' "$SYNCTMP/pdda-sync-backups" 2>/dev/null; then
  pass "the unstamped local content is in the backup the label claims"
else
  fail "labelled updated+bak but the content is not in any backup"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
