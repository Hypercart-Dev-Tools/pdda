#!/usr/bin/env bash
# pdda-gh-release-sync.sh — refresh the cached GitHub release-state file that
# `pdda.sh release-readiness` reads when `gh` is offline.
#
# Parallel to pdda-gh-refresh.sh (which caches issue state); same cadence, same degrade model.
# Calls `gh release list --json tagName` once and writes PDDA_GH_RELEASE_CACHE (default:
# <repo>/.pdda-gh-release-state.tsv, gitignored) ATOMICALLY. On any gh failure the existing cache
# is left untouched and the script exits non-zero, so a cron wrapper can log the miss without
# clobbering good data with an empty file.
#
# Cadence: same hourly schedule as pdda-gh-refresh.sh, BEFORE the deterministic suite.
# One-off: `utils/pdda/pdda-gh-release-sync.sh` or `utils/pdda/pdda.sh gh-release-sync`.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh"

main() {
  if ! command -v gh >/dev/null 2>&1; then
    printf 'pdda-gh-release-sync: gh not found — cache not refreshed (%s left as-is)\n' \
      "$(pdda_relpath "$PDDA_GH_RELEASE_CACHE")" >&2
    return 3
  fi

  local table
  if ! table="$(_pdda_gh_release_table)"; then
    printf 'pdda-gh-release-sync: `gh release list` failed (unauthenticated or offline) — cache left as-is\n' >&2
    pdda_log_activity warn "pdda-gh-release-sync" "$PDDA_GH_RELEASE_CACHE" 0 \
      "gh release list failed; cache not refreshed" "skip"
    return 4
  fi

  if ! pdda_write_gh_release_cache "$table"; then
    printf 'pdda-gh-release-sync: could not write cache to %s\n' "$(pdda_relpath "$PDDA_GH_RELEASE_CACHE")" >&2
    return 5
  fi

  local count=0
  [ -n "$table" ] && count="$(printf '%s\n' "$table" | grep -c .)"
  printf 'pdda-gh-release-sync: wrote %s release(s) to %s\n' "$count" "$(pdda_relpath "$PDDA_GH_RELEASE_CACHE")"
  pdda_log_activity info "pdda-gh-release-sync" "$PDDA_GH_RELEASE_CACHE" 0 \
    "refreshed gh-release-state cache ($count releases)" "refresh"
}

main "$@"
