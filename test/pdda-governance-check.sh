#!/usr/bin/env bash
# Test: pdda.sh governance — dead-reference resolution (incl. bare-filename fallback + GH-doc
# exemption), orphan-doc detection, subcommand drift, and env-var drift.
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
assert_eq()       { [ "$1" = "$2" ] && pass "$3" || fail "$3 (expected '$2', got '$1')"; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-governance.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/2-WORKING" "$SBOX/utils/pdda"
}

run_check() {
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_MODE=full \
  PDDA_FORMAT=text \
  bash "$PDDA" governance 2>&1
}

# --- dead reference: a markdown link to a file that does not exist --------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

See [the plan](PROJECT/2-WORKING/NOPE.md) for details.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference" "dead markdown-link reference is flagged"
assert_contains "$out" "NOPE.md" "flags the specific missing file"
assert_contains "$out" "WARN [pdda-check-governance]" "dead reference is severity warn, not error"

# --- bare filename that exists elsewhere in the repo is NOT flagged (blank.md-style mention) -------
new_sandbox
mkdir -p "$SBOX/PROJECT/3-COMPLETED"
: > "$SBOX/PROJECT/3-COMPLETED/blank.md"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

`blank.md` placeholders are scaffolding and should be ignored.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'blank.md'" "bare filename found elsewhere in the repo is not flagged dead"

# --- a GH-<n>-*.md name is a naming-convention example, never a real cross-reference ---------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Name it like `GH-1234-EXAMPLE-DOC.md`.
EOF
out="$(run_check)"
assert_absent "$out" "GH-1234-EXAMPLE-DOC.md" "GH-issue example filename is exempt from dead-reference checking"

# --- orphan doc: a present governance doc the index doc never mentions ----------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Nothing else mentioned here.
EOF
cat > "$SBOX/AGENTS.md" <<'EOF'
# AGENTS.md
EOF
out="$(run_check)"
assert_contains "$out" "not referenced anywhere in ROUTER.md" "a governance doc unreferenced by the index doc is flagged"
assert_contains "$out" "WARN [pdda-check-governance]" "orphan-doc finding is severity warn, not error"

# --- subcommand drift: the real pdda.sh dispatcher has a 'governance' subcommand -------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Run `pdda.sh frontmatter` and `pdda.sh roadmap`.
EOF
out="$(run_check)"
assert_contains "$out" "subcommand 'governance' is not documented" "an undocumented real subcommand is flagged"
assert_contains "$out" "ERROR [pdda-check-governance]" "subcommand drift is severity error (mechanical, blocks in full)"

new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Run `pdda.sh governance` for the doc-consistency check.
EOF
out="$(run_check)"
assert_absent "$out" "subcommand 'governance' is not documented" "a documented real subcommand is not flagged"

# --- env-var drift: a fabricated var is flagged; a real one implemented in pdda-lib.sh is not -------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Set `PDDA_TOTALLY_MADE_UP_VAR` before running.
EOF
out="$(run_check)"
assert_contains "$out" "PDDA_TOTALLY_MADE_UP_VAR" "a fabricated env var not read by any shipped script is flagged"
assert_contains "$out" "WARN [pdda-check-governance]" \
  "env-var drift is severity warn, not error (PDDA-INSTALL.md legitimately documents canonical-only pdda-sync.sh vars that a target install never ships)"

new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Set `PDDA_MODE` before running.
EOF
out="$(run_check)"
assert_absent "$out" "PDDA_MODE' which no shipped script" "a real env var implemented in pdda-lib.sh is not flagged"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
