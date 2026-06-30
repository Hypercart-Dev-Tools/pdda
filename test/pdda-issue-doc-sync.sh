#!/usr/bin/env bash
# Test: pdda.sh issue-doc-sync
#
# Covers the two drift directions plus the gh-absent degrade path, all offline and deterministic by
# forcing PDDA_ISSUE_SYNC_SOURCE (so the test never touches the network or the real tree/activity log):
#   (a) issue CLOSED + doc still in 2-WORKING        -> warn (recommend git mv to 3-COMPLETED)
#   (b) issue OPEN   + doc status declares itself done -> warn (reconcile status / close issue)
#   degrade) issue number known but no state source   -> info/skip (never errors)
#   clean)   issue OPEN + doc status "Active"          -> no findings
#   filename fallback) no gh_issue key, GH-<n>- name  -> number still resolved
#   never-blocks)      warn-only even in full mode     -> exit 0
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
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-ids.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/2-WORKING" "$SBOX/PROJECT/3-COMPLETED"
}

# write_doc <path> <gh_issue|-> <status>
write_doc() {
  local gh_line=""
  [ "$2" = "-" ] || gh_line="gh_issue: $2"
  cat > "$1" <<EOF
---
title: Fixture
status: $3
created: 2026-06-29
updated: 2026-06-29
owner: test
$gh_line
goal: fixture doc
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | proceed |
EOF
}

# run_check <source> -> echoes findings; exit code preserved in $?
run_check() {
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_WORKING_DIR="$SBOX/PROJECT/2-WORKING" \
  PDDA_COMPLETED_DIR="$SBOX/PROJECT/3-COMPLETED" \
  PDDA_GH_STATE_CACHE="$SBOX/.pdda-gh-state.tsv" \
  PDDA_ACTIVITY_LOG="$SBOX/activity.jsonl" \
  PDDA_ISSUE_SYNC_SOURCE="$1" \
  PDDA_MODE="${MODE:-observe}" \
  PDDA_FORMAT=text \
  bash "$PDDA" issue-doc-sync 2>&1
}

# (a) CLOSED issue, doc still in 2-WORKING -> warn + git mv recommendation to 3-COMPLETED
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-101-thing.md" 101 "Active — building"
printf '101\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #101 is CLOSED" "(a) flags closed-issue-still-in-WORKING"
assert_contains "$out" "git mv" "(a) emits a git mv recommendation"
assert_contains "$out" "PROJECT/3-COMPLETED/GH-101-thing.md" "(a) targets 3-COMPLETED"
assert_contains "$out" "warns=1 info=0" "(a) exactly one warn, no info"

# (b) OPEN issue, doc declares itself done -> warn to reconcile
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-102-done.md" 102 "Complete — shipped all phases"
printf '102\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #102 is still OPEN" "(b) flags done-doc-but-open-issue"
assert_contains "$out" "status reads 'complete'" "(b) names the offending status word"
assert_contains "$out" "warns=1 info=0" "(b) exactly one warn, no info"

# (b-negative) "Active — Phase 0 complete" must NOT trip the leadword test (word appears mid-status)
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-103-active.md" 103 "Active — Phase 0 complete, Phase 1 next"
printf '103\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "errors=0 warns=0 info=0" "(b-neg) mid-status 'complete' does not false-flag"

# (degrade) issue number known but no cache + forced cache source -> info/skip, never an error
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-104-x.md" 104 "Active"
out="$(run_check cache)"   # no cache file written
assert_contains "$out" "issue #104 state unavailable" "(degrade) emits an info skip when no state source"
assert_contains "$out" "errors=0 warns=0 info=1" "(degrade) info-only, zero warns/errors"

# (filename fallback) no gh_issue frontmatter, GH-<n>- filename still yields the number
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-105-nokey.md" - "Active"
printf '105\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #105 is CLOSED" "(fallback) resolves issue number from GH-<n>- filename"

# (filename fallback, bare) GH-<n>.md with NO description and NO gh_issue key must still resolve
# (regression for the agy QA-review nit: '.md' must be stripped before the dash split).
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-106.md" - "Active"
printf '106\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #106 is CLOSED" "(fallback-bare) resolves bare GH-<n>.md filename (no description)"

# (non-GH doc) a working doc with neither gh_issue nor GH- name is silently skipped
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/PLAIN-DOC.md" - "Active"
printf '999\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "errors=0 warns=0 info=0" "(non-GH) untracked doc produces no findings"

# (never-blocks) warn-only even in full mode -> exit 0 despite a live warn
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-106-closed.md" 106 "Active"
printf '106\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
MODE=full run_check cache >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then pass "(never-blocks) exits 0 in full mode despite a warn"; else fail "(never-blocks) exited $rc in full mode"; fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
