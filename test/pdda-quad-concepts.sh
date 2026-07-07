#!/usr/bin/env bash
# Test: pdda.sh quad-concepts — the opt-in "## Quad Concepts" check + the .pdda-quad/PDDA_QUAD lever.
#
# Covers the Phase 1 QA gate:
#   - a well-formed section (1..4 bullets) passes; missing / 0 / >4 error
#   - quad_exempt: true skips the doc
#   - scope = 2-WORKING + 1-INBOX/GH-* + 3-COMPLETED; 4-MISC and non-GH inbox are OUT of scope
#   - lenient bullet char (- or *), tolerant of blank lines / HTML comments in the section
#   - the lever gates inclusion in `run` (absent when off, present when on) and resolves env->file->off
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"
LIB="$REPO_ROOT/utils/pdda/pdda-lib.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_eq()      { [ "$1" = "$2" ] && pass "$3" || fail "$3 (got '$1', want '$2')"; }
assert_contains(){ case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '%s\n' "--- output ---" "$1" "---" ;; esac; }

ROOT=""
cleanup() { [ -n "$ROOT" ] && rm -rf "$ROOT"; }
trap cleanup EXIT

new_sandbox() {
  cleanup
  ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pdda-quad.XXXXXX")"
  SBOX="$ROOT/repo"
  ACT="$ROOT/activity.jsonl"
  mkdir -p "$SBOX/PROJECT/1-INBOX" "$SBOX/PROJECT/2-WORKING" \
           "$SBOX/PROJECT/3-COMPLETED" "$SBOX/PROJECT/4-MISC"
  printf '# Roadmap\n' > "$SBOX/ROADMAP.md"
}

# seed_doc <repo-relative path> <quad-section-or-empty>  (writes minimal frontmatter + optional section)
seed_doc() {
  local rel="$1" section="$2" abs="$SBOX/$1"
  {
    printf -- '---\ntitle: T\nstatus: Active\ncreated: 2026-07-07\nupdated: 2026-07-07\nowner: t\ngoal: g\n---\n\n'
    printf -- '## Status\n\n| What was just completed | Whats next |\n|---|---|\n| a | b |\n\n'
    printf -- '%s' "$section"
  } > "$abs"
}

# run the standalone check scoped to ONE doc; echo the errors= count
quad_errors() {  # <repo-relative target>
  local out
  out="$(env PDDA_REPO_ROOT="$SBOX" PDDA_ONLY_FILE="$SBOX/$1" PDDA_ACTIVITY_LOG="$ACT" \
           bash "$PDDA" quad-concepts 2>&1)"
  printf '%s\n' "$out" | sed -n 's/.*errors=\([0-9]*\).*/\1/p' | tail -1
}
quad_output() {  # <repo-relative target>
  env PDDA_REPO_ROOT="$SBOX" PDDA_ONLY_FILE="$SBOX/$1" PDDA_ACTIVITY_LOG="$ACT" \
    bash "$PDDA" quad-concepts 2>&1
}
# exit code of the standalone check under a given mode (for the full-mode blocking assertions)
quad_rc() {  # <repo-relative target> <mode>
  env PDDA_REPO_ROOT="$SBOX" PDDA_ONLY_FILE="$SBOX/$1" PDDA_ACTIVITY_LOG="$ACT" PDDA_MODE="$2" \
    bash "$PDDA" quad-concepts >/dev/null 2>&1
  echo "$?"
}
# write a doc with an EXACT body (no auto frontmatter/status) — for raw parser fixtures
raw_doc() { printf -- '%s' "$2" > "$SBOX/$1"; }

# --- Scenario 1: well-formed section (2 bullets) passes ---
new_sandbox
seed_doc PROJECT/2-WORKING/ok.md '## Quad Concepts
- Dense docs give no orientation → a glance section
- Coverage is invisible → pain → fix bullets
'
assert_eq "$(quad_errors PROJECT/2-WORKING/ok.md)" "0" "S1: valid 2-bullet section passes"

# --- Scenario 2: missing section errors ---
seed_doc PROJECT/2-WORKING/none.md ''
assert_eq "$(quad_errors PROJECT/2-WORKING/none.md)" "1" "S2: missing section = 1 error"
assert_contains "$(quad_output PROJECT/2-WORKING/none.md)" "missing '## Quad Concepts'" "S2: missing-section message"

# --- Scenario 3: header present but zero bullets errors ---
seed_doc PROJECT/2-WORKING/empty.md '## Quad Concepts

## Next Section
- not a concept
'
assert_eq "$(quad_errors PROJECT/2-WORKING/empty.md)" "1" "S3: zero bullets = 1 error"
assert_contains "$(quad_output PROJECT/2-WORKING/empty.md)" "no bullets" "S3: no-bullets message"

# --- Scenario 4: more than 4 bullets errors ---
seed_doc PROJECT/2-WORKING/five.md '## Quad Concepts
- one
- two
- three
- four
- five
'
assert_eq "$(quad_errors PROJECT/2-WORKING/five.md)" "1" "S4: five bullets = 1 error"
assert_contains "$(quad_output PROJECT/2-WORKING/five.md)" "5 bullets (max 4" "S4: too-many message"

# --- Scenario 5: exactly 4 passes (boundary) ---
seed_doc PROJECT/2-WORKING/four.md '## Quad Concepts
- one
- two
- three
- four
'
assert_eq "$(quad_errors PROJECT/2-WORKING/four.md)" "0" "S5: exactly 4 bullets passes"

# --- Scenario 6: quad_exempt: true skips (no section, still passes) ---
{
  printf -- '---\ntitle: T\nstatus: Active\ncreated: 2026-07-07\nupdated: 2026-07-07\nowner: t\ngoal: g\nquad_exempt: true\n---\n\n'
  printf -- '## Status\n\n| What was just completed | Whats next |\n|---|---|\n| a | b |\n'
} > "$SBOX/PROJECT/2-WORKING/exempt.md"
assert_eq "$(quad_errors PROJECT/2-WORKING/exempt.md)" "0" "S6: quad_exempt: true skips the doc"

# --- Scenario 7: lenient bullet char (*) and blank line + HTML comment tolerated ---
seed_doc PROJECT/2-WORKING/star.md '## Quad Concepts

<!-- 1 to 4 key concepts -->
* one
* two
* three
'
assert_eq "$(quad_errors PROJECT/2-WORKING/star.md)" "0" "S7: * bullets + blank/comment tolerated"

# --- Scenario 8: scope — 3-COMPLETED is IN, 4-MISC is OUT, inbox GH-* IN, inbox non-GH OUT ---
seed_doc PROJECT/3-COMPLETED/done.md ''
assert_eq "$(quad_errors PROJECT/3-COMPLETED/done.md)" "1" "S8a: 3-COMPLETED in scope (missing = error)"
seed_doc PROJECT/4-MISC/misc.md ''
assert_eq "$(quad_errors PROJECT/4-MISC/misc.md)" "0" "S8b: 4-MISC out of scope (not flagged)"
seed_doc PROJECT/1-INBOX/GH-1-thing.md ''
assert_eq "$(quad_errors PROJECT/1-INBOX/GH-1-thing.md)" "1" "S8c: 1-INBOX GH-* in scope (missing = error)"
seed_doc PROJECT/1-INBOX/notes.md ''
assert_eq "$(quad_errors PROJECT/1-INBOX/notes.md)" "0" "S8d: 1-INBOX non-GH out of scope (not flagged)"

# --- Scenario 9: the lever resolves env -> .pdda-quad file -> default off ---
lever_state() {  # runs quad_is_enabled in a clean env for $SBOX
  env PDDA_REPO_ROOT="$SBOX" "$@" bash -c ". \"$LIB\"; quad_is_enabled && echo on || echo off"
}
new_sandbox
assert_eq "$(lever_state)" "off" "S9a: default (no env, no file) = off"
assert_eq "$(lever_state PDDA_QUAD=1)" "on" "S9b: PDDA_QUAD=1 = on"
assert_eq "$(lever_state PDDA_QUAD=off)" "off" "S9c: PDDA_QUAD=off = off"
printf 'on\n' > "$SBOX/.pdda-quad"
assert_eq "$(lever_state)" "on" "S9d: .pdda-quad 'on' = on"
printf '# comment\noff\n' > "$SBOX/.pdda-quad"
assert_eq "$(lever_state)" "off" "S9e: .pdda-quad 'off' (past comment) = off"
# env overrides the file
printf 'off\n' > "$SBOX/.pdda-quad"
assert_eq "$(lever_state PDDA_QUAD=1)" "on" "S9f: env overrides file"

# --- Scenario 10: lever gates inclusion in `run` ---
new_sandbox
seed_doc PROJECT/2-WORKING/ok.md '## Quad Concepts
- a → b
'
run_full() { env PDDA_REPO_ROOT="$SBOX" PDDA_ACTIVITY_LOG="$ACT" "$@" bash "$PDDA" run 2>&1; }
OFF_OUT="$(run_full)"
ON_OUT="$(run_full PDDA_QUAD=1)"
case "$OFF_OUT" in *pdda-check-quad-concepts*) fail "S10a: quad check ABSENT from run when lever off" ;; *) pass "S10a: quad check absent when lever off" ;; esac
assert_contains "$ON_OUT" "pdda-check-quad-concepts" "S10b: quad check present in run when lever on"

# ================================================================================================
# Parser-hardening edge cases (from the Codex + agy consult on Phase 1)
# ================================================================================================
new_sandbox

# --- S11: fenced code block is DATA — a fake section with 5 bullets inside a ``` block is ignored;
#          only the real 2-bullet section counts (would error at >4 if the fence were parsed). ---
raw_doc PROJECT/2-WORKING/fence.md '# T

```text
## Quad Concepts
- f1
- f2
- f3
- f4
- f5
```

## Quad Concepts
- real one
- real two
'
assert_eq "$(quad_errors PROJECT/2-WORKING/fence.md)" "0" "S11: fenced example section is skipped"

# --- S12: an h2 heading terminates the section; a bullet after it does not count ---
raw_doc PROJECT/2-WORKING/h2.md '## Quad Concepts
- a
- b
## Other
- c
- d
- e
'
assert_eq "$(quad_errors PROJECT/2-WORKING/h2.md)" "0" "S12: next h2 terminates (2 bullets, not 5)"

# --- S13: an h3 sub-heading does NOT terminate (bullets around it are still the section) ---
raw_doc PROJECT/2-WORKING/h3.md '## Quad Concepts
- a
- b
### note
- c
- d
- e
'
assert_contains "$(quad_output PROJECT/2-WORKING/h3.md)" "5 bullets (max 4" "S13: h3 does not terminate (all 5 counted -> error)"

# --- S14: duplicate "## Quad Concepts" sections do not sum; only the first (2 bullets) counts ---
raw_doc PROJECT/2-WORKING/dup.md '## Quad Concepts
- a
- b

## Quad Concepts
- c
- d
- e
'
assert_eq "$(quad_errors PROJECT/2-WORKING/dup.md)" "0" "S14: duplicate sections do not sum (first only)"

# --- S15: empty bullets ("- " with no text) do not count -> a section of only empties errors ---
raw_doc PROJECT/2-WORKING/empties.md '## Quad Concepts
-
-
'
assert_contains "$(quad_output PROJECT/2-WORKING/empties.md)" "no bullets" "S15: empty bullets do not count"

# --- S16: indented/nested bullets are not top-level; 1 top + 4 nested counts as 1 (not 5) ---
raw_doc PROJECT/2-WORKING/nested.md '## Quad Concepts
- top
  - n1
  - n2
  - n3
  - n4
'
assert_eq "$(quad_errors PROJECT/2-WORKING/nested.md)" "0" "S16: nested bullets excluded (counts 1, not 5)"

# --- S17: a blank line AFTER bullets terminates; stray bullets in later prose do not count ---
raw_doc PROJECT/2-WORKING/blankterm.md '## Quad Concepts
- a
- b
- c
- d

Some prose.
- stray one
- stray two
'
assert_eq "$(quad_errors PROJECT/2-WORKING/blankterm.md)" "0" "S17: blank after bullets terminates (4, not 6)"

# --- S18: CRLF line endings — a valid 2-bullet section still passes; a bare CR bullet does not count ---
printf -- '## Quad Concepts\r\n-\r\n- real one\r\n- real two\r\n' > "$SBOX/PROJECT/2-WORKING/crlf.md"
assert_eq "$(quad_errors PROJECT/2-WORKING/crlf.md)" "0" "S18: CRLF normalized; bare CR bullet ignored (2 valid)"

# --- S19: PDDA_MODE gating — full BLOCKS (non-zero) on a missing section; observe never blocks ---
seed_doc PROJECT/2-WORKING/miss.md ''
assert_eq "$(quad_rc PROJECT/2-WORKING/miss.md observe)" "0" "S19a: observe never blocks (rc 0)"
assert_eq "$(quad_rc PROJECT/2-WORKING/miss.md full)"    "1" "S19b: full blocks a missing section (rc 1)"
seed_doc PROJECT/2-WORKING/good.md '## Quad Concepts
- a → b
'
assert_eq "$(quad_rc PROJECT/2-WORKING/good.md full)" "0" "S19c: full passes a valid section (rc 0)"

# --- S20: blank.md is out of scope even in single-file (PDDA_ONLY_FILE) mode ---
seed_doc PROJECT/2-WORKING/blank.md ''
assert_eq "$(quad_errors PROJECT/2-WORKING/blank.md)" "0" "S20: blank.md scaffold not flagged"

# --- S21: `pdda.sh glance` rolls up title + Quad Concepts across 2-WORKING ---
new_sandbox
seed_doc PROJECT/2-WORKING/withquad.md '## Quad Concepts
- pain one → fix one
- pain two → fix two
'
seed_doc PROJECT/2-WORKING/noquad.md ''
raw_doc PROJECT/2-WORKING/emptyquad.md '## Quad Concepts

## Next
- x
'
G="$(env PDDA_REPO_ROOT="$SBOX" PDDA_ACTIVITY_LOG="$ACT" bash "$PDDA" glance 2>&1)"
assert_contains "$G" "withquad.md" "S21a: glance lists a doc with a section"
assert_contains "$G" "- pain one → fix one" "S21b: glance prints bullets, marker stripped"
assert_contains "$G" "(no ## Quad Concepts)" "S21c: glance marks a doc with no section"
assert_contains "$G" "present but empty" "S21d: glance marks an empty section"

# --- S22: glance robustness (from the consult) — metachar/quoted titles, empty 2-WORKING ---
new_sandbox
# a title with shell/format metacharacters MUST print literally (no expansion, no printf format abuse)
{
  printf -- '---\ntitle: "100%% $(whoami) `id` done"\n---\n'
  printf -- '## Quad Concepts\n- a → b\n'
} > "$SBOX/PROJECT/2-WORKING/meta.md"
G="$(env PDDA_REPO_ROOT="$SBOX" PDDA_ACTIVITY_LOG="$ACT" bash "$PDDA" glance 2>&1)"
assert_contains "$G" '100% $(whoami) `id` done' "S22a: metachar title printed literally, quotes stripped"
assert_contains "$G" "- a → b" "S22b: glance still prints bullets alongside a metachar title"

# empty PROJECT/2-WORKING → graceful message, exit 0
new_sandbox
G="$(env PDDA_REPO_ROOT="$SBOX" PDDA_ACTIVITY_LOG="$ACT" bash "$PDDA" glance 2>&1)"; RC=$?
assert_contains "$G" "no active docs" "S22c: glance on empty 2-WORKING says so"
assert_rc() { [ "$1" -eq "$2" ] && pass "$3" || fail "$3 (exit $1, want $2)"; }
assert_rc "$RC" 0 "S22d: glance exits 0 on empty 2-WORKING"

printf '\n=== pdda-quad-concepts: %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
