---
title: install.sh — auto-detect git-pulse repo path for the registry projection
status: Implemented (2026-06-30 — fix + test + lockstep docs landed on branch fix/gh-7-gitpulse-path-autodetect; verified 17/17 + real-world; pending merge/close)
created: 2026-06-30
updated: 2026-06-30
owner: noel
gh_issue: 7
goal: >
  Make publish_registry_projection() find git-pulse's sync repo even when it is not at the hardcoded
  default (~/.config/git-pulse/repo). Resolve in priority order: explicit PDDA_GITPULSE_DIR override →
  sync_repo_dir from git-pulse's own config.sh (which install.sh already sources for device_id) →
  a small candidate list. Keeps the projection best-effort / fail-open; no git-pulse-side change.
branch: fix/gh-7-gitpulse-path-autodetect
non_goals: >
  Not changing the local registry (source of truth, absolute paths) at ~/.config/pdda/registry.tsv.
  Not adding a new command or any PDDA-side git/commit/push logic. Not touching the git-pulse repo.
  Not removing the PDDA_GITPULSE_DIR override or the "point at a nonexistent path to disable" escape hatch.
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-7 — Auto-detect git-pulse repo path for the registry projection

## Status

| What was just completed | What's next |
|---|---|
| Fix landed on branch `fix/gh-7-gitpulse-path-autodetect` (atop newest main `05862e1`): `publish_registry_projection()` resolves the git-pulse path via override → `config.sh` `sync_repo_dir` → candidate list; lockstep updated (`install.sh` comment/usage + `PDDA-INSTALL.md` step 4c); `CHANGELOG.md` recorded. Verified: `test/pdda-publish-projection.sh` 17/17 (new Case 4), `bash -n` clean, and a real-world plain `./install.sh` (no override) on `noels-mac-studio` re-published the deleted projection. | Operator: merge branch to `main`, push, close issue [#7](https://github.com/Hypercart-Dev-Tools/pdda/issues/7); on merge, move this doc to `PROJECT/3-COMPLETED/` and shift its ROADMAP pointer to Completed. |

## Problem

On install, the per-device registry projection (`<git-pulse-repo>/pdda/registry-<device>.tsv`) is only
written when git-pulse is found at `$PDDA_GITPULSE_DIR` (default `~/.config/git-pulse/repo`). When the
sync checkout lives elsewhere, the publish step fail-opens (returns 0) and nothing rolls up — silently.
The local registry is still written, so the failure is invisible until you look for the projection.

## Fix

In `publish_registry_projection()`, resolve `gp` in priority order:

1. **Explicit `PDDA_GITPULSE_DIR`** (if the caller set it) — honored as-is.
2. **`sync_repo_dir`** sourced from `${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh`
   (the same file already sourced for `device_id`).
3. **Candidate list** — first existing of `~/.config/git-pulse/repo`, `~/git-pulse-sync`.
4. Final gate `[ -d "$gp/.git" ] || return 0` unchanged → still best-effort / fail-open.

To make the override distinguishable from the default, the top-level default assignment becomes empty
(`PDDA_GITPULSE_DIR="${PDDA_GITPULSE_DIR:-}"`) and resolution moves into the function (in the existing
subshell that already sources `config.sh`).

## Verification

- On `noels-mac-studio`: `./install.sh <repo>` **without** any env override writes
  `~/git-pulse-sync/pdda/registry-noels-mac-studio.tsv`.
- `utils/pdda/pdda.sh run` clean.
- Behavior unchanged on a device where `~/.config/git-pulse/repo` already exists (candidate #1 still hits).
