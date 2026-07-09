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

# `printf '----\n…'` makes bash read the leading `--` as an end-of-options marker and abort with
# "invalid option" — so the diagnostic dump only ever failed on the failure path, where it was needed.
# `printf '%s\n' ----` sidesteps it.
_dump() { printf '%s\n' "----" "$1" "----"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; _dump "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; _dump "$1" ;; *) pass "$3" ;; esac; }

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

# (degrade) issue number known but no cache + forced cache source -> WARN, never an error.
# Changed in GH-27: this used to be `info`, which meant an unevaluated check scored as a passing one.
# The Stop hook consumed that as "all clear" while two issues sat done-but-open. A check that could not
# run must say so at a severity a human reads. Still never errors, still exit 0.
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-104-x.md" 104 "Active"
out="$(run_check cache)"   # no cache file written
assert_contains "$out" "issue #104 state unavailable" "(degrade) flags the unevaluated doc when no state source"
assert_contains "$out" "sync NOT evaluated" "(degrade) says plainly that it did not evaluate"
assert_contains "$out" "errors=0 warns=1 info=0" "(degrade) is a WARN, not an info — unevaluated != passing"

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


# ==================================================================================================
# GH-27 — the check used to stop watching a doc at the moment it completed.
#
# Both leaks below were LIVE in this repo while the 14 tests above were passing. The suite encoded the
# check's behavior, not its purpose. Cases marked NEGATIVE CONTROL matter more than the positives: a
# "fix" that warns on everything, or one that starts blocking, would sail through every positive test.
# ==================================================================================================

# --- LEAK 1: doc reached 3-COMPLETED, issue still OPEN --------------------------------------------
# The check scanned 2-WORKING only. Direction (a) recommends `git mv ... 3-COMPLETED/`; the moment the
# operator complies, the doc leaves scope and its open issue is never mentioned again. The remediation
# the check recommends is what blinded it. Reproduced GH-15 (doc completed 2026-07-08, #15 still open).
new_sandbox
write_doc "$SBOX/PROJECT/3-COMPLETED/GH-901-done.md" 901 "Completed — shipped and verified"
printf '901\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "doc is in 3-COMPLETED but issue #901 is still OPEN" "(leak-1) completed doc + open issue is flagged"
assert_contains "$out" "gh issue close 901" "(leak-1) names the exact remediation command"
assert_contains "$out" "errors=0 warns=1 info=0" "(leak-1) is a warn, never an error"

# --- NEGATIVE CONTROL for leak 1: the fully reconciled end state must be silent --------------------
# Without this, a "fix" that warns on every doc in 3-COMPLETED passes the test above.
new_sandbox
write_doc "$SBOX/PROJECT/3-COMPLETED/GH-902-done.md" 902 "Completed — shipped and verified"
printf '902\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "errors=0 warns=0 info=0" "(leak-1 NEG) completed doc + closed issue is fully reconciled: silent"

# --- LEAK 2: status prose says done, lead word says otherwise -------------------------------------
# Verbatim from GH-12: `Active — Phases 1-4 complete ... Ready to close to 3-COMPLETED.` while #12 was
# OPEN. Direction (b) keys on the LEAD word ("active") and stops. Every human reads that as done.
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-903-handoff.md" 903 \
  "Active — Phases 1-4 complete + final consult passed; 42/42 + 6/6. Ready to close to 3-COMPLETED."
printf '903\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "declares it is ready to close but issue #903 is still OPEN" "(leak-2) hand-off phrase beats the lead word"
assert_contains "$out" "errors=0 warns=1 info=0" "(leak-2) is a warn, never an error"

# --- NEGATIVE CONTROL for leak 2: genuinely-in-progress work must not be nagged --------------------
# This is the failure mode that gets a check disabled by an irritated operator. "Phase 0 complete" is a
# progress note, not a hand-off; the lead-word anchor exists precisely to let it through.
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-904-wip.md" 904 \
  "Active — Phase 0 complete, Phase 1 in progress; more work to do before this is done"
printf '904\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "errors=0 warns=0 info=0" "(leak-2 NEG) live work with a mid-status 'complete' is not flagged"

# --- NEGATIVE CONTROL: a completed doc with no gh_issue is not our business ------------------------
new_sandbox
write_doc "$SBOX/PROJECT/3-COMPLETED/untracked-plan.md" - "Completed"
printf '905\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "errors=0 warns=0 info=0" "(NEG) completed doc without gh_issue produces no finding"

# --- Direction (a) still works after the rewrite (regression guard) -------------------------------
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-906-x.md" 906 "Active"
printf '906\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #906 is CLOSED but the doc is still in 2-WORKING" "(regress) direction (a) survives the 3-COMPLETED pass"
assert_contains "$out" "git mv" "(regress) direction (a) still names the git mv"

# --- Both buckets in one run: two independent findings, no cross-talk ------------------------------
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-907-a.md" 907 "Active"
write_doc "$SBOX/PROJECT/3-COMPLETED/GH-908-b.md" 908 "Completed"
printf '907\tCLOSED\n908\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
out="$(run_check cache)"
assert_contains "$out" "issue #907 is CLOSED but the doc is still in 2-WORKING" "(both) 2-WORKING drift found"
assert_contains "$out" "doc is in 3-COMPLETED but issue #908 is still OPEN" "(both) 3-COMPLETED drift found"
assert_contains "$out" "errors=0 warns=2 info=0" "(both) exactly two warns, no double-counting"

# --- The wrap trigger: a live lookup must PERSIST what it fetched ----------------------------------
# The Stop hook reads the cache with PDDA_ISSUE_SYNC_SOURCE=cache and makes no network call. `run` used
# `auto` (live gh) and threw the result away, so the cache never existed and the hook reported
# "all clear" over real drift. Stub gh on PATH to keep this hermetic.
new_sandbox
write_doc "$SBOX/PROJECT/2-WORKING/GH-909-x.md" 909 "Active"
STUB="$SBOX/stub"; mkdir -p "$STUB"
cat > "$STUB/gh" <<'STUBEOF'
#!/usr/bin/env bash
# Minimal `gh issue list --json number,state --jq ...` stub. Any other invocation is not our business.
case "$*" in
  *"issue list"*) printf '909\tOPEN\n910\tCLOSED\n' ;;
  *) exit 1 ;;
esac
STUBEOF
chmod +x "$STUB/gh"

[ -f "$SBOX/.pdda-gh-state.tsv" ] && fail "(cache) precondition: cache must not exist yet" || pass "(cache) precondition: no cache file"

out="$(PATH="$STUB:$PATH" run_check auto)"
if [ -f "$SBOX/.pdda-gh-state.tsv" ]; then pass "(cache) a live lookup writes .pdda-gh-state.tsv"; else fail "(cache) live lookup did not write the cache"; fi
assert_contains "$(cat "$SBOX/.pdda-gh-state.tsv" 2>/dev/null)" "909" "(cache) cache holds the fetched rows"

# ...and the next OFFLINE run evaluates from that cache instead of skipping.
out="$(run_check cache)"
assert_absent "$out" "state unavailable" "(cache) offline run after a live one evaluates instead of skipping"

# --- GUARDRAIL: still warn-only, even in full mode, even with the new findings ---------------------
new_sandbox
write_doc "$SBOX/PROJECT/3-COMPLETED/GH-911-done.md" 911 "Completed"
printf '911\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
MODE=full run_check cache >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then pass "(guardrail) 3-COMPLETED drift never blocks: exit 0 in full mode"; else fail "(guardrail) exited $rc in full mode"; fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
