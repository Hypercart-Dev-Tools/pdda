#!/usr/bin/env bash
# Test: install.sh's git-pulse projection (publish_registry_projection).
# Verifies the multi-device rollup is (a) written, normalized to repo name with NO absolute paths, when a
# git-pulse checkout is present, and (b) fail-open — an install on a machine without git-pulse still
# succeeds and writes the local registry, and never creates a stray projection.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
INSTALL="$REPO_ROOT/install.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '----\n%s\n----\n' "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf '----\n%s\n----\n' "$1" ;; *) pass "$3" ;; esac; }

SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-publish.XXXXXX")"
cleanup() { [ -n "$SBOX" ] && { chmod -R u+w "$SBOX" 2>/dev/null; rm -rf "$SBOX"; }; }
trap cleanup EXIT

git_init() { ( cd "$1" && git init -q && git config user.name t && git config user.email t@e ); }

# --- Case 1: git-pulse present -> normalized projection is published ------------------------------------
TARGET="$SBOX/myproj-repo"; mkdir -p "$TARGET"; git_init "$TARGET"
GP="$SBOX/gitpulse-repo";   mkdir -p "$GP";     git_init "$GP"          # the .git makes it a publish target
REG="$SBOX/registry.tsv"
XDG="$SBOX/xdg"; mkdir -p "$XDG/git-pulse"; printf 'device_id="test-device"\n' > "$XDG/git-pulse/config.sh"

XDG_CONFIG_HOME="$XDG" PDDA_REGISTRY="$REG" PDDA_GITPULSE_DIR="$GP" \
  bash "$INSTALL" --mode observe "$TARGET" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "install exits 0 with git-pulse present" || fail "install exit $rc with git-pulse present"

PROJ="$GP/pdda/registry-test-device.tsv"
[ -f "$PROJ" ] && pass "projection written under git-pulse device id" || fail "projection file missing ($PROJ)"
body="$(cat "$PROJ" 2>/dev/null)"
assert_contains "$body" "absolute paths intentionally omitted" "projection carries the maintainer header"
assert_contains "$body" "myproj-repo" "projection lists the installed repo by bare name"
# No data row (non-comment line) may contain a slash -> proves paths are stripped.
data_with_slash="$(grep -v '^#' "$PROJ" 2>/dev/null | grep '/' || true)"
[ -z "$data_with_slash" ] && pass "no absolute path leaks into any data row" || { fail "a data row contains '/'"; printf '%s\n' "$data_with_slash"; }
assert_absent "$body" "$SBOX" "projection contains no sandbox/filesystem path"
# Local registry still authoritative and DOES keep the absolute path.
assert_contains "$(cat "$REG")" "$TARGET" "local registry keeps the absolute target path"

# --- Case 2: no git-pulse -> fail-open (install still works, nothing published) ------------------------
TARGET2="$SBOX/other-repo"; mkdir -p "$TARGET2"; git_init "$TARGET2"
REG2="$SBOX/registry2.tsv"
MISSING="$SBOX/no-such-gitpulse"   # never created -> no .git -> publish must skip

XDG_CONFIG_HOME="$XDG" PDDA_REGISTRY="$REG2" PDDA_GITPULSE_DIR="$MISSING" \
  bash "$INSTALL" --mode observe "$TARGET2" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "install exits 0 with git-pulse absent (fail-open)" || fail "install exit $rc with git-pulse absent"
assert_contains "$(cat "$REG2")" "$TARGET2" "local registry written even when git-pulse absent"
[ ! -e "$MISSING" ] && pass "no stray projection dir created when git-pulse absent" || fail "publish wrote into a non-git-pulse path"

# --- Case 3: atomic write — a failed generation leaves the prior projection intact (Codex review) -------
# git-pulse's concurrent sync must never see a half-written file; publish writes temp-then-mv. Force the
# write to fail (read-only projection dir) and prove the previous good file survives and install stays 0.
TARGET3="$SBOX/third-repo"; mkdir -p "$TARGET3"; git_init "$TARGET3"
GP3="$SBOX/gitpulse3"; mkdir -p "$GP3/pdda"; git_init "$GP3"
REG3="$SBOX/registry3.tsv"
SENTINEL="$GP3/pdda/registry-test-device.tsv"
printf 'PRIOR-GOOD-PROJECTION\n' > "$SENTINEL"
chmod 0555 "$GP3/pdda"   # read-only dir -> the temp write (and thus the mv) cannot occur

XDG_CONFIG_HOME="$XDG" PDDA_REGISTRY="$REG3" PDDA_GITPULSE_DIR="$GP3" \
  bash "$INSTALL" --mode observe "$TARGET3" >/dev/null 2>&1
rc=$?
chmod 0755 "$GP3/pdda" 2>/dev/null
[ "$rc" -eq 0 ] && pass "install exits 0 when projection dir is unwritable (fail-open)" || fail "install exit $rc on unwritable projection dir"
assert_contains "$(cat "$SENTINEL")" "PRIOR-GOOD-PROJECTION" "prior projection survives a failed atomic write"
[ -z "$(ls "$GP3"/pdda/*.tmp.* 2>/dev/null)" ] && pass "no leftover .tmp file after a failed write" || fail "stray .tmp file remained"
assert_contains "$(cat "$REG3")" "$TARGET3" "local registry still written despite publish failure"

# --- Case 4: autodetect — no PDDA_GITPULSE_DIR override; resolve git-pulse from config.sh sync_repo_dir --
# GH-7: when the git-pulse checkout isn't at the hardcoded default, install must still find it via
# git-pulse's own config (sync_repo_dir) instead of silently skipping the projection.
TARGET4="$SBOX/fourth-repo"; mkdir -p "$TARGET4"; git_init "$TARGET4"
GP4="$SBOX/gitpulse4-elsewhere"; mkdir -p "$GP4"; git_init "$GP4"   # NOT at the default ~/.config/git-pulse/repo
REG4="$SBOX/registry4.tsv"
XDG4="$SBOX/xdg4"; mkdir -p "$XDG4/git-pulse"
printf 'device_id="test-device"\nsync_repo_dir="%s"\n' "$GP4" > "$XDG4/git-pulse/config.sh"

# PDDA_GITPULSE_DIR intentionally UNSET (env -u) -> exercises the autodetection path, not the override.
env -u PDDA_GITPULSE_DIR XDG_CONFIG_HOME="$XDG4" PDDA_REGISTRY="$REG4" \
  bash "$INSTALL" --mode observe "$TARGET4" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "install exits 0 with autodetected git-pulse path" || fail "install exit $rc (autodetect)"
PROJ4="$GP4/pdda/registry-test-device.tsv"
[ -f "$PROJ4" ] && pass "projection auto-published to sync_repo_dir from git-pulse config" || fail "autodetected projection missing ($PROJ4)"
assert_contains "$(cat "$PROJ4" 2>/dev/null)" "fourth-repo" "autodetected projection lists the installed repo"

# --- Case 5-8: GH-28 — warn_stale_projection_destination() -----------------------------------------
# The projection write above (cases 1-4) can succeed on disk while never reaching origin, if the
# git-pulse checkout itself isn't being committed/pushed by whatever job owns that. A real device was
# found with 5 rows sitting uncommitted for over a week because its git-pulse sync job had stalled —
# and every install reported success throughout. These cases pin the fix: warn, once, best-effort,
# never blocking, only when the destination is actually dirty or behind its upstream.
WARN_RE='warn: git-pulse'

# A git-pulse checkout cloned from its own local bare "origin" -> gives it a real upstream so
# ahead/behind is meaningful, with zero network access.
gitpulse_with_upstream() {  # <dir-name> -> prints working-checkout path
  local bare="$SBOX/$1-origin.git" work="$SBOX/$1"
  git init -q --bare "$bare"
  git clone -q "$bare" "$work"
  ( cd "$work" && git config user.email t@e && git config user.name t \
    && printf 'seed\n' > seed.txt && git add seed.txt && git commit -qm seed && git push -q origin HEAD )
  printf '%s\n' "$work"
}

# Case 5: dirty destination (the projection write itself leaves pdda/ uncommitted) -> must warn.
TARGET5="$SBOX/fifth-repo"; mkdir -p "$TARGET5"; git_init "$TARGET5"
GP5="$(gitpulse_with_upstream gitpulse5)"
REG5="$SBOX/registry5.tsv"
out5="$(PDDA_REGISTRY="$REG5" PDDA_GITPULSE_DIR="$GP5" bash "$INSTALL" --mode observe "$TARGET5" 2>&1)"
n=$(printf '%s' "$out5" | grep -cE "$WARN_RE.*uncommitted" || true)
[ "$n" -gt 0 ] && pass "dirty projection destination (uncommitted pdda/) triggers a warning" \
  || fail "dirty projection destination did not warn as expected"

# Case 6: negative control — commit + push that same write, then re-check with the function directly
# (not another install.sh run: re-running would re-register with a fresh timestamp and genuinely
# re-dirty the file, which is a property of registration, not of this warning check).
( cd "$GP5" && git add pdda && git commit -qm sync && git push -q origin HEAD )
out6="$(bash -c "$(sed -n '/^warn_stale_projection_destination() {/,/^}/p' "$INSTALL")"'
  say() { printf "%s\n" "$*"; }
  warn_stale_projection_destination "$1"
' _ "$GP5")"
n=$(printf '%s' "$out6" | grep -cE "$WARN_RE" || true)
[ "$n" -eq 0 ] && pass "clean, current git-pulse checkout: no stale/dirty warning" \
  || fail "clean, current git-pulse checkout unexpectedly warned"

# Case 7: behind destination — a second clone pushes ahead, the checkout under test fetches (so it
# knows, without install.sh itself ever making a network call) that it's behind -> must warn.
BARE7="$SBOX/gitpulse5-origin.git"  # same origin as case 5/6's checkout
OTHER7="$SBOX/gitpulse7-other-clone"
git clone -q "$BARE7" "$OTHER7"
( cd "$OTHER7" && git config user.email t@e && git config user.name t \
  && printf 'more\n' > more.txt && git add more.txt && git commit -qm more && git push -q origin HEAD )
( cd "$GP5" && git fetch -q origin )
out7="$(bash -c "$(sed -n '/^warn_stale_projection_destination() {/,/^}/p' "$INSTALL")"'
  say() { printf "%s\n" "$*"; }
  warn_stale_projection_destination "$1"
' _ "$GP5")"
n=$(printf '%s' "$out7" | grep -cE "$WARN_RE.*behind" || true)
[ "$n" -gt 0 ] && pass "git-pulse checkout behind its upstream triggers a warning" \
  || fail "git-pulse checkout behind its upstream did not warn"

# Case 8: guardrail — none of the above ever fail the install itself (still installs, runtime present).
[ -d "$TARGET5/utils/pdda" ] && pass "install still completes despite a dirty/behind git-pulse checkout" \
  || fail "install did not complete when the git-pulse checkout was dirty/behind"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
