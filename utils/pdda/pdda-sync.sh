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

# --- engine helpers (Phase 2) --------------------------------------------------------------------

# Create the gitignored temp/ layout lazily (no tracked files).
ensure_tmp() { mkdir -p "$STATE_DIR" "$MANIFEST_SNAP_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"; }

# Append a timestamped line to the run log and echo it.
log_line() {  # <message>
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s %s\n' "$ts" "$*" | tee -a "$LOG_FILE"
}

# Portable content hash (first field of shasum).
hash_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# Portable mtime epoch.
mtime_epoch() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# Look up the last-synced source hash for a relpath in a per-target state file (empty if absent).
state_get() {  # <statefile> <rel>
  [ -f "$1" ] || return 0
  awk -F'\t' -v r="$2" '$1==r{print $2; exit}' "$1"
}

# mkdir-based lock with stale age-out.
acquire_lock() {
  ensure_tmp
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    local age now mt; now="$(date +%s)"; mt="$(mtime_epoch "$LOCK_DIR")"; age=$((now - mt))
    if [ "$age" -ge "${PDDA_SYNC_LOCK_STALE_S:-3600}" ]; then
      warn "pdda-sync: breaking stale lock (age ${age}s)"; rm -rf "$LOCK_DIR"; continue
    fi
    warn "pdda-sync: another run holds the lock ($LOCK_DIR, age ${age}s) — aborting"; return 1
  done
  printf '%s\n' "$$" > "$LOCK_DIR/pid" 2>/dev/null || true
}
release_lock() { rm -rf "$LOCK_DIR"; }

# Refuse to push from a dirty HQ (any manifest file modified/staged). Returns 1 if dirty.
dirty_source_check() {  # manifest on stdin
  git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local rel dirty=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    if [ -n "$(git -C "$SOURCE_DIR" status --porcelain -- "$rel" 2>/dev/null)" ]; then
      warn "  dirty source file: $rel"; dirty=1
    fi
  done
  return "$dirty"
}

# First declared `dir` root that resolves to zero tracked files (poisoning signal), else empty.
manifest_zero_root() {
  local conf line kind arg; conf="$(pdda_manifest_conf_path "$SOURCE_DIR")"
  [ -f "$conf" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    kind="${line%%[[:space:]]*}"; arg="${line#"$kind"}"
    arg="${arg#"${arg%%[![:space:]]*}"}"; arg="${arg%/}"
    [ "$kind" = dir ] || continue
    if git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      [ -z "$(git -C "$SOURCE_DIR" ls-files -- "$arg")" ] && { printf '%s\n' "$arg"; return 0; }
    else
      [ -d "$SOURCE_DIR/$arg" ] || { printf '%s\n' "$arg"; return 0; }
    fi
  done < "$conf"
  return 1
}

# Keep only the newest N backup snapshots for a target.
prune_backups() {  # <slug>
  local d="$BACKUP_DIR/$1" n="${PDDA_SYNC_BACKUPS:-5}" count
  [ -d "$d" ] || return 0
  count="$(ls -1 "$d" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" -le "$n" ] && return 0
  ls -1 "$d" | LC_ALL=C sort | head -n "$((count - n))" | while IFS= read -r old; do
    [ -n "$old" ] && rm -rf "$d/$old"
  done
}

# --- subcommands ---------------------------------------------------------------------------------

# manifest — print the expanded synced file set (debug / parity check with install.sh).
cmd_manifest() { pdda_manifest_expand "$SOURCE_DIR"; }

# push [<target>] — distribute the current runtime to one target (or all registered).
cmd_push() {
  local DRY=0 ALLOW_DIRTY=0 NO_DELETE=0 FORCE_DELETE=0 ONE_TARGET=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY=1; shift ;;
      --allow-dirty) ALLOW_DIRTY=1; shift ;;
      --no-delete) NO_DELETE=1; shift ;;
      --force-delete) FORCE_DELETE=1; shift ;;
      --target) ONE_TARGET="${2:-}"; shift 2 ;;
      -*) warn "push: unknown option $1"; return 2 ;;
      *) ONE_TARGET="$1"; shift ;;
    esac
  done

  # Current expanded manifest (the set to push). Empty ⇒ refuse outright.
  local CUR_MANIFEST cur_count
  CUR_MANIFEST="$(pdda_manifest_expand "$SOURCE_DIR")" || { warn "push: manifest expand failed"; return 1; }
  cur_count="$(printf '%s\n' "$CUR_MANIFEST" | grep -c . || true)"
  if [ "$cur_count" -eq 0 ]; then warn "push: expanded manifest is empty — refusing to push nothing"; return 1; fi

  # Dirty-source guard.
  if [ "$ALLOW_DIRTY" -eq 0 ]; then
    if ! printf '%s\n' "$CUR_MANIFEST" | dirty_source_check; then
      warn "push: HQ has uncommitted changes to manifest files — commit them or pass --allow-dirty"; return 1
    fi
  fi

  # Global poisoning signal: a declared root resolving to zero tracked files blocks deletes (unless forced).
  local zero_root deletes_blocked=0
  zero_root="$(manifest_zero_root || true)"
  if [ -n "$zero_root" ]; then
    if [ "$FORCE_DELETE" -eq 1 ]; then
      warn "push: manifest-poisoning — root '$zero_root' resolves to zero files (overridden by --force-delete)"
    else
      deletes_blocked=1
      warn "push: manifest-poisoning — root '$zero_root' resolves to zero files; DELETES blocked (pass --force-delete)"
    fi
  fi

  # Targets.
  local -a targets=()
  if [ -n "$ONE_TARGET" ]; then
    [ -d "$ONE_TARGET" ] || { warn "push: target is not a directory: $ONE_TARGET"; return 1; }
    targets=( "$(cd "$ONE_TARGET" && pwd)" )
  else
    local t; while IFS= read -r t; do [ -n "$t" ] && targets+=( "$t" ); done < <(registry_targets)
    [ "${#targets[@]}" -eq 0 ] && { say "push: no registered targets (register one first)"; return 0; }
  fi

  acquire_lock || return 1
  # shellcheck disable=SC2064
  trap 'release_lock' EXIT INT TERM

  local MAX_SHRINK="${PDDA_SYNC_MAX_SHRINK:-25}"
  local n_new=0 n_upd=0 n_updb=0 n_skip=0 n_del=0 n_miss=0
  local utc; utc="$(date -u +%Y%m%dT%H%M%SZ)"
  [ "$DRY" -eq 1 ] && log_line "push START (dry-run) — ${#targets[@]} target(s), $cur_count manifest files" \
                    || log_line "push START — ${#targets[@]} target(s), $cur_count manifest files"

  local tgt slug statefile snapfile newstate rel src tgt_f src_hash tgt_hash last
  for tgt in "${targets[@]}"; do
    if [ ! -d "$tgt" ]; then log_line "  MISSING target (skip): $tgt"; n_miss=$((n_miss+1)); continue; fi
    slug="$(slug_for "$tgt")"; statefile="$STATE_DIR/$slug.tsv"; snapfile="$MANIFEST_SNAP_DIR/$slug.tsv"
    newstate="$(mktemp)"; : > "$newstate"
    log_line "  TARGET $tgt"

    # ---- copy / update phase ----
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$SOURCE_DIR/$rel"; tgt_f="$tgt/$rel"; src_hash="$(hash_file "$src")"
      if [ ! -e "$tgt_f" ]; then
        if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$tgt_f")"; cp "$src" "$tgt_f.pdda-tmp" && mv "$tgt_f.pdda-tmp" "$tgt_f"; case "$rel" in *.sh) chmod +x "$tgt_f" ;; esac; fi
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; log_line "    new        $rel"; n_new=$((n_new+1)); continue
      fi
      tgt_hash="$(hash_file "$tgt_f")"; last="$(state_get "$statefile" "$rel")"
      if [ -n "$last" ] && [ "$src_hash" = "$last" ]; then
        printf '%s\t%s\n' "$rel" "$last" >> "$newstate"; n_skip=$((n_skip+1)); continue   # source unchanged → leave target
      fi
      if [ "$src_hash" = "$tgt_hash" ]; then
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; n_skip=$((n_skip+1)); continue   # already identical → just stamp
      fi
      # source advanced; decide backup based on whether target diverged from last stamp
      if [ -n "$last" ] && [ "$tgt_hash" != "$last" ]; then
        if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$BACKUP_DIR/$slug/$utc/$rel")"; cp "$tgt_f" "$BACKUP_DIR/$slug/$utc/$rel"; fi
        if [ "$DRY" -eq 0 ]; then cp "$src" "$tgt_f.pdda-tmp" && mv "$tgt_f.pdda-tmp" "$tgt_f"; case "$rel" in *.sh) chmod +x "$tgt_f" ;; esac; fi
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; log_line "    updated+bak $rel"; n_updb=$((n_updb+1))
      else
        if [ "$DRY" -eq 0 ]; then cp "$src" "$tgt_f.pdda-tmp" && mv "$tgt_f.pdda-tmp" "$tgt_f"; case "$rel" in *.sh) chmod +x "$tgt_f" ;; esac; fi
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; log_line "    updated    $rel"; n_upd=$((n_upd+1))
      fi
    done <<EOF
$CUR_MANIFEST
EOF

    # ---- delete-mirror phase ----
    # pending_del = removals we did NOT perform this run (no-delete or poison-blocked). They stay in the
    # snapshot so a later run (e.g. --force-delete) still detects them — never silently forgotten.
    local pending_del=""
    if [ -f "$snapfile" ]; then
      local prev_count removed
      prev_count="$(grep -c . "$snapfile" 2>/dev/null || echo 0)"
      # paths that were in the previous snapshot but are gone from the current manifest
      removed="$(comm -23 <(LC_ALL=C sort -u "$snapfile") <(printf '%s\n' "$CUR_MANIFEST" | LC_ALL=C sort -u) 2>/dev/null || true)"
      if [ -n "$removed" ]; then
        local block=0
        if [ "$NO_DELETE" -eq 1 ]; then
          block=1; log_line "    (--no-delete: deletions deferred, kept in snapshot)"
        elif [ "$deletes_blocked" -eq 1 ]; then
          block=1; log_line "    (delete phase blocked by zero-root poisoning — pass --force-delete)"
        elif [ "$prev_count" -gt 0 ]; then
          local shrink=$(( (prev_count - cur_count) * 100 / prev_count ))
          if [ "$shrink" -gt "$MAX_SHRINK" ] && [ "$FORCE_DELETE" -eq 0 ]; then
            block=1; log_line "    POISON: manifest shrank ${shrink}% (>${MAX_SHRINK}%) — deletes blocked (pass --force-delete)"
          fi
        fi
        if [ "$block" -eq 1 ]; then
          pending_del="$removed"
        else
          while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            tgt_f="$tgt/$rel"
            if [ -e "$tgt_f" ]; then
              if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$BACKUP_DIR/$slug/$utc/$rel")"; cp "$tgt_f" "$BACKUP_DIR/$slug/$utc/$rel" && rm -f "$tgt_f"; fi
              log_line "    deleted+bak $rel"; n_del=$((n_del+1))
            fi
          done <<EOF
$removed
EOF
        fi
      fi
    fi

    # ---- persist state + manifest snapshot (skip on dry-run) ----
    # Snapshot = current manifest PLUS any deferred deletions, so deletion tracking survives a blocked run.
    if [ "$DRY" -eq 0 ]; then
      mv "$newstate" "$statefile"
      if [ -n "$pending_del" ]; then
        printf '%s\n%s\n' "$CUR_MANIFEST" "$pending_del" | grep . | LC_ALL=C sort -u > "$snapfile"
      else
        printf '%s\n' "$CUR_MANIFEST" | grep . | LC_ALL=C sort -u > "$snapfile"
      fi
      prune_backups "$slug"
    else
      rm -f "$newstate"
    fi
  done

  release_lock; trap - EXIT INT TERM
  local drynote=""; [ "$DRY" -eq 1 ] && drynote=" (dry-run: nothing written)"
  log_line "push DONE — new=$n_new updated=$n_upd updated+bak=$n_updb skip=$n_skip deleted=$n_del missing=$n_miss$drynote"
  return 0
}

# list — show registered targets (Phase 1: plain list; Phase 3 adds last-push summary from the log).
cmd_list() {
  local any=0 t
  while IFS= read -r t; do any=1; say "$t"; done < <(registry_targets)
  [ "$any" -eq 0 ] && return 0
  return 0
}

# Stubs filled in by later phases — fail loudly rather than silently no-op.
not_yet() { warn "pdda-sync.sh: '$1' is not implemented yet (planned: $2)"; return 3; }
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
