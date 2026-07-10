#!/usr/bin/env bash
# Canonical source for the PDDA-hook skill's OPT-IN, DEFAULT-OFF PreToolUse gate (GH-23 P4b).
#
# The SessionStart reminder's directive 1 ("read ROUTER.md / invoke /pdda") is the only directive that
# is both expensive and unverifiable — which is exactly why agents drop it. Every other directive names
# a command whose output proves it ran. This gate makes directive 1 verifiable: an edit to a governed
# doc is refused if nothing in this session ever opened the router.
#
# It is DEFAULT OFF. Enable per repo with a `.pdda-router-gate` file, or per invocation with
# PDDA_ROUTER_GATE=1. PDDA_ROUTER_GATE=0 always wins, so an operator can turn it off without deleting
# the lever file. Same convention as `.pdda-quad` / PDDA_QUAD.
#
# FAIL-OPEN, ALWAYS. This is the whole lesson of GH-23, GH-27 and BUG-001b pointed back at itself: a
# check that could not run must not report a result. If jq is missing, or the transcript is unreadable,
# or the payload is not what we expect, this gate has NO EVIDENCE that the router went unread — so it
# allows the write and says on stderr that it could not evaluate. It never blocks on a guess. The one
# thing worse than an unenforced directive is a gate that refuses edits for reasons it cannot explain.
#
# Wiring (PreToolUse, matcher "Write|Edit") is written ONLY to the operator's own ~/.claude/settings.json
# or a repo's untracked .claude/settings.local.json — never a repo's committed .claude/settings.json.
# See SKILLS/PDDA-hook/SKILL.md.

set -u

# Claude Code hooks: exit 0 allows, exit 2 blocks and feeds stderr back to the model.
ALLOW=0
BLOCK=2

allow_unevaluated() {  # <reason>
  printf 'pdda-router-read-gate: could not evaluate (%s) — allowing the write.\n' "$1" >&2
  exit "$ALLOW"
}

command -v jq >/dev/null 2>&1 || allow_unevaluated "jq not installed"

payload="$(cat)"
[ -n "$payload" ] || allow_unevaluated "empty hook payload"

tool_name="$(printf '%s' "$payload"   | jq -r '.tool_name          // empty' 2>/dev/null)"
file_path="$(printf '%s' "$payload"   | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
transcript="$(printf '%s' "$payload"  | jq -r '.transcript_path     // empty' 2>/dev/null)"
cwd="$(printf '%s' "$payload"         | jq -r '.cwd                 // empty' 2>/dev/null)"

case "$tool_name" in
  Write|Edit) ;;
  *) exit "$ALLOW" ;;            # not ours to police; silent, this fires on every tool call
esac
[ -n "$file_path" ] || exit "$ALLOW"

root="$(cd "${cwd:-.}" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${cwd:-$PWD}")"

# Not a PDDA repo -> nothing to govern. Silent: the same registration is meant to sit safely in
# ~/.claude/settings.json across every repo on the machine.
[ -f "$root/PROJECT/PDDA.md" ] || exit "$ALLOW"

# --- lever: default OFF ---------------------------------------------------------------------------
gate_on=0
[ -f "$root/.pdda-router-gate" ] && gate_on=1
case "${PDDA_ROUTER_GATE:-}" in
  1) gate_on=1 ;;
  0) gate_on=0 ;;
esac
[ "$gate_on" -eq 1 ] || exit "$ALLOW"

# --- scope: only the docs PDDA actually governs ----------------------------------------------------
# Make the file path repo-relative. The two sides can disagree about symlinks — `git rev-parse` reports
# a PHYSICAL root while the hook payload's file_path is whatever the caller typed, so on macOS a repo
# under /tmp yields root=/private/tmp/... and file_path=/tmp/.... A naive prefix strip then silently
# fails, every governed doc looks out of scope, and the gate becomes an elaborate no-op that still
# reports success. Resolve both sides physically, and keep the logical form as a fallback for a path
# whose parent directory does not exist yet (a Write creating a new subtree).
phys() { ( cd "$1" 2>/dev/null && pwd -P ) || printf '%s' "$1"; }

root_phys="$(phys "$root")"

# A relative file_path is relative to the session's cwd, not to wherever this hook happens to run.
case "$file_path" in
  /*) file_full="$file_path" ;;
  *)  file_full="${cwd:-$PWD}/$file_path" ;;
esac

file_dir="$(dirname "$file_full")"
file_abs="$(phys "$file_dir")/$(basename "$file_full")"

# Scope is decided on the RESOLVED path, never on the raw string. `PROJECT/../../etc/passwd` matches the
# glob `PROJECT/*` while pointing nowhere near this repo; deciding on the string would let the gate refuse
# writes to files it does not govern. A path that resolves outside the repo is simply not ours.
#
# If the parent directory does not exist yet, phys() cannot resolve it and containment fails, so the gate
# allows. That is deliberate: an unresolvable path is one we cannot prove we govern. Fail-open, as ever.
case "$file_abs" in
  "$root_phys"/*) rel="${file_abs#"$root_phys"/}" ;;
  *) exit "$ALLOW" ;;
esac

case "$rel" in
  PROJECT/*|ROADMAP.md|CHANGELOG.md) ;;
  *) exit "$ALLOW" ;;
esac

# Never gate the router itself, or the reader could not satisfy the gate by fixing the router.
case "$rel" in ROUTER.md) exit "$ALLOW" ;; esac

# --- evidence: did anything this session open the router (or run the skill that reads it)? ---------
# A REGULAR file, not merely a readable one. `-r` accepted character devices, FIFOs and directories:
#   - /dev/stdin is readable, but this script already drained stdin to read its own payload, so jq saw
#     an empty stream, the scan came back empty, and the gate BLOCKED — fail-closed on a transcript it
#     never actually read. Exactly the invariant this file claims to hold, broken by one test operator.
#   - a FIFO with no writer would hang jq forever, wedging the tool call.
# Only a regular file can be scanned twice and reasoned about. Anything else is no evidence at all.
# An empty REGULAR file is still evidence, and still blocks — that is the boundary, and it is tested.
[ -n "$transcript" ] || allow_unevaluated "no transcript path in the payload"
[ -f "$transcript" ] || allow_unevaluated "transcript is not a regular file"
[ -r "$transcript" ] || allow_unevaluated "transcript is not readable"

# jq reads a JSONL stream one value at a time — no slurp, so a long session costs no extra memory.
# Two ways to satisfy directive 1, because blocking someone who did exactly what it asked is perverse:
#   - a Read of any file named ROUTER.md
#   - an invocation of the /pdda skill, which encodes the read order
#
# The two failure modes must not be confused, and conflating them is the easiest bug to write here:
#   - jq EXITS NON-ZERO (truncated final line, corrupt file) -> we learned nothing -> allow, and say so.
#   - jq SUCCEEDS and the scan is empty -> we learned the router was never opened -> block.
# `... | grep -q` collapses both into one exit status, so the scan is captured before it is matched.
if ! scan="$(
      jq -r '
        .. | objects
           | select(.type? == "tool_use")
           | if   (.name? == "Read")  then (.input.file_path? // empty)
             elif (.name? == "Skill") then ("skill:" + (.input.skill? // ""))
             else empty end
      ' "$transcript" 2>/dev/null
    )"; then
  allow_unevaluated "transcript could not be parsed"
fi

if printf '%s\n' "$scan" | grep -Eq '(^|/)ROUTER\.md$|^skill:([^:]*:)?pdda$'; then
  exit "$ALLOW"
fi

cat >&2 <<EOF
BLOCKED by pdda-router-read-gate: this session has not read ROUTER.md.

You are about to edit $rel, which PDDA governs. Nothing in this session's transcript shows
ROUTER.md being read or the /pdda skill being invoked, so the startup contract was never loaded.

Do one of these, then retry the edit:
  - invoke the /pdda skill (cheapest; it encodes the whole read order), or
  - read ROUTER.md and follow the order it gives.

This gate is opt-in and repo-local. Turn it off for one command with PDDA_ROUTER_GATE=0, or
permanently by removing $root/.pdda-router-gate.
EOF
exit "$BLOCK"
