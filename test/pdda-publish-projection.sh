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
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
