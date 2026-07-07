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
#   rc 0 applied; rc 2 refused by guard (empty / delta too large / collateral loss)
apply_full_file() {  # <target abs> <new-body-file>
  local target="$1" body="$2" old_n new_n delta lost
  local max_delta="${SENTINEL_APPLY_MAX_LINE_DELTA:-40}"
  local max_lost="${SENTINEL_APPLY_MAX_LOST_LINES:-3}"
  [ -s "$body" ] || { echo "guard: empty body"; return 2; }
  old_n="$(grep -c '' "$target" 2>/dev/null || echo 0)"
  new_n="$(grep -c '' "$body" 2>/dev/null || echo 0)"
  delta=$(( old_n > new_n ? old_n - new_n : new_n - old_n ))
  if [ "$delta" -gt "$max_delta" ]; then
    echo "guard: line delta $delta > $max_delta"; return 2
  fi
  # collateral-loss guard (promoted from the Phase 2a spike, sentinel/spike/apply-spike-live.sh:46-50):
  # count original NON-BLANK lines that vanished verbatim from the new body. A targeted doc edit loses
  # ~0; a DESTRUCTIVE same-length rewrite that drops a section spikes this even when the line-delta
  # bound passes — which the delta check alone cannot catch. This is the full-file-specific lossiness
  # signal the plan's apply-mechanism decision (GH-10-SENTINEL.md:336-337) calls the load-bearing guard.
  # NB: runs BEFORE the write, so $target is still the original content and $body is the candidate.
  lost="$(awk 'NR==FNR{seen[$0]=1;next} $0 ~ /[^ \t]/ && !($0 in seen){m++} END{print m+0}' "$body" "$target")"
  if [ "${lost:-0}" -gt "$max_lost" ]; then
    echo "guard: collateral loss — $lost original non-blank lines vanished > $max_lost"; return 2
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

# Hardened gate (RESOLVED decision) — deterministic checks ONLY, count-based, log redirected,
# TARGET-CLASS-AWARE and fail-closed.
#
# The bug this replaced: the old gate ran frontmatter+status-table+hardcoded-paths for every target, but
# all three iterate pdda_list_working_docs(), which (with PDDA_ONLY_FILE set) returns the file ONLY when
# it lives under PROJECT/2-WORKING. For any other allowlisted target — README.md, ROUTER.md, AGENTS.md,
# GUIDING-PRINCIPLES.md, CHANGELOG.md, utils/pdda/PDDA-INSTALL.md, PROJECT/{1,3,4}/* — the checks scanned
# NOTHING and reported errors=0, so the gate passed those edits with zero scrutiny (Codex Blocker 2).
#
# This version scopes by class:
#   * hardcoded-paths applies to EVERY doc (no machine-absolute paths), so we scope the canonical check
#     to the one edited file by pointing PDDA_WORKING_DIR at its own directory — making it scan the file
#     regardless of where it lives. This is the fix for the no-op hole.
#   * frontmatter + status-table are the phased-plan-doc contract; they apply ONLY to PROJECT/2-WORKING
#     docs (exactly the surface pdda_list_working_docs governs). Root/governance docs legitimately don't
#     carry that contract, so we skip those two BY CLASS rather than pretend-passing them.
# Fail-closed: if any invoked check emits no parseable `errors=` summary (i.e. it didn't actually run),
# the gate FAILS instead of treating the absent count as a pass.
# Never invokes pdda-doc-ready (the LLM layer). PDDA_ACTIVITY_LOG points at a throwaway so the gate can't
# dirty the artifact.  rc 0 pass; rc 1 fail
hardened_gate() {  # <edited file abs> <wt_root abs> <temp_log_dir abs>
  local f="$1" wt_root="$2" temp_log_dir="$3" errs=0 c out n pdda_bin rel dir
  pdda_bin="$wt_root/utils/pdda/pdda.sh"

  [ -f "$pdda_bin" ] || { echo "gate error: pdda.sh not found at $pdda_bin"; return 1; }
  [ -s "$f" ] || { echo "gate error: edited file empty or missing: $f"; return 1; }

  rel="${f#"$wt_root"/}"
  # Use the PLAIN dirname (not pwd -P): PDDA_ONLY_FILE is passed unresolved as "$f", and pdda's
  # pdda_list_working_docs matches it against "$PDDA_WORKING_DIR"/*.md by string prefix. Resolving the
  # dir (e.g. /tmp -> /private/tmp on macOS) while leaving "$f" unresolved would break that prefix match
  # and silently empty the list — reintroducing the very no-op this gate exists to close. Path safety
  # (no .., no symlinked component) was already enforced by allowlist_check before we got here.
  dir="$(dirname "$f")"
  local temp_log="$temp_log_dir/gate-activity.$$.jsonl"

  # run one pdda check scoped as given; returns its errors= count on stdout, or nonzero rc if it produced
  # no parseable summary (the fail-closed signal).
  # NB: route env through `env` — a VAR=val produced by expansion is NOT honored as an assignment
  # prefix (the shell resolves prefixes before expansion), so the optional PDDA_WORKING_DIR override
  # must be an argument to `env`, not a bare word before the command.
  _gate_run() {  # <check> [PDDA_WORKING_DIR override]
    local check="$1" wdir="${2:-}" o m
    if [ -n "$wdir" ]; then
      o="$(env PDDA_ONLY_FILE="$f" PDDA_WORKING_DIR="$wdir" PDDA_ACTIVITY_LOG="$temp_log" \
             PDDA_MODE=observe PDDA_REPO_ROOT="$wt_root" "$pdda_bin" "$check" 2>/dev/null || true)"
    else
      o="$(env PDDA_ONLY_FILE="$f" PDDA_ACTIVITY_LOG="$temp_log" \
             PDDA_MODE=observe PDDA_REPO_ROOT="$wt_root" "$pdda_bin" "$check" 2>/dev/null || true)"
    fi
    m="$(printf '%s\n' "$o" | sed -n 's/.*errors=\([0-9]*\).*/\1/p' | tail -1)"
    [ -n "$m" ] || return 2
    printf '%s\n' "$m"
  }

  # (1) hardcoded-paths — every class. Scope to this one file via its own dir so it truly scans it.
  if ! n="$(_gate_run hardcoded-paths "$dir")"; then
    echo "gate error: hardcoded-paths produced no result for $rel (fail-closed)"; rm -f "$temp_log"; return 1
  fi
  errs=$(( errs + n ))

  # (2) frontmatter + status-table — plan-doc contract, PROJECT/2-WORKING only.
  case "$rel" in
    PROJECT/2-WORKING/*.md)
      for c in frontmatter status-table; do
        if ! n="$(_gate_run "$c")"; then
          echo "gate error: $c produced no result for $rel (fail-closed)"; rm -f "$temp_log"; return 1
        fi
        errs=$(( errs + n ))
      done
      ;;
  esac

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
