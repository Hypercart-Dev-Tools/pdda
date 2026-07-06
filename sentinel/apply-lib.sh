#!/usr/bin/env bash
# ------------------------------------------------------------------------------------------------
# Sentinel Phase 2b — apply-contract shared library.
#
# Contains the four promoted Phase-2a primitives (apply_full_file, apply_search_replace,
# hardened_gate, allowlist_check) plus allowlist verification helper.
# ------------------------------------------------------------------------------------------------

# Allowlist check (RESOLVED decision) — realpath-hardened containment, not a prefix compare.
#   ok  -> prints the resolved absolute path, rc 0
#   bad -> prints "reason", rc 1 (absolute, empty, .., symlinked component, outside allow-root, wrong case)
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

# (A) full-file applier — atomic write + scope guard.
#   rc 0 applied; rc 2 refused by guard (empty / delta too large)
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

# (B) search/replace applier — Aider-style blocks, exact match, all-or-nothing.
#   Block format:  <<<<<<< SEARCH\n...\n=======\n...\n>>>>>>> REPLACE
#   rc 0 applied; rc 3 anchor-not-found; rc 4 ambiguous(>1 match); rc 5 malformed blocks
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

# Hardened gate (RESOLVED decision) — deterministic checks ONLY, count-based, log redirected.
#   Runs frontmatter+status-table+hardcoded-paths scoped to the single edited file; passes iff the
#   summed error count is 0. Never invokes pdda-doc-ready (the LLM layer). PDDA_ACTIVITY_LOG points at
#   a throwaway so the gate can't dirty the artifact.  rc 0 pass; rc 1 fail
hardened_gate() {  # <edited file abs> <wt_root abs> <temp_log_dir abs>
  local f="$1" wt_root="$2" temp_log_dir="$3" errs=0 c out n pdda_bin
  pdda_bin="$wt_root/utils/pdda/pdda.sh"
  
  [ -f "$pdda_bin" ] || { echo "gate error: pdda.sh not found at $pdda_bin"; return 1; }
  
  local temp_log="$temp_log_dir/gate-activity.$$.jsonl"
  
  for c in frontmatter status-table hardcoded-paths; do
    out="$(PDDA_ONLY_FILE="$f" PDDA_ACTIVITY_LOG="$temp_log" PDDA_MODE=observe PDDA_REPO_ROOT="$wt_root" \
             "$pdda_bin" "$c" 2>/dev/null || true)"
    n="$(printf '%s\n' "$out" | sed -n 's/.*errors=\([0-9]*\).*/\1/p' | tail -1)"
    errs=$(( errs + ${n:-0} ))
  done
  rm -f "$temp_log"
  [ "$errs" -eq 0 ]
}

# Realpath-hardened allowlist verification helper for the target repository docs
sentinel_check_target_allowlist() { # <repo-relative target> <worktree-root abs>
  local target="$1" wt_root="$2"
  # Normalize leading ./ out if present
  target="${target#./}"
  
  case "$target" in
    PROJECT/1-INBOX/*)
      allowlist_check "$target" "$wt_root/PROJECT/1-INBOX" "$wt_root"
      ;;
    PROJECT/2-WORKING/*)
      allowlist_check "$target" "$wt_root/PROJECT/2-WORKING" "$wt_root"
      ;;
    PROJECT/3-COMPLETED/*)
      allowlist_check "$target" "$wt_root/PROJECT/3-COMPLETED" "$wt_root"
      ;;
    PROJECT/4-MISC/*)
      allowlist_check "$target" "$wt_root/PROJECT/4-MISC" "$wt_root"
      ;;
    README.md|ROUTER.md|AGENTS.md|GUIDING-PRINCIPLES.md|CHANGELOG.md)
      allowlist_check "$target" "$wt_root" "$wt_root"
      ;;
    utils/pdda/PDDA-INSTALL.md)
      allowlist_check "$target" "$wt_root/utils/pdda" "$wt_root"
      ;;
    *)
      echo "outside allowlist (unmatched target: $target)"
      return 1
      ;;
  esac
}
