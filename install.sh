#!/usr/bin/env bash
set -euo pipefail

# PDDA installer — drop the Project-Driven Doc Automation surface into ANOTHER repo in a clean,
# ready-to-use "zero state". Run it from a clone of the pdda repo:
#
#   ./install.sh /path/to/your-repo
#
# It copies the shipped runtime (the 4 canonical files), creates the PROJECT/** lifecycle tree,
# and SYNTHESES blank seed ledger/changelog/activity/mode files — it never copies this repo's own
# ROADMAP/CHANGELOG/activity content, so the target starts empty but immediately valid. Existing
# target files are never clobbered unless you pass --force.
#
# This is the executable form of utils/PDDA-INSTALL.md; keep the two in lockstep.

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORCE=0
WITH_STARTUP_DOCS=0
MODE="observe"
TARGET=""

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
  --mode <m>             Initial .pdda-mode: observe (default) | light | full.
  -h, --help             This message.

What gets installed (zero state):
  utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh   (runtime, refreshed)
  PROJECT/PDDA.md                                            (the contract, refreshed)
  PROJECT/{1-INBOX,2-WORKING,3-COMPLETED,4-MISC}/blank.md    (lifecycle buckets)
  ROADMAP.md CHANGELOG.md PROJECT/PDDA-ACTIVITY.jsonl .pdda-mode   (blank seeds, create-only)

After install it runs `utils/pdda.sh run` in the target so you see it working immediately.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --with-startup-docs) WITH_STARTUP_DOCS=1; shift ;;
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

if [ ! -d "$TARGET/.git" ]; then
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

say "Installing PDDA into: $TARGET"
say ""
say "Runtime + contract:"
copy_runtime "utils/pdda.sh"
copy_runtime "utils/pdda-lib.sh"
copy_runtime "utils/pdda-doc-ready.sh"
copy_runtime "PROJECT/PDDA.md"
chmod +x "$TARGET/utils/pdda.sh" "$TARGET/utils/pdda-lib.sh" "$TARGET/utils/pdda-doc-ready.sh"

if [ "$WITH_STARTUP_DOCS" -eq 1 ]; then
  copy_runtime "ROUTER.md"
  copy_runtime "AGENTS.md"
  copy_runtime ".claude/skills/pdda/SKILL.md"
fi

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
     Enforced by \`pdda.sh roadmap\` + \`pdda.sh roadmap-coverage\` (deterministic) + utils/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

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

- Installed the PDDA document-automation surface (\`utils/pdda.sh\` + helpers, \`PROJECT/PDDA.md\`)
  and the \`PROJECT/**\` lifecycle tree in \`observe\` mode.
- Next: replace this entry as real iterations land.

Verification: \`./utils/pdda.sh run\`
CHANGELOG

# Empty activity log (never copy the source repo's log).
seed_file "PROJECT/PDDA-ACTIVITY.jsonl" </dev/null

seed_file ".pdda-mode" <<MODE
$MODE
MODE

say ""
say "Verifying install (utils/pdda.sh run):"
say ""
case "$MODE" in
  observe) MODE_BLURB="report-only; graduate to light → full as you clear doc debt" ;;
  light)   MODE_BLURB="reports findings but never blocks; graduate to full when ready" ;;
  full)    MODE_BLURB="on rails — errors block with a non-zero exit" ;;
esac
if ( cd "$TARGET" && PDDA_MODE="$MODE" ./utils/pdda.sh run ); then
  say ""
  say "PDDA installed. Mode: $MODE ($MODE_BLURB)."
  say "Next: read PROJECT/PDDA.md, then start a doc in PROJECT/2-WORKING and point ROADMAP.md at it."
else
  say ""
  say "PDDA installed, but the first run reported findings or failed — see output above."
  say "In observe mode this never blocks; review the findings and re-run ./utils/pdda.sh run."
fi
