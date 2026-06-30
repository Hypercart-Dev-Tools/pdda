---
title: Multi-device PDDA install status — piggyback git-pulse's sync repo (new folder)
status: Completed (2026-06-30 — Iteration 1 wired into install.sh; 10/10 publish test green; today's ledger backfilled)
created: 2026-06-30
updated: 2026-06-30
owner: noel
goal: >
  Give the per-device, machine-local PDDA install registry a multi-device rollup without building any new
  sync infrastructure, by dropping a read-only copy of each device's registry into a new `pdda/` folder
  inside git-pulse's already-multi-device, GitHub-backed sync repo and letting git-pulse's EXISTING sync
  carry it. The local ~/.config/pdda/registry.tsv stays the source of truth (install.sh remains its sole
  writer); the git-pulse folder holds only a published copy for cross-device "where is PDDA installed, at
  what source commit" viewing.
branch: main
gh_issue: pending (gh auth re-login required; rename this doc to GH-<n>-… once the issue exists)
---

## Status

| What was just completed | What's next |
|---|---|
| **Iteration 1 built and shipped.** `publish_registry_projection()` added to `install.sh` and called from `register_install()` on every successful install/upgrade: when git-pulse is present it writes a path-normalized `pdda/registry-<device>.tsv` (bare repo name + date + source commit + mode; no absolute paths), carried by git-pulse's own sync. Best-effort/fail-open. Key = bare repo name with an exact-then-fuzzy maintainer `find` note. Backfilled today's ledger by hand earlier; this makes it automatic going forward. | Nothing committed remaining. Deferred (YAGNI, reopen if needed): a `roster` aggregation read and folding the projection into `pdda-sync.sh status`. |

## Design (post-ponytail)

**One best-effort, normalized copy, folded into the install path PDDA already runs.** `install.sh`'s
`register_install()` already runs on every install/upgrade and already best-effort writes the local
registry. Add to it: if git-pulse's repo dir exists, write a **path-normalized projection** of the registry
into its `pdda/` folder under a per-device name. That's the whole feature.

Normalization = col 1 (absolute target path) → **bare repo name**. The projection carries repo name +
version status only; no absolute paths. (See "Why normalize" below.)

```sh
# in register_install(), after the local registry row is written — best-effort, fail-open.
# Projection only: the LOCAL registry keeps absolute paths (the sync engine cd's into them).
gp="${PDDA_GITPULSE_DIR:-$HOME/.config/git-pulse/repo}"
if [ -d "$gp/.git" ]; then
  dev="$( ( . "$HOME/.config/git-pulse/config.sh" 2>/dev/null; printf '%s' "${device_id:-$(hostname -s)}" ) )"
  mkdir -p "$gp/pdda" && {
    printf '# PDDA install status (normalized to repo name; absolute paths intentionally omitted).\n'
    printf '# Maintainer LLM on another machine: a clone usually keeps the origin repo name as its folder,\n'
    printf '# so locate it by exact name first:\n'
    printf '#   find ~ -type d -name "<repo>" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
    printf '# If that returns nothing (repo cloned into a renamed folder), fall back to a fuzzy search:\n'
    printf '#   find ~ -type d -iname "*<repo>*" -exec test -d "{}/.git" \\; -print 2>/dev/null\n'
    printf '# repo\tlast_install_utc\tmode\tsource_commit\tstartup_docs\n'
    awk -F'\t' '!/^#/ && NF { n=split($1,a,"/"); print a[n]"\t"$2"\t"$3"\t"$4"\t"$5 }' "$reg"
  } > "$gp/pdda/registry-$dev.tsv" && say "  publish   pdda/registry-$dev.tsv (normalized; git-pulse carries it)" || true
fi
```

- **Per-device filename** (mirrors git-pulse's own `pulse-<device>.md`) → conflict-free git merges; each
  device only writes its own file.
- **git-pulse carries it** → no `git add/commit/push` in PDDA. Cadence = git-pulse's existing sweep.
- **Fail-open** → no git-pulse on this machine, or the write fails → silent no-op, install unaffected. Same
  posture as the existing best-effort registry write.
- `# ponytail: bare basename as the project key — matches git-pulse's convention. Two different repos
  sharing a basename collapse to one row; switch the key to the git remote slug only if that ever bites.`

## Why normalize (repo name only, no absolute paths)

- The rollup answers "which **project** is on which PDDA source commit, per device" — the join key is the
  project, not a filesystem path. Bare repo name is the natural key and reads cleanly in the maintainer's
  folder-search note.
- Absolute paths add nothing to that question and would leak each machine's directory layout. We're not
  using this data for a security audit, but there's no reason to publish paths we don't need.
- A maintainer-LLM updating PDDA on another machine doesn't need our path — it finds the repo locally by
  name (the file header carries the exact `find` command).
- **Publish-only.** The local `~/.config/pdda/registry.tsv` keeps absolute paths unchanged — `pdda-sync.sh`
  needs them to locate and update targets. The projection is lossy *by design*; the source of truth is not.

## Published file schema (`pdda/registry-<device>.tsv`)

```
# PDDA install status (normalized to repo name; absolute paths intentionally omitted).
# Maintainer LLM on another machine: a clone usually keeps the origin repo name as its folder,
# so locate it by exact name first:
#   find ~ -type d -name "<repo>" -exec test -d "{}/.git" \; -print 2>/dev/null
# If that returns nothing (repo cloned into a renamed folder), fall back to a fuzzy search:
#   find ~ -type d -iname "*<repo>*" -exec test -d "{}/.git" \; -print 2>/dev/null
# repo            last_install_utc      mode     source_commit  startup_docs
rebalance-OS      2026-06-30T14:55:14Z  observe  5b6e8dc        no
xyz-3-agents-swarm 2026-06-30T15:02:07Z observe  5b6e8dc        no
```

## Authority (spike-360): read-projection only

The local `~/.config/pdda/registry.tsv` stays authoritative; install.sh stays its sole writer. The
`pdda/` folder is a published *copy* nothing reads back to drive installs. No schema change, no rigor owed —
it's a projection, which is exactly why the implementation can be this thin.

## What ponytail cut (was in the first draft)

- **A `pdda-sync.sh publish` subcommand** — skipped; it's a copy on a path PDDA already walks. A separate
  command you must remember to run is a manual ops step, not laziness.
- **PDDA-side git add/commit/push + cadence logic** — skipped; git-pulse's sync already commits+pushes its
  repo. Add only if PDDA ever needs git-pulse-independent publishing.
- **A `roster` aggregation read + `pdda-sync.sh status` integration** — skipped (YAGNI). The per-device
  files land merged in the private repo; viewing = the `pdda/` folder on GitHub, or
  `cat ~/.config/git-pulse/repo/pdda/registry-*.tsv`. Build a `roster` command only if eyeballing the
  folder proves too coarse.
- **Device-id fallback chains** — collapsed to: reuse git-pulse's own `device_id`, else `hostname -s`.

## Anti-goals

- Not moving/duplicating the source of truth (local registry stays authoritative, keeps absolute paths).
- Not publishing absolute paths — the projection is repo name + date + build hash + mode only.
- Not commingling with `pulse-*.md` — PDDA data stays in its own `pdda/` folder.
- Not building any sync transport, daemon, command, or git logic — reuse git-pulse's.
- Not making PDDA hard-depend on git-pulse — the copy is best-effort and fail-open.

## Reversibility

Trivial. Iteration 1 is ~5 fail-open lines in one function plus a folder in an external private repo.
Undo = delete the block and `git rm -r pdda/`. install.sh's registry write path is untouched.

## Iteration 1 check (when built)

One assert: with `PDDA_GITPULSE_DIR` pointed at a non-existent dir, `register_install()` still exits 0 and
writes the local registry (proves fail-open). Trivial copy logic needs nothing more.
