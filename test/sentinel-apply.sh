#!/usr/bin/env bash
# Test: sentinel/apply.sh — Phase 2b worktree executor.
#
# Covers the Phase 2b QA gate:
#   - allowlisted full-file edit → clean worktree diff + gate pass
#   - out-of-allowlist / .. / symlinked / absolute target refused
#   - primary tree provably untouched after the run
#   - worktree+branch always cleaned up on success, gate-fail, error, AND SIGINT
#   - two concurrent runs do not collide (distinct branch/dir)
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
SENTINEL="$REPO_ROOT/sentinel/apply.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '%s\n' "--- output ---" "$1" "---" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf '%s\n' "--- output ---" "$1" "---" ;; *) pass "$3" ;; esac; }
assert_rc()       { [ "$1" -eq "$2" ] && pass "$3" || fail "$3 (exit $1, want $2)"; }

ROOT=""
REC_JSON=""
cleanup() { [ -n "$ROOT" ] && rm -rf "$ROOT"; }
trap cleanup EXIT

# Set up sandbox repo with utils/ and .gitignore copied over so it can run pdda.sh checks inside worktrees
new_sandbox() {
  cleanup
  ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-apply.XXXXXX")"
  SBOX="$ROOT/repo"
  BIN_DIR="$ROOT/fakebin"
  ACTLOG="$ROOT/activity.jsonl"
  REC_JSON="$ROOT/rec.json"
  mkdir -p "$SBOX" "$BIN_DIR"
  (
    cd "$SBOX" || exit 1
    git init -q
    git config user.name "PDDA Test"
    git config user.email "pdda@example.com"
    
    # Copy utils/ and .gitignore so the worktree checkouts have them
    cp -r "$REPO_ROOT/utils" ./
    cp "$REPO_ROOT/.gitignore" ./
    
    # Create the required directories
    mkdir -p PROJECT/1-INBOX PROJECT/2-WORKING PROJECT/3-COMPLETED PROJECT/4-MISC
    
    # Seed a target file with valid frontmatter and status table
    cat > PROJECT/2-WORKING/test-doc.md <<'EOF'
---
title: Test Document
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | Test runner |

EOF

    git add -A && git commit -qm "seed"
  )
}

# Write a fake model CLI that prints the first arg verbatim
fake_model() {  # <literal-response>
  cat > "$BIN_DIR/fakemodel" <<FAKE
#!/usr/bin/env bash
if [ -n "\${FAKE_MODEL_SLEEP:-}" ]; then
  sleep "\$FAKE_MODEL_SLEEP"
fi
cat <<'RESP'
$1
RESP
FAKE
  chmod +x "$BIN_DIR/fakemodel"
}

run_apply() {
  # run apply.sh against the sandbox
  ( cd "$SBOX" && env PATH="$BIN_DIR:$PATH" \
      PDDA_REPO_ROOT="$SBOX" \
      PDDA_ACTIVITY_LOG="$ACTLOG" \
      PDDA_LLM_BIN="${LLM_BIN:-fakemodel}" \
      SENTINEL_ENABLED="${SENTINEL_ENABLED:-1}" \
      SENTINEL_APPLY_MAX_LINE_DELTA="${SENTINEL_APPLY_MAX_LINE_DELTA:-40}" \
      bash "$SENTINEL" "$@" 2>&1 )
}

tree_fingerprint() { ( cd "$SBOX" && git status --porcelain; git rev-parse HEAD ); }

assert_no_worktrees() {
  local wt_list; wt_list="$(git -C "$SBOX" worktree list)"
  local line_count; line_count="$(echo "$wt_list" | grep -c '' || echo 0)"
  [ "$line_count" -eq 1 ] && pass "$1: no leaked worktrees" || fail "$1: leaked worktrees found ($wt_list)"
}

assert_no_branches() {
  local branches; branches="$(git -C "$SBOX" branch | tr -d ' *')"
  if [ "$branches" = "master" ] || [ "$branches" = "main" ]; then
    pass "$1: no leaked branches"
  else
    fail "$1: leaked branches found ($branches)"
  fi
}

# --- Scenario 1: allowlisted full-file edit -> clean worktree diff + gate pass ---
new_sandbox
cat > "$REC_JSON" <<EOF
{
  "should_update": true,
  "mode_recommendation": "dry_run",
  "risk": "low",
  "category": "test",
  "targets": ["PROJECT/2-WORKING/test-doc.md"],
  "reason": "testing apply",
  "summary": "test update",
  "confidence": 0.95
}
EOF

cat > "$ROOT/response1.txt" <<'EOF'
===FULL_FILE===
---
title: Test Document Edited
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | Test runner edited |
===END_FULL_FILE===
EOF

fake_model "$(cat "$ROOT/response1.txt")"

BEFORE_TREE="$(tree_fingerprint)"
OUT="$(run_apply "$REC_JSON")"; RC=$?
AFTER_TREE="$(tree_fingerprint)"

assert_rc "$RC" 0 "Scenario 1: apply exits 0"
assert_contains "$OUT" "=== BEGIN WORKTREE DIFF ===" "Scenario 1: outputs diff start marker"
assert_contains "$OUT" "+| Initial seed | Test runner edited" "Scenario 1: outputs the diff content"
assert_contains "$(cat "$ACTLOG")" "sentinel-apply-complete" "Scenario 1: logs complete finding"

[ "$BEFORE_TREE" = "$AFTER_TREE" ] && pass "Scenario 1: primary tree untouched" || fail "Scenario 1: primary tree changed"
assert_no_worktrees "Scenario 1"
assert_no_branches "Scenario 1"

SHA="$(git -C "$SBOX" rev-parse HEAD)"
if [ -f "$SBOX/temp/sentinel-diff-${SHA}.diff" ]; then
  pass "Scenario 1: diff file created under temp/"
else
  fail "Scenario 1: diff file not found under temp/"
fi


# --- Scenario 2: out-of-allowlist / traversal refused ---
new_sandbox
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["PROJECT/2-WORKING/../../passwd"], "summary": "test", "reason": "test"}
EOF
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 2a: traversal rejected exits non-zero"
assert_contains "$OUT" "Target validation failed" "Scenario 2a: target traversal message"
assert_no_worktrees "Scenario 2a"
assert_no_branches "Scenario 2a"

cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["/etc/passwd"], "summary": "test", "reason": "test"}
EOF
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 2b: absolute path rejected exits non-zero"
assert_no_worktrees "Scenario 2b"
assert_no_branches "Scenario 2b"

cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["sentinel/apply.sh"], "summary": "test", "reason": "test"}
EOF
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 2c: non-allowlisted target rejected exits non-zero"
assert_no_worktrees "Scenario 2c"
assert_no_branches "Scenario 2c"

# Symlinked leaf target
new_sandbox
( cd "$SBOX" && ln -s README.md PROJECT/2-WORKING/linked.md && git add -A && git commit -qm "add symlink" )
cat > "$REC_JSON" <<EOF
{
  "should_update": true,
  "mode_recommendation": "dry_run",
  "risk": "low",
  "category": "test",
  "targets": ["PROJECT/2-WORKING/linked.md"],
  "reason": "testing symlink",
  "summary": "test symlink",
  "confidence": 0.95
}
EOF
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 2d: symlinked target rejected exits non-zero"
assert_contains "$OUT" "symlinked target rejected" "Scenario 2d: symlink validation error output"
assert_no_worktrees "Scenario 2d"
assert_no_branches "Scenario 2d"


# --- Scenario 4: cleanup on apply-guard refusal, gate-fail, error, AND SIGINT ---
# 4a: a DESTRUCTIVE rewrite that drops the whole doc is refused by the collateral-loss guard at APPLY
# time (Phase 2a guard restored — Codex Blocker 3), before it ever reaches the gate; worktree cleaned up.
new_sandbox
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["PROJECT/2-WORKING/test-doc.md"], "summary": "test", "reason": "test"}
EOF
cat > "$ROOT/response_bad.txt" <<'EOF'
===FULL_FILE===
bad content without frontmatter
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response_bad.txt")"

OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 4a: destructive rewrite refused exits 1"
assert_contains "$OUT" "collateral loss" "Scenario 4a: collateral-loss guard message"
assert_contains "$OUT" "Failed to apply full-file update" "Scenario 4a: apply refusal surfaced"
assert_absent "$OUT" "=== BEGIN WORKTREE DIFF ===" "Scenario 4a: no diff emitted for refused apply"
assert_no_worktrees "Scenario 4a"
assert_no_branches "Scenario 4a"

# 4c: an edit that APPLIES cleanly (within the collateral tolerance) but FAILS the hardened gate — here
# by injecting a machine-absolute path, which the gate's hardcoded-paths check must catch. This is the
# gate-fail-then-cleanup path (distinct from 4a's apply-time refusal).
new_sandbox
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["PROJECT/2-WORKING/test-doc.md"], "summary": "test", "reason": "test"}
EOF
cat > "$ROOT/response_gatefail.txt" <<'EOF'
===FULL_FILE===
---
title: Test Document
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | see /Users/attacker/notes.md |
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response_gatefail.txt")"

OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 4c: gate fail exits 1"
assert_contains "$OUT" "Hardened gate check failed" "Scenario 4c: error message about gate failure"
assert_no_worktrees "Scenario 4c"
assert_no_branches "Scenario 4c"

# SIGINT cleanup test
new_sandbox
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["PROJECT/2-WORKING/test-doc.md"], "summary": "test", "reason": "test"}
EOF

cat > "$ROOT/response_sigint.txt" <<'EOF'
===FULL_FILE===
---
title: Test Document Edited
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | Test runner edited |
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response_sigint.txt")"

# Run in background and send SIGINT after creation
FAKE_MODEL_SLEEP=10 run_apply "$REC_JSON" > "$ROOT/sigint.log" 2>&1 &
PID=$!

# Wait for worktree to exist
for i in {1..30}; do
  if [ -d "$SBOX/temp"/sentinel-wt-* ]; then
    break
  fi
  sleep 0.1
done

WT_DIR="$(find "$SBOX/temp" -name "sentinel-wt-*" -type d | head -1)"
if [ -n "$WT_DIR" ] && [ -d "$WT_DIR" ]; then
  pass "Scenario 4b: worktree created in background"
else
  fail "Scenario 4b: worktree was not created in background"
fi

kill -2 "$PID"
wait "$PID" 2>/dev/null

assert_no_worktrees "Scenario 4b"
assert_no_branches "Scenario 4b"


# --- Scenario 5: concurrent runs do not collide ---
new_sandbox
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["PROJECT/2-WORKING/test-doc.md"], "summary": "test", "reason": "test"}
EOF

cat > "$ROOT/response_concurrent.txt" <<'EOF'
===FULL_FILE===
---
title: Test Document Edited
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | Test runner edited |
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response_concurrent.txt")"

# Start first run in background
FAKE_MODEL_SLEEP=3 run_apply "$REC_JSON" > "$ROOT/concurrent1.log" 2>&1 &
PID1=$!
# Start second run in background
FAKE_MODEL_SLEEP=3 run_apply "$REC_JSON" > "$ROOT/concurrent2.log" 2>&1 &
PID2=$!

wait "$PID1"
RC1=$?
wait "$PID2"
RC2=$?

assert_rc "$RC1" 0 "Scenario 5: concurrent run 1 exits 0"
assert_rc "$RC2" 0 "Scenario 5: concurrent run 2 exits 0"
assert_no_worktrees "Scenario 5"
assert_no_branches "Scenario 5"

# --- Scenario 6: <sha> INPUT MODE end-to-end (Codex Blocker 1) ---
# run.sh logs its recommendation keyed by the SHORT sha; apply.sh <sha> must recover it even when
# handed the FULL 40-char oid. Previously apply.sh searched the log for the full sha and never matched.
new_sandbox
RUN="$REPO_ROOT/sentinel/run.sh"
# make a SMALL commit to review (the seed commit bundles utils/, whose diff trips run.sh's size bound)
( cd "$SBOX" && printf 'a small tracked change\n' >> PROJECT/2-WORKING/test-doc.md && git commit -aqm "small doc change" )
# stage 1: run.sh with a fake model that emits the JSON recommendation (logged with the short sha)
fake_model '{"should_update":true,"mode_recommendation":"dry_run","risk":"low","category":"docs","targets":["PROJECT/2-WORKING/test-doc.md"],"reason":"keep the status doc in sync","summary":"sync status doc","confidence":0.9}'
FULL_SHA="$(git -C "$SBOX" rev-parse HEAD)"
SHORT_SHA="$(git -C "$SBOX" rev-parse --short HEAD)"
( cd "$SBOX" && env PATH="$BIN_DIR:$PATH" PDDA_REPO_ROOT="$SBOX" PDDA_ACTIVITY_LOG="$ACTLOG" \
    PDDA_LLM_BIN=fakemodel SENTINEL_ENABLED=1 bash "$RUN" "$FULL_SHA" >/dev/null 2>&1 )
assert_contains "$(cat "$ACTLOG")" "recommendation for $SHORT_SHA" "Scenario 6: run.sh logged short-sha recommendation"
# stage 2: apply.sh <FULL sha> must find that short-keyed recommendation and apply it
cat > "$ROOT/response6.txt" <<'EOF'
===FULL_FILE===
---
title: Test Document
status: Active — Phase 0 complete
created: 2026-07-06
updated: 2026-07-06
owner: test
goal: Test sentinel apply.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Initial seed | Test runner (synced by sha mode) |
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response6.txt")"
BEFORE_TREE="$(tree_fingerprint)"
OUT="$(run_apply "$FULL_SHA")"; RC=$?
AFTER_TREE="$(tree_fingerprint)"
assert_rc "$RC" 0 "Scenario 6: apply.sh <full-sha> resolves short-keyed recommendation, exits 0"
assert_contains "$OUT" "synced by sha mode" "Scenario 6: applied the recovered recommendation"
assert_contains "$(cat "$ACTLOG")" "sentinel-apply-complete" "Scenario 6: logged apply-complete"
[ "$BEFORE_TREE" = "$AFTER_TREE" ] && pass "Scenario 6: primary tree untouched" || fail "Scenario 6: primary tree changed"
assert_no_worktrees "Scenario 6"
assert_no_branches "Scenario 6"

# also assert a genuinely-unknown sha still fails cleanly (no false match)
OUT="$(run_apply "0000000000000000000000000000000000000000")"; RC=$?
assert_rc "$RC" 1 "Scenario 6: unknown sha rejected exits 1"

# --- Scenario 7: ROOT-DOC target — gate is NOT a no-op (Codex Blocker 2) ---
# README.md is allowlisted but lives OUTSIDE PROJECT/2-WORKING, so the old gate scanned nothing and
# passed any edit. The class-aware gate must still run hardcoded-paths on it.
new_sandbox
( cd "$SBOX" && printf '# Sandbox Repo\n\nGovernance readme for the sentinel apply test.\nSee the docs under PROJECT/ for details.\nNothing machine-specific here.\n' > README.md && git add -A && git commit -qm "add README" )
cat > "$REC_JSON" <<EOF
{"should_update": true, "targets": ["README.md"], "summary": "test", "reason": "test"}
EOF
# 7a: a CLEAN README edit passes the gate
cat > "$ROOT/response7ok.txt" <<'EOF'
===FULL_FILE===
# Sandbox Repo

Governance readme for the sentinel apply test.
See the docs under PROJECT/ for details.
Nothing machine-specific here. (reviewed)
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response7ok.txt")"
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 0 "Scenario 7a: clean root-doc edit passes gate, exits 0"
assert_contains "$OUT" "=== BEGIN WORKTREE DIFF ===" "Scenario 7a: emits diff for clean root-doc edit"
assert_no_worktrees "Scenario 7a"
assert_no_branches "Scenario 7a"

# 7b: a README edit injecting a machine-absolute path MUST be caught by the gate (proves non-vacuous)
cat > "$ROOT/response7bad.txt" <<'EOF'
===FULL_FILE===
# Sandbox Repo

Governance readme for the sentinel apply test.
See the docs under PROJECT/ for details.
Install lives at /Users/attacker/pdda per local setup.
===END_FULL_FILE===
EOF
fake_model "$(cat "$ROOT/response7bad.txt")"
OUT="$(run_apply "$REC_JSON")"; RC=$?
assert_rc "$RC" 1 "Scenario 7b: root-doc with hardcoded path fails gate, exits 1"
assert_contains "$OUT" "Hardened gate check failed" "Scenario 7b: gate catches hardcoded path in root doc"
assert_no_worktrees "Scenario 7b"
assert_no_branches "Scenario 7b"

printf '\n=== sentinel-apply: %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
