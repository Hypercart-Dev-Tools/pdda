#!/usr/bin/env bash
set -euo pipefail

# PDDA installer — drop the Project-Driven Doc Automation surface into ANOTHER repo in a clean,
# ready-to-use "zero state". Run it from a clone of the pdda repo:
#
#   ./install.sh /path/to/your-repo
#
# It copies the shipped runtime — exactly the set declared in utils/pdda/pdda-sync-manifest.conf and
# expanded by utils/pdda/pdda-manifest.sh (the SAME manifest pdda-sync.sh pushes, so the install set
# and the steady-state push set can never drift) — creates the PROJECT/** lifecycle tree, and
# SYNTHESISES blank seed ledger/changelog/activity/mode files. It never copies this repo's own
# ROADMAP/CHANGELOG/activity content, so the target starts empty but immediately valid. Existing
# target files are never clobbered unless you pass --force.
#
# Re-running it upgrades in place. If the target predates the utils/pdda/ subfolder (runtime kept
# FLAT under utils/), it auto-migrates to the canonical layout: removes the duplicate PDDA-owned flat
# files and repoints old-path references. Disable with --no-migrate.
#
# This is the executable form of utils/pdda/PDDA-INSTALL.md; keep the two in lockstep.

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared manifest expander — the synced runtime set is declared ONCE in
# utils/pdda/pdda-sync-manifest.conf and consumed by both this installer and pdda-sync.sh (push), so
# the two never drift (GUIDING-PRINCIPLES #4). New runtime files under utils/pdda/ ship automatically.
# shellcheck source=utils/pdda/pdda-manifest.sh
. "$SOURCE_DIR/utils/pdda/pdda-manifest.sh"

FORCE=0
WITH_STARTUP_DOCS=0
MIGRATE=1
REGISTER=1
MODE="observe"
TARGET=""

# Per-user, per-device install registry — records WHERE each copy was installed and on which source
# commit. Lives in $HOME (never in the repo, so it can't leak into the eventually-public repo). Not
# portable by design. A future sync layer reads this to find targets that are behind. Override the
# path with PDDA_REGISTRY; skip writing it with --no-register.
PDDA_REGISTRY="${PDDA_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv}"

# Optional multi-device rollup: if git-pulse (a separate, GitHub-backed activity-sync tool) is present, the
# installer also drops a PATH-NORMALIZED projection of the registry (repo name + date + source commit +
# mode; never absolute paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries it across
# devices — no new sync infrastructure. Best-effort and fail-open: absent git-pulse → silently skipped, the
# install is unaffected. The LOCAL registry above stays the source of truth. Override the location with
# PDDA_GITPULSE_DIR; disable by pointing it at a nonexistent path, or with --no-register (same gate).
PDDA_GITPULSE_DIR="${PDDA_GITPULSE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo}"

usage() {
  cat <<'USAGE'
PDDA installer — install Project-Driven Doc Automation into a target repo.

Usage:
  ./install.sh [options] <target-repo-dir>

Options:
  --force                Overwrite existing seed files (ROADMAP.md, CHANGELOG.md, .pdda-mode,
                         blank.md placeholders). Runtime scripts + PROJECT/PDDA.md are always
                         refreshed. Never touches your real PROJECT/** docs.
  --with-startup-docs    Also install adapted ROUTER.md + AGENTS.md + the /pdda re-orient skill
                         (operator read-order scaffold).
  --no-migrate           Skip auto-migration of a pre-utils/pdda/ (flat) layout. By default, when the
                         target keeps the runtime flat under utils/, install removes the duplicate
                         PDDA-owned flat files and repoints old-path references to utils/pdda/.
  --no-register          Skip recording this install in the per-user registry
                         (default: $XDG_CONFIG_HOME/pdda/registry.tsv or ~/.config/pdda/registry.tsv;
                         override with PDDA_REGISTRY). The registry is machine-local and never committed.
                         Also skips the multi-device git-pulse projection (see below).
  --mode <m>             Initial .pdda-mode: observe (default) | light | full.
  -h, --help             This message.

What gets installed (zero state):
  utils/pdda/{pdda.sh,pdda-lib.sh,pdda-doc-ready.sh,pdda-catchup.sh,pdda-gh-refresh.sh}   (runtime, refreshed)
  PROJECT/PDDA.md                                            (the contract, refreshed)
  PROJECT/{1-INBOX,2-WORKING,3-COMPLETED,4-MISC}/blank.md    (lifecycle buckets)
  ROADMAP.md CHANGELOG.md PROJECT/PDDA-ACTIVITY.jsonl .pdda-mode   (blank seeds, create-only)
  .gitignore += PROJECT/PDDA-ACTIVITY.jsonl .pdda-gh-state.tsv     (churning runtime state)

It also records the install in a per-user, machine-local registry (~/.config/pdda/registry.tsv) so
pdda-sync.sh knows where every copy lives. The registry is never committed. --no-register skips it.

If git-pulse (a GitHub-backed activity-sync tool) is present, the installer additionally drops a
path-normalized projection of the registry (repo name + date + source commit + mode; never absolute
paths) into git-pulse's repo under pdda/, and git-pulse's own sync carries that status across your
devices. Best-effort and fail-open — absent git-pulse it is silently skipped. Override the location with
PDDA_GITPULSE_DIR; the local registry remains the source of truth.

After install it runs `utils/pdda/pdda.sh run` in the target so you see it working immediately.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --with-startup-docs) WITH_STARTUP_DOCS=1; shift ;;
    --no-migrate) MIGRATE=0; shift ;;
    --no-register) REGISTER=0; shift ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'install.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else printf 'install.sh: unexpected argument %q\n' "$1" >&2; exit 2; fi ;;
  esac
done

case "$MODE" in observe|light|full) ;; *) printf 'install.sh: --mode must be observe|light|full (got %q)\n' "$MODE" >&2; exit 2 ;; esac

if [ -z "$TARGET" ]; then
  printf 'install.sh: missing target repo directory.\n\n' >&2
  usage >&2
  exit 2
fi

# Resolve the target (must exist as a directory).
if [ ! -d "$TARGET" ]; then
  printf 'install.sh: target %q is not a directory. Create it (and `git init`) first.\n' "$TARGET" >&2
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SOURCE_DIR" ]; then
  printf 'install.sh: refusing to install into the pdda source repo itself.\n' >&2
  exit 1
fi

# True if TARGET is inside a git work tree. Uses `git rev-parse`, not a literal `.git` directory test,
# so it also handles worktrees and submodules (where `.git` is a FILE) and an external GIT_DIR.
is_git_repo() { git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

if ! is_git_repo; then
  printf 'install.sh: note — %q is not a git repo. PDDA works best under version control (changelog\n' "$TARGET" >&2
  printf '            freshness uses git history). Consider `git init` there.\n' >&2
fi

say() { printf '%s\n' "$*"; }

# Copy a runtime file verbatim, always (runtime is the shipped surface, safe to refresh).
copy_runtime() {  # <relpath>
  local rel="$1" src="$SOURCE_DIR/$1" dst="$TARGET/$1"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  say "  runtime   $rel"
}

# Portable in-place edit (BSD/GNU `sed -i` differ; avoid both via temp + mv). The temp lives BESIDE
# the target — no $TMPDIR dependency and the mv stays on one filesystem (atomic, no cross-device copy).
sed_inplace() {  # <file> <sed-args...>
  local f="$1"; shift
  local tmp="$f.pdda-mig.$$"
  sed "$@" "$f" > "$tmp" && mv "$tmp" "$f"
}

# Collapse a pre-utils/pdda/ FLAT install into the canonical subfolder layout. The runtime is already
# refreshed under utils/pdda/ by the time this runs, so here we (1) delete the now-duplicate PDDA-owned
# flat files and (2) repoint old flat-path references — never touching the repo's own utils/ files,
# the dated CHANGELOG, or the activity log. Idempotent: a no-op once there is no flat utils/pdda.sh.
migrate_flat_layout() {
  [ "$MIGRATE" -eq 1 ] || return 0
  [ -f "$TARGET/utils/pdda.sh" ] || return 0   # no flat entry point => nothing to migrate

  say ""
  say "Migrating pre-utils/pdda/ flat layout:"

  local f
  for f in utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh utils/pdda-catchup.sh \
           utils/PDDA-INSTALL.md PDDA-INSTALL.md; do
    if [ -f "$TARGET/$f" ]; then
      rm -f "$TARGET/$f"
      say "  remove    $f (now in utils/pdda/)"
    fi
  done
  if [ -d "$TARGET/utils/pdda-phase-out" ]; then
    rm -rf "$TARGET/utils/pdda-phase-out"
    say "  remove    utils/pdda-phase-out/ (legacy)"
  fi

  # Repoint old flat-path references. Candidate files come from `git ls-files` (tracked only — skips
  # node_modules/.venv and other untracked trees, and keeps the scan bounded); a non-git target falls
  # back to a pruned `find`. Either way we skip the target's own utils/ tree (never our files to edit),
  # the dated CHANGELOG, and machine logs — and only rewrite a file that actually contains an old path.
  local rel repointed=0
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    case "$rel" in
      utils/*|node_modules/*|.venv/*|vendor/*|CHANGELOG.md|*.jsonl) continue ;;
    esac
    grep -Iq -e 'utils/pdda\.sh' -e 'utils/pdda-lib\.sh' -e 'utils/pdda-doc-ready\.sh' \
      -e 'utils/pdda-catchup\.sh' -e 'utils/PDDA-INSTALL\.md' "$TARGET/$rel" 2>/dev/null || continue
    sed_inplace "$TARGET/$rel" \
      -e 's|utils/pdda\.sh|utils/pdda/pdda.sh|g' \
      -e 's|utils/pdda-lib\.sh|utils/pdda/pdda-lib.sh|g' \
      -e 's|utils/pdda-doc-ready\.sh|utils/pdda/pdda-doc-ready.sh|g' \
      -e 's|utils/pdda-catchup\.sh|utils/pdda/pdda-catchup.sh|g' \
      -e 's|utils/PDDA-INSTALL\.md|utils/pdda/PDDA-INSTALL.md|g'
    say "  repoint   $rel"
    repointed=$((repointed + 1))
  done < <(
    if is_git_repo; then
      git -C "$TARGET" ls-files -z
    else
      ( cd "$TARGET" && find . \( -name .git -o -name node_modules -o -name .venv -o -path './utils' \) -prune \
          -o -type f -print0 )
    fi
  )
  [ "$repointed" -eq 0 ] && say "  (no old-path references found)"
  say "  migration done — review with: git -C \"$TARGET\" diff"
}

# Create a seed file only if absent (or when --force). Reads content from stdin.
seed_file() {  # <relpath>  (content on stdin)
  local rel="$1" dst="$TARGET/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    say "  keep      $rel (exists; --force to overwrite)"
    cat >/dev/null   # drain stdin
    return
  fi
  cat > "$dst"
  say "  seed      $rel"
}

# Ensure PDDA's churning runtime state is gitignored in the target (the activity log and the gh-issue
# -state cache are regenerated output, not source — tracking them makes every run a dirty diff).
# Idempotent, so installs AND upgrades converge: adds each entry if missing, and untracks any that a
# pre-gitignore install already committed (a no-op for entries that were never tracked).
ensure_runtime_ignored() {
  local gi="$TARGET/.gitignore" entry
  for entry in "PROJECT/PDDA-ACTIVITY.jsonl" ".pdda-gh-state.tsv"; do
    if [ -f "$gi" ] && grep -qxF "$entry" "$gi"; then
      say "  keep      .gitignore ($entry already ignored)"
    else
      # Guarantee a trailing newline before appending so we never glue onto the prior last line.
      if [ -f "$gi" ] && [ -n "$(tail -c1 "$gi" 2>/dev/null)" ]; then printf '\n' >> "$gi"; fi
      printf '%s\n' "$entry" >> "$gi"
      say "  ignore    .gitignore += $entry"
    fi
    if is_git_repo && git -C "$TARGET" ls-files --error-unmatch "$entry" >/dev/null 2>&1; then
      if git -C "$TARGET" rm --cached --quiet "$entry" >/dev/null 2>&1; then
        say "  untrack   $entry (was tracked; git rm --cached)"
      fi
    fi
  done
}

# Publish a path-normalized projection of the registry into git-pulse's sync repo when git-pulse is present,
# so PDDA install status rolls up across devices with NO new sync infrastructure (git-pulse's own sync
# carries the file). Normalized = col 1 absolute path -> bare repo name; the projection never contains a
# filesystem path. Best-effort / fail-open (GUIDING-PRINCIPLES #6: never break an install); the local
# registry stays the source of truth (#4) and keeps absolute paths because pdda-sync.sh cd's into them.
# Rewritten in full every run, so the projection can't drift from the registry. A maintainer-LLM on another
# machine locates a repo by name (the file header carries the exact find command), not by a path we ship.
publish_registry_projection() {
  local gp="$PDDA_GITPULSE_DIR" dev cfg out
  [ -d "$gp/.git" ] || return 0   # no git-pulse checkout here -> nothing to roll up
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
  # Reuse git-pulse's own device id so PDDA and pulse files key on the same device; else fall back to host.
  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
  mkdir -p "$gp/pdda" 2>/dev/null || { say "  (git-pulse pdda/ not writable — publish skipped)"; return 0; }
  out="$gp/pdda/registry-$dev.tsv"
  # ponytail: registry paths are pwd-normalized (no trailing slash), so basename-via-split is safe.
  if {
       printf '# PDDA install status (normalized to repo name; absolute paths intentionally omitted).\n'
       printf '# Maintainer LLM on another machine: a clone usually keeps the origin repo name as its folder,\n'
       printf '# so locate it by exact name first:\n'
       printf '#   find ~ -type d -name "<repo>" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
       printf '# If that returns nothing (repo cloned into a renamed folder), fall back to a fuzzy search:\n'
       printf '#   find ~ -type d -iname "*<repo>*" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
       printf '# repo\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$PDDA_REGISTRY"
     } > "$out" 2>/dev/null; then
    say "  publish   pdda/registry-$dev.tsv (normalized; git-pulse carries it)"
  else
    say "  (git-pulse publish failed — skipped)"
  fi
  return 0
}

# Record this install in the per-user, per-device registry (one row per target, latest wins). This is
# the data pdda-sync.sh reads to find copies that are behind — recording source_commit means that layer
# needs no schema change. Machine-local; never committed. Best-effort: a failure here never fails the
# install. On success it also publishes the multi-device projection (publish_registry_projection).
register_install() {
  [ "$REGISTER" -eq 1 ] || return 0
  local reg="$PDDA_REGISTRY" dir
  dir="$(dirname "$reg")"
  mkdir -p "$dir" 2>/dev/null || { say "  (registry dir $dir not writable — skipped)"; return 0; }

  local ts src_commit sdocs row tmp
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  src_commit="$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  sdocs=$([ "$WITH_STARTUP_DOCS" -eq 1 ] && printf 'yes' || printf 'no')

  if [ ! -f "$reg" ]; then
    {
      printf '# PDDA install registry — per-user, per-device. Machine-local; do NOT commit.\n'
      printf '# target\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
    } > "$reg"
  fi

  # One row per target: drop any prior row for this exact path (tab-delimited col 1), then append fresh.
  # awk keeps comment lines (their col 1 never equals an absolute target path).
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$MODE" "$src_commit" "$sdocs")"
  tmp="$reg.tmp.$$"
  if awk -F'\t' -v t="$TARGET" '$1 != t' "$reg" > "$tmp" 2>/dev/null; then
    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
      say "  register  $TARGET -> $reg"
      publish_registry_projection   # best-effort multi-device rollup; never fails the install
    fi
  else
    rm -f "$tmp"
    say "  (registry write failed — skipped)"
  fi
}

say "Installing PDDA into: $TARGET"
say ""
say "Runtime + contract:"
# Copy exactly the shared manifest set (DRY with pdda-sync.sh), restoring the exec bit on scripts.
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  copy_runtime "$rel"
  case "$rel" in *.sh) chmod +x "$TARGET/$rel" ;; esac
done < <(pdda_manifest_expand "$SOURCE_DIR")

if [ "$WITH_STARTUP_DOCS" -eq 1 ]; then
  copy_runtime "ROUTER.md"
  copy_runtime "AGENTS.md"
  copy_runtime ".claude/skills/pdda/SKILL.md"
fi

migrate_flat_layout

say ""
say "Lifecycle buckets:"
for bucket in 1-INBOX 2-WORKING 3-COMPLETED 4-MISC; do
  seed_file "PROJECT/$bucket/blank.md" <<'BLANK'
<!-- placeholder so this lifecycle bucket exists in version control; PDDA checks ignore blank.md -->
BLANK
done

say ""
say "Zero-state seeds:"
TODAY="$(date +%Y-%m-%d)"

seed_file "ROADMAP.md" <<ROADMAP
<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by \`pdda.sh roadmap\` + \`pdda.sh roadmap-coverage\` (deterministic) + utils/pdda/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

# Roadmap

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked \`PROJECT/**\` docs; keep it there. See the contract banner above.

## Status

| What was just completed | What's next |
|---|---|
| Installed PDDA ($TODAY). | Open a \`PROJECT/**\` doc for the first tracked effort and add its pointer here. |

## Ledger

### Queue / parked intake

- No parked intake docs.

### In progress

- No active \`PROJECT/2-WORKING\` docs.

### Completed

- No completed docs.

### Deferred

- No deferred docs.

---

*Add new work here only when a real \`PROJECT/**\` doc exists to own the execution detail.*
ROADMAP

seed_file "CHANGELOG.md" <<CHANGELOG
# CHANGELOG.md

Newest-first, dated end-of-iteration record. One entry per substantive iteration: what changed,
why, and the verification. See \`PROJECT/PDDA.md\` for the full contract.

## $TODAY

### PDDA installed

- Installed the PDDA document-automation surface (\`utils/pdda/pdda.sh\` + helpers, \`PROJECT/PDDA.md\`)
  and the \`PROJECT/**\` lifecycle tree in \`observe\` mode.
- Next: replace this entry as real iterations land.

Verification: \`./utils/pdda/pdda.sh run\`
CHANGELOG

# Empty activity log (never copy the source repo's log).
seed_file "PROJECT/PDDA-ACTIVITY.jsonl" </dev/null

ensure_runtime_ignored

seed_file ".pdda-mode" <<MODE
$MODE
MODE

say ""
say "Registry:"
register_install

say ""
say "Verifying install (utils/pdda/pdda.sh run):"
say ""
case "$MODE" in
  observe) MODE_BLURB="report-only; graduate to light → full as you clear doc debt" ;;
  light)   MODE_BLURB="reports findings but never blocks; graduate to full when ready" ;;
  full)    MODE_BLURB="on rails — errors block with a non-zero exit" ;;
esac
if ( cd "$TARGET" && PDDA_MODE="$MODE" ./utils/pdda/pdda.sh run ); then
  say ""
  say "PDDA installed. Mode: $MODE ($MODE_BLURB)."
  say "Next: read PROJECT/PDDA.md, then start a doc in PROJECT/2-WORKING and point ROADMAP.md at it."
else
  say ""
  say "PDDA installed, but the first run reported findings or failed — see output above."
  case "$MODE" in
    observe|light) say "In $MODE mode this never blocks; review the findings and re-run ./utils/pdda/pdda.sh run." ;;
    full)          say "In full mode errors block (non-zero exit); review the findings and re-run ./utils/pdda/pdda.sh run." ;;
  esac
fi
