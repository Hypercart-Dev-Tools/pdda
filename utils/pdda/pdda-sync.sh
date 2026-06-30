#!/usr/bin/env bash
set -euo pipefail

# pdda-sync.sh — distribute this HQ clone's PDDA runtime to registered target repos.
#
# HQ (this clone) is the single source of truth and the only writer. `register` enrolls a target and
# does the initial install (delegating to install.sh, which is the SOLE registry writer). `push` is the
# steady-state distributor: it copies files whose content has advanced and mirrors HQ-side deletions —
# always backing up the target's version first. A launchd job (install-agent) is an OPTIONAL wrapper
# over `push`.
#
# The synced file set is the auto-regenerated manifest (utils/pdda/pdda-sync-manifest.conf, expanded by
# pdda-manifest.sh) — shared with install.sh so the set is defined in exactly one place.
#
# See PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md for the full design.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$HERE/../.." && pwd)"   # HQ repo root
# shellcheck source=utils/pdda/pdda-manifest.sh
. "$HERE/pdda-manifest.sh"

# Per-user, per-device registry (written by install.sh; pdda-sync.sh only READS it). Same default path
# and override knob as install.sh so the two agree without coordination.
PDDA_REGISTRY="${PDDA_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv}"

# Gitignored HQ-side runtime state (created lazily, never tracked).
SYNC_TMP="${PDDA_SYNC_TMP:-$SOURCE_DIR/temp}"
STATE_DIR="$SYNC_TMP/pdda-sync-state"
MANIFEST_SNAP_DIR="$SYNC_TMP/pdda-sync-manifest"
BACKUP_DIR="$SYNC_TMP/pdda-sync-backups"
LOG_FILE="$SYNC_TMP/pdda-sync.log"
LOCK_DIR="$SYNC_TMP/pdda-sync.lock"

say() { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }

# --- registry read helpers (READ-ONLY — install.sh owns all writes) ------------------------------

# Print every registered target path (col 1), skipping comments + blank lines.
registry_targets() {
  [ -f "$PDDA_REGISTRY" ] || return 0
  awk -F'\t' '!/^#/ && NF>0 && $1!="" {print $1}' "$PDDA_REGISTRY"
}

# True if a given absolute path is registered.
registry_has() {  # <target>
  local t
  while IFS= read -r t; do [ "$t" = "$1" ] && return 0; done < <(registry_targets)
  return 1
}

# Sanitize a target path into a filename-safe slug for per-target state/backup files.
slug_for() {  # <target>
  printf '%s' "$1" | tr '/ ' '__' | tr -cd 'A-Za-z0-9_.-'
}

# --- subcommands ---------------------------------------------------------------------------------

# manifest — print the expanded synced file set (debug / parity check with install.sh).
cmd_manifest() { pdda_manifest_expand "$SOURCE_DIR"; }

# list — show registered targets (Phase 1: plain list; Phase 3 adds last-push summary from the log).
cmd_list() {
  local any=0 t
  while IFS= read -r t; do any=1; say "$t"; done < <(registry_targets)
  [ "$any" -eq 0 ] && return 0
  return 0
}

# Stubs filled in by later phases — fail loudly rather than silently no-op.
not_yet() { warn "pdda-sync.sh: '$1' is not implemented yet (planned: $2)"; return 3; }
cmd_push()            { not_yet push "Phase 2"; }
cmd_register()        { not_yet register "Phase 3"; }
cmd_status()          { not_yet status "Phase 3"; }
cmd_remove()          { not_yet remove "Phase 3"; }
cmd_prune()           { not_yet prune "Phase 3"; }
cmd_install_agent()   { not_yet install-agent "Phase 4"; }
cmd_uninstall_agent() { not_yet uninstall-agent "Phase 4"; }

usage() {
  cat <<'USAGE'
pdda-sync.sh — distribute the PDDA runtime from HQ to registered target repos.

Usage: pdda-sync.sh <command> [options]

Commands:
  register <dir>     Enroll a target repo + initial install (delegates to install.sh). [Phase 3]
  push [<dir>]       Distribute current runtime to one target, or all if omitted.      [Phase 2]
  list               List registered targets.
  status [<dir>]     Per-target behind/current/diverged summary.                       [Phase 3]
  remove <dir>       De-register a target (keeps its files).                            [Phase 3]
  prune              Drop registry entries whose directory is gone.                     [Phase 3]
  manifest           Print the expanded synced file set (parity/debug).
  install-agent      Install the optional launchd schedule around `push`.              [Phase 4]
  uninstall-agent    Remove the launchd schedule.                                      [Phase 4]
  help               This message.

The registry is machine-local at ${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv (override with
PDDA_REGISTRY) and is written only by install.sh. State/backups live under temp/ (override PDDA_SYNC_TMP).
USAGE
}

cmd="${1:-help}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
  register)        cmd_register "$@" ;;
  push)            cmd_push "$@" ;;
  list)            cmd_list "$@" ;;
  status)          cmd_status "$@" ;;
  remove)          cmd_remove "$@" ;;
  prune)           cmd_prune "$@" ;;
  manifest)        cmd_manifest "$@" ;;
  install-agent)   cmd_install_agent "$@" ;;
  uninstall-agent) cmd_uninstall_agent "$@" ;;
  help|-h|--help)  usage ;;
  *)               warn "pdda-sync.sh: unknown command $cmd"; usage >&2; exit 2 ;;
esac
