#!/usr/bin/env bash
# Test: pdda-doc-ready.sh appends the Quad Concepts QUALITY rubric to the working-doc review ONLY when
# the .pdda-quad / PDDA_QUAD lever is on. Uses a fake PDDA_LLM_BIN that captures the prompt it receives
# (and emits no findings), so the assertion is deterministic and needs no real model.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
DR="$REPO_ROOT/utils/pdda/pdda-doc-ready.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }
assert_eq() { [ "$1" = "$2" ] && pass "$3" || fail "$3 (got '$1', want '$2')"; }

ROOT="$(mktemp -d "${TMPDIR:-/tmp}/qr.XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/PROJECT/2-WORKING"
printf -- '---\ntitle: T\n---\n## Quad Concepts\n- a → b\n' > "$ROOT/PROJECT/2-WORKING/d.md"

# fake model: write the LAST arg (the full rubric+doc prompt) to $PROMPT_CAP; emit nothing
cat > "$ROOT/fake" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${!#}" > "$PROMPT_CAP"
EOF
chmod +x "$ROOT/fake"

run_dr() {  # <extra-env...>  -> prints the match count (single clean integer)
  local c
  env PDDA_REPO_ROOT="$ROOT" PDDA_ACTIVITY_LOG="$ROOT/act.jsonl" PROMPT_CAP="$ROOT/cap.txt" \
      PDDA_LLM_BIN="$ROOT/fake" "$@" bash "$DR" >/dev/null 2>&1
  c="$(grep -c "Quad Concepts.*mode is enabled" "$ROOT/cap.txt" 2>/dev/null)"
  echo "${c:-0}"
}
: > "$ROOT/cap.txt"; assert_eq "$(run_dr)"            "0" "lever off: quad quality rubric NOT appended"
: > "$ROOT/cap.txt"; assert_eq "$(run_dr PDDA_QUAD=1)" "1" "lever on (env): quad quality rubric appended"
printf 'on\n' > "$ROOT/.pdda-quad"
: > "$ROOT/cap.txt"; assert_eq "$(run_dr)"            "1" "lever on (.pdda-quad file): quad quality rubric appended"

# --- clamp: a model emitting severity:error is downgraded to warn and never blocks (exit 0), even in
#     full mode (a non-deterministic oracle must not gain build-blocking power) ---
cat > "$ROOT/fake_err" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '{"severity":"error","line":0,"message":"synthetic error finding"}'
EOF
chmod +x "$ROOT/fake_err"
OUT="$(env PDDA_REPO_ROOT="$ROOT" PDDA_ACTIVITY_LOG="$ROOT/act.jsonl" PDDA_LLM_BIN="$ROOT/fake_err" \
        PDDA_MODE=full bash "$DR" 2>&1)"; RC=$?
case "$OUT" in *"WARN [pdda-doc-ready]"*) pass "clamp: error severity downgraded to warn" ;; *) fail "clamp: expected a WARN finding" ;; esac
case "$OUT" in *"ERROR [pdda-doc-ready]"*) fail "clamp: an ERROR finding leaked (not clamped)" ;; *) pass "clamp: no ERROR finding emitted" ;; esac
[ "$RC" -eq 0 ] && pass "clamp: doc-ready exits 0 even in full mode" || fail "clamp: expected exit 0, got $RC"

printf '\n=== pdda-doc-ready-quad: %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
