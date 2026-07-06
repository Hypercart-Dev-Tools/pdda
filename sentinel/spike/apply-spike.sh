#!/usr/bin/env bash
set -u

# ------------------------------------------------------------------------------------------------
# Sentinel Phase 2a — apply-contract SPIKE (discovery, throwaway measurement).
#
# Purpose: decide how a Phase-1 recommendation becomes concrete file edits, by MEASURING the two
# finalist apply formats over real governance docs — not asserting. Both were surfaced by the Codex+agy
# consult (relay-system/2026-07-05/sentinel-phase2-222804/); unified diffs were ruled out by both.
#
#   (A) full-file  — model returns the entire new body; apply = atomic write, guarded by a size/scope
#                    bound. Mechanically always "applies"; failure mode is silent lossiness (the model
#                    drops/rewrites unrelated sections of a large doc).
#   (B) srch/repl  — model returns Aider-style SEARCH/REPLACE blocks; apply = exact-match substitution,
#                    all-or-nothing. Failure mode is anchor-not-found / ambiguous / partial.
#
# This is SPIKE code (sentinel/spike/), not the Phase 2b executor. It also exercises the two RESOLVED
# decisions so 2b inherits working primitives: the hardened gate (deterministic checks only,
# count-based, activity-log redirected) and the realpath-hardened allowlist check.
#
# Usage:
#   apply-spike.sh selftest        # deterministic mechanical fixtures (no model); always runnable
#   apply-spike.sh live            # real measurement: one model call/scenario over real repo docs
#                                   #   needs PDDA_LLM_BIN (e.g. PDDA_LLM_BIN=codex PDDA_LLM_ARGS="exec -s read-only")
# ------------------------------------------------------------------------------------------------

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"
WORK="$HERE/work"

SENTINEL_APPLY_MAX_LINE_DELTA="${SENTINEL_APPLY_MAX_LINE_DELTA:-40}"   # full-file scope guard

PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }

# ------------------------------------------------------------------------------------------------
# Allowlist check (RESOLVED decision) — realpath-hardened containment, not a prefix compare.
#   ok  -> prints the resolved absolute path, rc 0
#   bad -> prints "reason", rc 1   (absolute, empty, .., symlinked component, outside allow-root, wrong case)
# ------------------------------------------------------------------------------------------------
allowlist_check() {  # <repo-relative target> <allow-root abs> <worktree-root abs>
  local target="$1" allow_root="$2" wt_root="$3" abs parent base
  [ -n "$target" ] || { echo "empty target"; return 1; }
  case "$target" in
    /*) echo "absolute path rejected"; return 1 ;;
    *..*) echo "dot-dot rejected"; return 1 ;;
  esac
  abs="$wt_root/$target"
  parent="$(cd "$(dirname "$abs")" 2>/dev/null && pwd -P)" || { echo "parent dir missing"; return 1; }
  base="$(basename "$abs")"
  # refuse a symlinked leaf; pwd -P above already resolved symlinked parents, so compare the resolved
  # parent stays under the resolved allow-root.
  [ -L "$parent/$base" ] && { echo "symlinked target rejected"; return 1; }
  local allow_real; allow_real="$(cd "$allow_root" 2>/dev/null && pwd -P)" || { echo "allow-root missing"; return 1; }
  case "$parent/" in
    "$allow_real"/*|"$allow_real"/) : ;;
    *) echo "outside allowlist ($parent not under $allow_real)"; return 1 ;;
  esac
  # exact-case guard: on a case-folding FS the file may exist under different case; require the
  # basename to match an actually-listed entry byte-for-byte when the file exists.
  if [ -e "$parent/$base" ]; then
    ls -1 "$parent" 2>/dev/null | grep -Fqx "$base" || { echo "case-mismatch"; return 1; }
  fi
  printf '%s\n' "$parent/$base"
  return 0
}

# ------------------------------------------------------------------------------------------------
# (A) full-file applier — atomic write + scope guard.
#   rc 0 applied; rc 2 refused by guard (empty / delta too large)
# ------------------------------------------------------------------------------------------------
apply_full_file() {  # <target abs> <new-body-file>
  local target="$1" body="$2" old_n new_n delta
  [ -s "$body" ] || { echo "guard: empty body"; return 2; }
  old_n="$(grep -c '' "$target" 2>/dev/null || echo 0)"
  new_n="$(grep -c '' "$body" 2>/dev/null || echo 0)"
  delta=$(( old_n > new_n ? old_n - new_n : new_n - old_n ))
  if [ "$delta" -gt "$SENTINEL_APPLY_MAX_LINE_DELTA" ]; then
    echo "guard: line delta $delta > $SENTINEL_APPLY_MAX_LINE_DELTA"; return 2
  fi
  cp "$body" "$target.tmp.$$" && mv "$target.tmp.$$" "$target"
}

# ------------------------------------------------------------------------------------------------
# (B) search/replace applier — Aider-style blocks, exact match, all-or-nothing.
#   Block format:  <<<<<<< SEARCH\n...\n=======\n...\n>>>>>>> REPLACE
#   rc 0 applied; rc 3 anchor-not-found; rc 4 ambiguous(>1 match); rc 5 malformed blocks
# ------------------------------------------------------------------------------------------------
apply_search_replace() {  # <target abs> <blocks-file>
  SR_TARGET="$1" SR_BLOCKS="$2" node <<'NODE'
  const fs = require('fs');
  const target = process.env.SR_TARGET, blocksFile = process.env.SR_BLOCKS;
  let src = fs.readFileSync(target, 'utf8');
  const raw = fs.readFileSync(blocksFile, 'utf8');
  const re = /<<<<<<< SEARCH\n([\s\S]*?)\n=======\n([\s\S]*?)\n>>>>>>> REPLACE/g;
  let m, blocks = [];
  while ((m = re.exec(raw)) !== null) blocks.push([m[1], m[2]]);
  if (blocks.length === 0) { process.stderr.write("malformed: no SEARCH/REPLACE blocks"); process.exit(5); }
  let out = src;
  for (const [search, replace] of blocks) {
    // exact-match, count occurrences
    let idx = out.indexOf(search);
    if (idx === -1) { process.stderr.write("anchor-not-found"); process.exit(3); }
    if (out.indexOf(search, idx + 1) !== -1) { process.stderr.write("ambiguous"); process.exit(4); }
    out = out.slice(0, idx) + replace + out.slice(idx + search.length);
  }
  fs.writeFileSync(target + ".tmp." + process.pid, out);
  fs.renameSync(target + ".tmp." + process.pid, target);
NODE
}

# ------------------------------------------------------------------------------------------------
# Hardened gate (RESOLVED decision) — deterministic checks ONLY, count-based, log redirected.
#   Runs frontmatter+status-table+hardcoded-paths scoped to the single edited file; passes iff the
#   summed error count is 0. Never invokes pdda-doc-ready (the LLM layer). PDDA_ACTIVITY_LOG points at
#   a throwaway so the gate can't dirty the artifact.  rc 0 pass; rc 1 fail
# ------------------------------------------------------------------------------------------------
hardened_gate() {  # <edited file abs>
  local f="$1" errs=0 c out n
  for c in frontmatter status-table hardcoded-paths; do
    out="$(PDDA_ONLY_FILE="$f" PDDA_ACTIVITY_LOG="$WORK/gate-activity.$$.jsonl" PDDA_MODE=observe \
             "$PDDA" "$c" 2>/dev/null || true)"
    n="$(printf '%s\n' "$out" | sed -n 's/.*errors=\([0-9]*\).*/\1/p' | tail -1)"
    errs=$(( errs + ${n:-0} ))
  done
  rm -f "$WORK/gate-activity.$$.jsonl"
  [ "$errs" -eq 0 ]
}

# ================================================================================================
# selftest — deterministic mechanical fixtures (no model). Proves parser + failure modes.
# ================================================================================================
selftest() {
  rm -rf "$WORK"; mkdir -p "$WORK"
  local t="$WORK/doc.md"

  # --- full-file: clean apply ---
  printf 'line1\nline2\nline3\n' > "$t"
  printf 'line1\nline2-EDITED\nline3\n' > "$WORK/body.md"
  apply_full_file "$t" "$WORK/body.md" >/dev/null 2>&1 && grep -q 'line2-EDITED' "$t" \
    && pass "full-file: clean apply" || fail "full-file: clean apply"

  # --- full-file: scope guard trips on huge delta ---
  printf 'a\n' > "$t"; seq 1 200 > "$WORK/body.md"
  apply_full_file "$t" "$WORK/body.md" >/dev/null 2>&1
  [ "$?" -eq 2 ] && pass "full-file: scope guard trips on large delta" || fail "full-file: scope guard"

  # --- full-file: empty body refused ---
  printf 'a\nb\n' > "$t"; : > "$WORK/body.md"
  apply_full_file "$t" "$WORK/body.md" >/dev/null 2>&1
  [ "$?" -eq 2 ] && pass "full-file: empty body refused" || fail "full-file: empty body refused"

  # --- search/replace: exact match applies ---
  printf 'alpha\nbeta\ngamma\n' > "$t"
  printf '<<<<<<< SEARCH\nbeta\n=======\nBETA!\n>>>>>>> REPLACE\n' > "$WORK/blocks.md"
  apply_search_replace "$t" "$WORK/blocks.md" >/dev/null 2>&1 && grep -q 'BETA!' "$t" \
    && pass "search/replace: exact match applies" || fail "search/replace: exact match applies"

  # --- search/replace: whitespace-drift SEARCH -> clean anchor-not-found (NOT silent) ---
  printf 'alpha\nbeta\ngamma\n' > "$t"
  printf '<<<<<<< SEARCH\n  beta\n=======\nBETA!\n>>>>>>> REPLACE\n' > "$WORK/blocks.md"
  apply_search_replace "$t" "$WORK/blocks.md" >/dev/null 2>&1
  [ "$?" -eq 3 ] && pass "search/replace: whitespace drift -> anchor-not-found" || fail "search/replace: whitespace drift"

  # --- search/replace: ambiguous (2 matches) refused ---
  printf 'dup\nother\ndup\n' > "$t"
  printf '<<<<<<< SEARCH\ndup\n=======\nDUP\n>>>>>>> REPLACE\n' > "$WORK/blocks.md"
  apply_search_replace "$t" "$WORK/blocks.md" >/dev/null 2>&1
  [ "$?" -eq 4 ] && pass "search/replace: ambiguous match refused" || fail "search/replace: ambiguous match refused"

  # --- allowlist: traversal / absolute / good ---
  mkdir -p "$WORK/repo/docs"; printf 'x\n' > "$WORK/repo/docs/ok.md"
  allowlist_check "docs/ok.md" "$WORK/repo/docs" "$WORK/repo" >/dev/null 2>&1 \
    && pass "allowlist: in-tree doc accepted" || fail "allowlist: in-tree doc accepted"
  allowlist_check "../../etc/passwd" "$WORK/repo/docs" "$WORK/repo" >/dev/null 2>&1 \
    && fail "allowlist: traversal rejected" || pass "allowlist: traversal rejected"
  allowlist_check "/etc/passwd" "$WORK/repo/docs" "$WORK/repo" >/dev/null 2>&1 \
    && fail "allowlist: absolute rejected" || pass "allowlist: absolute rejected"
  allowlist_check "docs/ok.md" "$WORK/repo/other" "$WORK/repo" >/dev/null 2>&1 \
    && fail "allowlist: outside allow-root rejected" || pass "allowlist: outside allow-root rejected"

  printf '\n=== selftest: %d passed, %d failed ===\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}

case "${1:-selftest}" in
  selftest) selftest ;;
  live)     shift; . "$HERE/apply-spike-live.sh" ;;
  *) echo "usage: apply-spike.sh selftest|live" >&2; exit 2 ;;
esac
