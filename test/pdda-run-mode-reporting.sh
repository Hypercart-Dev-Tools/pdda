#!/usr/bin/env bash
# Test: `pdda.sh run` reports what it FOUND, independent of what it BLOCKED on (GH-14 Phase 2 / BUG-001b).
#
# pdda_gated_exit forces every check's return value to 0 outside `full` mode. That is correct — observe
# and light must never fail a build. But cmd_run inferred "all checks passed" from that same zero, so a
# run of nothing but errors closed with a success line. The mode gate is supposed to stop the run from
# BLOCKING, not from REPORTING.
#
# Same family as GH-23 (a dead-ref scan that could not see .sh) and GH-27 (an issue check that could not
# reach gh): a check that could not run — or could not block — must never be scored as one that passed.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
_dump() { printf '%s\n' "----" "$1" "----"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; _dump "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; _dump "$1" ;; *) pass "$3" ;; esac; }
assert_eq()       { [ "$1" = "$2" ] && pass "$3" || fail "$3 (expected '$2', got '$1')"; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

# A sandbox whose ROUTER.md omits a real dispatcher subcommand -> check_governance records an ERROR
# (subcommand drift is the one governance finding that is severity error, so it exercises the gate).
new_sandbox_with_error() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-runmode.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/1-INBOX" "$SBOX/PROJECT/2-WORKING" "$SBOX/PROJECT/3-COMPLETED" "$SBOX/PROJECT/4-MISC"
  for d in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do : > "$SBOX/PROJECT/$d/blank.md"; done
  printf '# ROUTER.md\n\nNo subcommands documented here at all.\n' > "$SBOX/ROUTER.md"
  printf '# ROADMAP.md\n' > "$SBOX/ROADMAP.md"
  printf '# CHANGELOG.md\n' > "$SBOX/CHANGELOG.md"
}

# A sandbox with a ROUTER.md naming every dispatcher subcommand -> no governance errors.
new_clean_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-runmode.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/1-INBOX" "$SBOX/PROJECT/2-WORKING" "$SBOX/PROJECT/3-COMPLETED" "$SBOX/PROJECT/4-MISC"
  for d in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do : > "$SBOX/PROJECT/$d/blank.md"; done
  {
    printf '# ROUTER.md\n\n'
    awk '/case "\$cmd" in/{c=1;next} c&&/^esac/{c=0} c' "$PDDA" \
      | grep -oE '^[[:space:]]*[a-z][a-z-]*(\|[a-z-]+)*\)' \
      | tr -d ' )' | tr '|' '\n' | sort -u \
      | while IFS= read -r s; do [ -n "$s" ] && printf -- '- `pdda.sh %s`\n' "$s"; done
  } > "$SBOX/ROUTER.md"
  printf '# ROADMAP.md\n' > "$SBOX/ROADMAP.md"
  printf '# CHANGELOG.md\n' > "$SBOX/CHANGELOG.md"
}

# PDDA_ISSUE_SYNC_SOURCE=cache keeps `run` off the network: issue-doc-sync would otherwise shell out to
# `gh` once per invocation, making this suite slow and dependent on GitHub being reachable.
run_in() {  # <mode>
  PDDA_REPO_ROOT="$SBOX" PDDA_MODE="$1" PDDA_FORMAT=text PDDA_ISSUE_SYNC_SOURCE=cache \
    bash "$PDDA" run 2>&1
  printf '\n__RC__=%s\n' "$?"
}
rc_of() { printf '%s\n' "$1" | sed -n 's/^__RC__=//p'; }

# --- observe mode: errors present ------------------------------------------------------------------
# THE BUG. Pre-fix this printed "all checks passed" and exited 0. The exit 0 is correct and must stay.
new_sandbox_with_error
out="$(run_in observe)"
assert_absent   "$out" "all checks passed" "observe: a run with errors never claims all checks passed"
assert_contains "$out" "error(s) found, not blocking in observe mode" "observe: the run names the errors it found"
assert_contains "$out" "pdda-check-governance" "observe: the run names which check reported them"
assert_eq "$(rc_of "$out")" "0" "observe: still exits 0 — reporting a finding must not start blocking"

# --- light mode: identical semantics ---------------------------------------------------------------
new_sandbox_with_error
out="$(run_in light)"
assert_absent   "$out" "all checks passed" "light: a run with errors never claims all checks passed"
assert_contains "$out" "not blocking in light mode" "light: the run says why it is not failing"
assert_eq "$(rc_of "$out")" "0" "light: still exits 0"

# --- full mode: unchanged, errors block ------------------------------------------------------------
new_sandbox_with_error
out="$(run_in full)"
assert_absent   "$out" "all checks passed" "full: a run with errors never claims all checks passed"
assert_contains "$out" "failures:" "full: the run reports failures"
assert_eq "$(rc_of "$out")" "1" "full: exits non-zero — the mode gate still blocks"

# --- NEGATIVE CONTROL: a genuinely clean run still says so, in every mode --------------------------
# Without this, "never print all checks passed" would be trivially satisfiable by never printing it.
for mode in observe light full; do
  new_clean_sandbox
  out="$(run_in "$mode")"
  assert_contains "$out" "all checks passed" "$mode: a clean run still reports all checks passed"
  assert_absent   "$out" "not blocking" "$mode: a clean run does not mention non-blocking errors"
  assert_eq "$(rc_of "$out")" "0" "$mode: a clean run exits 0"
done

# --- NEGATIVE CONTROL: warnings alone are not errors ------------------------------------------------
# A warn is the house-style "recommend, never act" signal. It must not flip the summary line, or every
# advisory finding would read as a failure and the distinction would collapse.
new_clean_sandbox
printf '\nA dead link to [nothing](PROJECT/2-WORKING/NOPE.md).\n' >> "$SBOX/ROUTER.md"
out="$(run_in observe)"
assert_contains "$out" "dead reference" "warn-only: the dead reference is still reported"
assert_contains "$out" "all checks passed" "warn-only: warnings do not turn a passing run into an error run"
assert_eq "$(rc_of "$out")" "0" "warn-only: exits 0"

# --- doc-ready is gated on findings, not on the (gated) exit code -----------------------------------
# PDDA.md: the LLM review "should spend time only on docs that passed basic structural hygiene". Gating
# on EXIT_CODE alone meant observe-mode runs sent error-laden docs to the LLM anyway.
new_sandbox_with_error
out="$(run_in observe)"
assert_contains "$out" "skipped pdda-doc-ready" "observe: doc-ready is skipped when errors were found"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
