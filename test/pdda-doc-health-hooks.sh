#!/usr/bin/env bash
# Test: the two-tier doc-health hooks
#   tier 1 — pdda-edit-doc-hook.sh   (PostToolUse single-file lint)   [Phase 3]
#   tier 2 — pdda-stop-doc-health.sh (Stop full-scan, cached gh-state) [Phase 4]
#
# Every scenario runs in a throwaway sandbox (overridden PDDA_* dirs) so nothing touches the real tree,
# the real activity log, or the network. The cardinal property under test is FAIL-OPEN: a hook must
# ALWAYS exit 0 (it can never block an edit or a stop), while still surfacing findings for visibility.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
EDIT_HOOK="$REPO_ROOT/utils/pdda/pdda-edit-doc-hook.sh"
STOP_HOOK="$REPO_ROOT/utils/pdda/pdda-stop-doc-health.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_rc0()      { [ "$RC" -eq 0 ] && pass "$1" || { fail "$1 (exit $RC, must be 0 / fail-open)"; printf '%s\n' "$HOOK_OUT"; }; }
assert_has()      { case "$HOOK_OUT" in *"$1"*) pass "$2" ;; *) fail "$2 (missing: $1)"; printf '%s\n' "$HOOK_OUT" ;; esac; }
assert_absent()   { case "$HOOK_OUT" in *"$1"*) fail "$2 (unexpected: $1)"; printf '%s\n' "$HOOK_OUT" ;; *) pass "$2" ;; esac; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT
new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-hook.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/2-WORKING" "$SBOX/PROJECT/1-INBOX" "$SBOX/PROJECT/3-COMPLETED"
  printf '# Roadmap\n' > "$SBOX/ROADMAP.md"
}
sbox_env() {
  printf 'PDDA_REPO_ROOT=%s PDDA_WORKING_DIR=%s PDDA_INBOX_DIR=%s PDDA_COMPLETED_DIR=%s PDDA_ROADMAP=%s PDDA_ACTIVITY_LOG=%s PDDA_GH_STATE_CACHE=%s' \
    "$SBOX" "$SBOX/PROJECT/2-WORKING" "$SBOX/PROJECT/1-INBOX" "$SBOX/PROJECT/3-COMPLETED" \
    "$SBOX/ROADMAP.md" "$SBOX/activity.jsonl" "$SBOX/.pdda-gh-state.tsv"
}
good_doc() {
  cat > "$1" <<EOF
---
title: OK
status: Active
created: 2026-06-29
updated: 2026-06-29
owner: test
goal: fine
---

## Status

| What was just completed | What's next |
|---|---|
| a | b |
EOF
}

# run the edit hook with a payload naming <file_path>; capture combined output + exit code
run_edit_hook() {
  HOOK_OUT="$(printf '%s' "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$1\"}}" \
    | env $(sbox_env) bash "$EDIT_HOOK" 2>&1)"
  RC=$?
}

printf '== tier 1: PostToolUse edit hook ==\n'

# 1. non-doc file -> instant no-op (exit 0, no lint output)
new_sandbox
run_edit_hook "$SBOX/utils/pdda/pdda.sh"
assert_rc0 "non-doc: exits 0"
assert_absent "doc-health" "non-doc: produces no lint output"

# 2. valid working doc -> lints, clean, exit 0
new_sandbox
good_doc "$SBOX/PROJECT/2-WORKING/GH-1-ok.md"
printf -- '- [GH-1](PROJECT/2-WORKING/GH-1-ok.md)\n' >> "$SBOX/ROADMAP.md"
run_edit_hook "$SBOX/PROJECT/2-WORKING/GH-1-ok.md"
assert_rc0 "valid doc: exits 0"
assert_has "doc-health (edit): PROJECT/2-WORKING/GH-1-ok.md" "valid doc: announces the lint"
assert_has "errors=0" "valid doc: frontmatter clean"

# 3. malformed doc (no frontmatter) -> warns but STILL exits 0 (edit not blocked)
new_sandbox
printf 'no frontmatter here\n' > "$SBOX/PROJECT/2-WORKING/BAD.md"
run_edit_hook "$SBOX/PROJECT/2-WORKING/BAD.md"
assert_rc0 "malformed doc: exits 0 (fail-open)"
assert_has "frontmatter" "malformed doc: surfaces the frontmatter finding"

# 4. the hook makes NO network call: it must never invoke the issue-doc-sync / gh path
assert_absent "issue-doc-sync" "edit hook: no network issue-doc-sync check"

# 5. garbage / empty payload -> fail-open exit 0
new_sandbox
HOOK_OUT="$(printf 'this is not json' | env $(sbox_env) bash "$EDIT_HOOK" 2>&1)"; RC=$?
assert_rc0 "garbage payload: exits 0"
HOOK_OUT="$(printf '' | env $(sbox_env) bash "$EDIT_HOOK" 2>&1)"; RC=$?
assert_rc0 "empty payload: exits 0"

# 6. ROADMAP.md edit -> routed to the roadmap check (and still exit 0)
new_sandbox
printf '# Roadmap\n\n- [ ] a task checkbox that the roadmap check rejects\n' > "$SBOX/ROADMAP.md"
run_edit_hook "$SBOX/ROADMAP.md"
assert_rc0 "ROADMAP edit: exits 0"
assert_has "pdda-check-roadmap" "ROADMAP edit: routed to the roadmap check"

printf '\n== tier 2: Stop full-scan hook ==\n'

run_stop_hook() {
  HOOK_OUT="$(printf '%s' '{"stop_hook_active":false}' | env $(sbox_env) bash "$STOP_HOOK" 2>&1)"
  RC=$?
}

# clean working set -> single consolidated report, "all clear", exit 0
new_sandbox
good_doc "$SBOX/PROJECT/2-WORKING/GH-1-ok.md"
printf -- '- [GH-1](PROJECT/2-WORKING/GH-1-ok.md)\n' >> "$SBOX/ROADMAP.md"
printf '# Changelog\n\n## 2026-06-29\n\n- seeded\n' > "$SBOX/CHANGELOG.md"
printf '1\tOPEN\n' > "$SBOX/.pdda-gh-state.tsv"
run_stop_hook
assert_rc0 "stop/clean: exits 0"
assert_has "PDDA doc-health (stop scan)" "stop/clean: emits ONE consolidated report header"
assert_has "all clear" "stop/clean: reports all clear"

# closed-issue drift -> consolidated report includes issue-doc-sync (from cache), still exit 0
new_sandbox
good_doc "$SBOX/PROJECT/2-WORKING/GH-2-done.md"
printf -- '- [GH-2](PROJECT/2-WORKING/GH-2-done.md)\n' >> "$SBOX/ROADMAP.md"
printf '# Changelog\n\n## 2026-06-29\n\n- seeded\n' > "$SBOX/CHANGELOG.md"
printf '2\tCLOSED\n' > "$SBOX/.pdda-gh-state.tsv"
run_stop_hook
assert_rc0 "stop/drift: exits 0 even with findings (never blocks)"
assert_has "issue #2 is CLOSED" "stop/drift: report includes issue-doc-sync against the cached gh-state"
assert_has "warn(s)" "stop/drift: consolidated counts shown"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
