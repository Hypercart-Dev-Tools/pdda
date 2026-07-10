#!/usr/bin/env bash
# Test: the opt-in, default-off PreToolUse router-read gate (GH-23 P4b).
#
# This gate is the only thing in PDDA that ACTS rather than recommends, so the assertions that matter
# most are the ones proving it stays out of the way: default off, narrowly scoped, and fail-open on
# every path where it cannot actually establish that ROUTER.md went unread.
#
# A gate that blocks on a guess is worse than no gate. It would be the first thing anyone turns off.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
GATE="$REPO_ROOT/SKILLS/PDDA-hook/scripts/pdda-router-read-gate.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_eq()       { [ "$1" = "$2" ] && pass "$3" || fail "$3 (expected '$2', got '$1')"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '%s\n' "----" "$1" "----" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)" ;; *) pass "$3" ;; esac; }

ALLOW=0
BLOCK=2

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

new_repo() {  # <pdda?>  — creates $SBOX/repo, $SBOX/t.jsonl
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-gate.XXXXXX")"
  mkdir -p "$SBOX/repo/PROJECT/2-WORKING"
  ( cd "$SBOX/repo" && git init -q && git config user.email t@e && git config user.name t )
  [ "${1:-pdda}" = "pdda" ] && printf '# PDDA\n' > "$SBOX/repo/PROJECT/PDDA.md"
  : > "$SBOX/t.jsonl"
}

# A transcript line recording one tool_use, in the shape Claude Code writes.
tx_read()  { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"%s"}}]}}\n' "$1" >> "$SBOX/t.jsonl"; }
tx_skill() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"%s"}}]}}\n' "$1" >> "$SBOX/t.jsonl"; }
tx_noise() { printf '{"type":"assistant","message":{"content":[{"type":"text","text":"thinking about ROUTER.md"}]}}\n' >> "$SBOX/t.jsonl"; }

# Run the gate. $1=tool, $2=file (repo-relative unless absolute), rest from env.
run_gate() {  # <tool> <relpath> [transcript-override]
  local tool="$1" rel="$2" tr="${3-$SBOX/t.jsonl}"
  local fp="$rel"; case "$rel" in /*) ;; *) fp="$SBOX/repo/$rel" ;; esac
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s"},"transcript_path":"%s","cwd":"%s"}' \
    "$tool" "$fp" "$tr" "$SBOX/repo" | bash "$GATE" 2>"$SBOX/err"
}
err() { cat "$SBOX/err" 2>/dev/null; }

# --- DEFAULT OFF: the single most important assertion ----------------------------------------------
# No lever file, no env var -> the gate must be invisible even on a governed doc with no router read.
new_repo
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "default-off: a governed doc with no router read is allowed"
assert_eq "$(err)" "" "default-off: the gate is completely silent"

# --- enabled by lever file, router never read -> BLOCK ----------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "lever on + router unread -> blocks"
assert_contains "$(err)" "has not read ROUTER.md" "block message names the cause"
assert_contains "$(err)" "invoke the /pdda skill" "block message leads with the cheap remedy"
assert_contains "$(err)" "PDDA_ROUTER_GATE=0" "block message says how to turn it off"

# --- enabled by env var alone (no lever file) ------------------------------------------------------
new_repo
rc=0; PDDA_ROUTER_GATE=1 run_gate Edit "ROADMAP.md" || rc=$?
assert_eq "$rc" "$BLOCK" "PDDA_ROUTER_GATE=1 enables the gate without a lever file"

# --- PDDA_ROUTER_GATE=0 always wins over the lever file --------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
rc=0; PDDA_ROUTER_GATE=0 run_gate Edit "CHANGELOG.md" || rc=$?
assert_eq "$rc" "$ALLOW" "PDDA_ROUTER_GATE=0 overrides the lever file"

# --- satisfied by reading ROUTER.md -----------------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_read "$SBOX/repo/ROUTER.md"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "a Read of ROUTER.md satisfies the gate"

# --- satisfied by invoking /pdda, which is what directive 1 actually asks for -----------------------
# Blocking an agent that did exactly what the reminder told it to do would be perverse.
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_skill "pdda"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "invoking the /pdda skill satisfies the gate"

new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_skill "someplugin:pdda"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "a plugin-namespaced pdda skill satisfies the gate"

# --- NEGATIVE: a DIFFERENT pdda-prefixed skill must NOT satisfy it ----------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_skill "pdda-eod"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "the wrap skill (pdda-eod) does not count as reading the router"

# --- NEGATIVE: merely mentioning ROUTER.md in prose is not reading it -------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_noise
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "a text mention of ROUTER.md is not evidence of a Read"

# --- NEGATIVE: a Read of a DIFFERENT file does not satisfy it ---------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_read "$SBOX/repo/AGENTS.md"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "reading AGENTS.md alone does not satisfy the router gate"

# --- SCOPE: only PROJECT/**, ROADMAP.md, CHANGELOG.md ----------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
for f in src/main.py README.md utils/pdda/pdda.sh AGENTS.md; do
  run_gate Edit "$f"; rc=$?
  assert_eq "$rc" "$ALLOW" "out of scope: $f is never gated"
done

# --- SCOPE: ROUTER.md itself is never gated ---------------------------------------------------------
# Otherwise the only file that satisfies the gate would be unfixable while the gate is on.
new_repo; : > "$SBOX/repo/.pdda-router-gate"
run_gate Edit "ROUTER.md"; rc=$?
assert_eq "$rc" "$ALLOW" "ROUTER.md itself is never gated (it is the way out)"

# --- SCOPE: only Write and Edit ---------------------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
run_gate Write "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "Write is gated"
for t in Read Bash Grep NotebookEdit; do
  run_gate "$t" "PROJECT/2-WORKING/X.md"; rc=$?
  assert_eq "$rc" "$ALLOW" "tool $t is not gated"
done

# --- SCOPE: a non-PDDA repo is never gated, even with the lever present -----------------------------
# One global registration must be safe to leave in place across every repo on the machine.
new_repo none; : > "$SBOX/repo/.pdda-router-gate"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "a repo without PROJECT/PDDA.md is never gated"
assert_eq "$(err)" "" "a non-PDDA repo produces no noise"

# ==================================================================================================
# FAIL-OPEN. The gate is the one component in PDDA that acts rather than recommends, so every path on
# which it cannot establish "the router was not read" must allow the write and SAY it could not tell.
# This is GH-23 / GH-27 / BUG-001b turned back on the enforcement layer: a check that could not run
# must not report a result — and for a gate, "reporting a result" means blocking.
# ==================================================================================================

# --- missing transcript ------------------------------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
run_gate Edit "PROJECT/2-WORKING/X.md" "$SBOX/does-not-exist.jsonl"; rc=$?
assert_eq "$rc" "$ALLOW" "fail-open: an unreadable transcript allows the write"
assert_contains "$(err)" "could not evaluate" "fail-open: it says it could not evaluate"
assert_absent "$(err)" "BLOCKED" "fail-open: it does not pretend to have blocked"

# --- transcript path absent from the payload --------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"},"cwd":"%s"}' \
  "$SBOX/repo/PROJECT/2-WORKING/X.md" "$SBOX/repo" | bash "$GATE" 2>"$SBOX/err"; rc=$?
assert_eq "$rc" "$ALLOW" "fail-open: a payload with no transcript_path allows the write"
assert_contains "$(err)" "could not evaluate" "fail-open: no-transcript path explains itself"

# --- empty payload ------------------------------------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
rc=0; printf '' | bash "$GATE" 2>"$SBOX/err" || rc=$?
assert_eq "$rc" "$ALLOW" "fail-open: an empty payload allows the write"

# --- malformed payload --------------------------------------------------------------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
rc=0; printf 'not json at all' | bash "$GATE" 2>"$SBOX/err" || rc=$?
assert_eq "$rc" "$ALLOW" "fail-open: a malformed payload allows the write"

# --- jq absent ----------------------------------------------------------------------------------------
# Simulate by handing the gate a PATH with no jq on it.
new_repo; : > "$SBOX/repo/.pdda-router-gate"
mkdir -p "$SBOX/emptybin"
rc=0
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"},"transcript_path":"%s","cwd":"%s"}' \
  "$SBOX/repo/PROJECT/2-WORKING/X.md" "$SBOX/t.jsonl" "$SBOX/repo" \
  | env PATH="$SBOX/emptybin:/usr/bin:/bin" bash "$GATE" 2>"$SBOX/err" || rc=$?
if command -v jq >/dev/null 2>&1 && [ -x /usr/bin/jq ]; then
  pass "jq lives in /usr/bin here; skipping the no-jq simulation (it would still find jq)"
else
  assert_eq "$rc" "$ALLOW" "fail-open: no jq on PATH allows the write"
  assert_contains "$(err)" "jq not installed" "fail-open: names jq as the missing dependency"
fi

# --- a corrupt transcript is not evidence of anything -------------------------------------------------
# The subtlest case, and the one the first draft of this gate got wrong. "jq found no Read of ROUTER.md"
# and "jq could not read the file" produce the same empty output — but only the first is evidence. A
# truncated final line (an interrupted session) would otherwise block every edit for the rest of the day.
new_repo; : > "$SBOX/repo/.pdda-router-gate"
printf 'garbage not json\n' > "$SBOX/t.jsonl"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "fail-open: an unparseable transcript allows the write"
assert_contains "$(err)" "could not be parsed" "fail-open: a parse failure is not read as 'router unread'"

# --- ...but an EMPTY, well-formed transcript IS evidence ---------------------------------------------
# This is the boundary. Nothing was read because nothing happened yet — that is a real answer, not a
# failure to answer, and it must block. Without this the fail-open above would swallow the whole gate.
new_repo; : > "$SBOX/repo/.pdda-router-gate"
: > "$SBOX/t.jsonl"
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$BLOCK" "an empty but valid transcript is evidence the router was never read"

# --- a transcript with a truncated LAST line still parses what came before ----------------------------
new_repo; : > "$SBOX/repo/.pdda-router-gate"
tx_read "$SBOX/repo/ROUTER.md"
printf '{"type":"assistant","message":{"conte' >> "$SBOX/t.jsonl"   # interrupted mid-write
run_gate Edit "PROJECT/2-WORKING/X.md"; rc=$?
assert_eq "$rc" "$ALLOW" "a truncated transcript never blocks (parse failure OR the Read is found)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
