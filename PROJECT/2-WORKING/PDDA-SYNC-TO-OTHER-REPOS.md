---
title: Sync the PDDA runtime to other repos (initial copy + 30-min auto-update)
status: Active
created: 2026-06-27
updated: 2026-06-27
owner: noel
goal: >
  Let one canonical PDDA source repo push its utils/pdda/ runtime into other registered repos —
  an initial install/update on registration, then a launchd job every 30 minutes that re-copies
  only files whose content has actually changed, backing up the target's version first. The set of
  synced repos lives in a gitignored registry under temp/.
branch: pdda-sync-to-other-repos
gh_issue: pending (open once scope is approved; rename this doc to GH-<n>-… then)
non_goals: >
  Not a two-way sync, not a git submodule/subtree, not a package manager, not a remote/cross-machine
  service. Source of truth is always this local clone's utils/pdda/.
effort: 3
complexity: 3
risk: 2
phases: 5
---

## Status

| What was just completed | What's next |
|---|---|
| Wrote this phased plan, resolved all five open questions (see [Resolved decisions](#resolved-decisions)), and ran a Codex QA review — applied its valid finding (dirty-guard now manifest-driven so `PROJECT/PDDA.md` is covered); rejected a false-positive "blocker" that misread the repo. | Build Phase 1 (registry + manifest + state model). Open question still pending: GH issue intake. |

## Table of contents

- [Phase 1 — Registry, manifest & state model](#phase-1--registry-manifest--state-model)
- [Phase 2 — Sync engine (`pdda-sync.sh run`)](#phase-2--sync-engine-pdda-syncsh-run)
- [Phase 3 — `register` / initial sync (reuse `install.sh`) + `list` / `remove` / `prune`](#phase-3--register--initial-sync-reuse-installsh--list--remove--prune)
- [Phase 4 — launchd scheduler (30-minute job)](#phase-4--launchd-scheduler-30-minute-job)
- [Phase 5 — Docs + dogfood verification](#phase-5--docs--dogfood-verification)

## Context

`install.sh` already copies the `utils/pdda/` runtime into a target repo's `utils/pdda/`. So the
"initial sync (new copy or update)" is **not new code** — it is `install.sh` plus *registering* the
target. What is new is the **steady-state** layer: a registry of repos that opted in, and a scheduled
job that keeps each one current as the source runtime evolves.

The four locked decisions:

- **Scheduler:** macOS `launchd` LaunchAgent (native, survives reboot/login; one job iterates the whole
  registry).
- **Drift policy:** backup-then-overwrite — the source is canonical, but the target's current file is
  saved before it is replaced, so nothing is ever destroyed irrecoverably.
- **Change detection:** content hash (`shasum`), not mtime. `git` checkouts reset mtimes, so a
  date-based rule misfires; hashing is just as cheap and actually correct.
- **Scope:** the `utils/pdda/` runtime **plus the contract `PROJECT/PDDA.md`** (resolved Q3 — a stale
  contract in a target is a real footgun, and `install.sh` already treats it as runtime). Per-repo
  *adapted* startup docs (`ROUTER.md`, `AGENTS.md`) are left alone so the job never clobbers
  customization.

### Operating principles this must respect

- **Non-destructive by default** (PDDA's `observe` ethos): a `--dry-run` preview, recoverable backups,
  and a guard against syncing a dirty source.
- **One canonical place per fact:** the synced file list is derived from one manifest, shared with
  `install.sh`, not duplicated.

## Design

### Files & layout (all source-side, under gitignored `temp/`)

```text
temp/pdda-sync-registry.conf     # one absolute target-repo-root per line; '#' comments; blanks ignored
temp/pdda-sync-state/<slug>.tsv  # per-target: <relpath>\t<last-synced-source-hash>
temp/pdda-sync-backups/<slug>/<utc-timestamp>/<relpath>   # pre-overwrite backups
temp/pdda-sync.log               # append-only run log (also launchd stdout/stderr sink)
temp/pdda-sync.lock              # mkdir-based lock; prevents overlapping runs
```

`<slug>` = the target root path sanitized to a filename. The registry is line-based (not JSON) so a
whole line is one path — robust to spaces, and append-only like `PDDA-ACTIVITY.jsonl`, with no
read-modify-write.

### The canonical manifest (shared with `install.sh`)

The synced set is the `utils/pdda/` runtime — `pdda.sh`, `pdda-lib.sh`, `pdda-doc-ready.sh`,
`pdda-catchup.sh`, `PDDA-INSTALL.md` — **plus `PROJECT/PDDA.md`** (the contract). To stay DRY, this
list is factored into one place both `install.sh` and `pdda-sync.sh` read, so adding a synced file
never requires editing two copies. The per-target state and backup paths key off each file's
repo-relative path, so a file outside `utils/pdda/` (like `PROJECT/PDDA.md`) needs no special-casing.

### Per-file sync decision (the state-stamp model)

For each manifest file, against each target, compute `src_hash` and the target's `tgt_hash`, and read
`last_hash` from the per-target state file:

| Situation | Action |
|---|---|
| target file missing | copy → record `last_hash = src_hash` (`new`) |
| `src_hash == last_hash` (source unchanged since last sync) | **leave target alone** — respects local edits between source releases (`skip`) |
| source advanced **and** target unchanged from `last_hash` | atomic copy → update state (`updated`) |
| source advanced **and** target also diverged | **back up target**, then atomic copy → update state (`updated+backup`) |

The state stamp is what stops two failure modes a naive "source-wins hash diff" has: (a) **backup
spam** — re-backing-up a persistently-customized target on every run; and (b) **stomping local edits**
the operator made deliberately while the source had not changed. Source only ever overwrites when it
has genuinely advanced.

### Safety / ops invariants

- **Atomic writes:** copy to `<file>.pdda-tmp` then `mv` into place (no half-written runtime).
- **Lock:** `mkdir temp/pdda-sync.lock` guard; stale-lock age-out so a crashed run self-heals.
- **Missing targets:** skip + log; `prune` subcommand removes dead entries (never auto-deletes silently).
- **Dirty-source guard:** refuse to sync if this repo has uncommitted changes to **any file in the
  shared manifest** (`--allow-dirty` to override) — prevents pushing half-finished edits to many repos
  at once. The check is driven off the same manifest used for copying, *not* a hardcoded `utils/pdda/`
  subtree, so a file outside that folder (notably the contract `PROJECT/PDDA.md`) can't slip past the
  guard half-edited. (QA: Codex review 2026-06-27.)
- **chmod:** restore the executable bit on copied `*.sh` (mirrors `install.sh`).
- **Recoverability:** every overwrite leaves a timestamped backup under `temp/pdda-sync-backups/`.
- **Backup retention:** prune to the last `N` backups per target (default `N=5`, `PDDA_SYNC_BACKUPS`
  override) so the backup tree stays bounded under a 30-min cadence — same spirit as the activity-log
  rotation in `pdda-lib.sh`.

---

## Phase 1 — Registry, manifest & state model

Establish the data layer before any copying.

- Create the `temp/` layout above (lazily, on first use — no tracked files).
- Add `utils/pdda-sync.sh` skeleton with subcommand dispatch mirroring `pdda.sh`'s thin-router style:
  `register`, `run`, `list`, `remove`, `prune`, `install-agent`, `uninstall-agent`, `help`.
- Factor the runtime manifest into one shared list consumed by both `install.sh` and `pdda-sync.sh`.
- Registry read/append helpers (dedupe on absolute, normalized path; tolerate spaces; ignore `#`/blank).

**QA gate:** `bash -n utils/pdda-sync.sh` clean; `pdda-sync.sh list` on an empty registry prints
nothing and exits 0; registering the same path twice does not duplicate it; the shared manifest yields
the identical file set `install.sh` copies (diff the two lists).

## Phase 2 — Sync engine (`pdda-sync.sh run`)

The steady-state copier — the heart of the feature.

- Implement the state-stamp decision table per file, per target.
- `shasum`-based comparison; atomic temp-then-`mv`; backup-then-overwrite; chmod; per-file logging.
- `--dry-run` (report planned actions, write nothing) and `--target <path>` (one repo) flags.
- Lock acquisition + stale-lock age-out; dirty-source guard (`--allow-dirty`).
- Backup retention: after writing a backup, prune that target's backups to the last `N` (default 5).

**QA gate:** against two throwaway target repos — unchanged source ⇒ all `skip`; bump a source file ⇒
exactly that file `updated` in both targets, backup written, state stamp advanced; locally edit a
target file with source unchanged ⇒ `skip` (local edit preserved); locally edit a target *and* advance
source ⇒ `updated+backup` with the old target content recoverable from the backup dir; `--dry-run`
writes nothing; second consecutive `run` is a clean all-`skip` no-op.

## Phase 3 — `register` / initial sync (reuse `install.sh`) + `list` / `remove` / `prune`

Onboarding and registry management.

- `register <target-repo-dir>`: validate it's a git repo; **confirm interactively before first write,
  with `--yes` to bypass for unattended onboarding** (resolved Q2 — friction only at the rare,
  consequential enrollment step; the recurring `run` never prompts); run
  `./install.sh [--with-startup-docs] [--mode <m>] <target>` for the initial copy; append to the
  registry; seed the per-target state stamps from the just-installed hashes.
- `remove <target>` (de-register, keep files), `prune` (drop registry entries whose dir is gone),
  `list` (show registered targets + last-sync summary from the log).

**QA gate:** `register` on a fresh repo installs the runtime (target `pdda.sh run` works), adds exactly
one registry line, and seeds state so the very next `run` is all-`skip`; `remove` then `list` shows it
gone but leaves files intact; `prune` drops a moved/deleted target.

## Phase 4 — launchd scheduler (30-minute job)

Wrap `run` in a native macOS job.

- `install-agent`: write `~/Library/LaunchAgents/com.hiqs.rebalance.pdda-sync.plist` with
  `ProgramArguments` → `pdda-sync.sh run` (absolute path to this clone), `StartInterval` 1800,
  `RunAtLoad`, and `StandardOutPath`/`StandardErrorPath` → `temp/pdda-sync.log`; then
  `launchctl bootstrap`/`enable`.
- `uninstall-agent`: `launchctl bootout` + remove the plist.
- Job is a single agent that iterates the whole registry (not one-per-repo).

**QA gate:** after `install-agent`, `launchctl list` shows the label; a forced kickstart performs a real
sync and appends to `temp/pdda-sync.log`; the interval is 1800s and `RunAtLoad` fires once; the job
survives a logout/login (or documented if it needs `RunAtLoad` only); `uninstall-agent` fully removes it
(`launchctl list` no longer shows the label, plist gone).

## Phase 5 — Docs + dogfood verification

Make it discoverable and prove it end-to-end.

- Document the sync system in `utils/pdda/PDDA-INSTALL.md` (or a dedicated section), add a `.gitignore`
  note that `temp/` holds the registry/state/backups, and add routing hints in `ROUTER.md`.
- Add a CHANGELOG entry. Update `install.sh` header comment if the manifest was refactored.
- Full dogfood: register 2–3 real secondary repos, run the agent for one interval, confirm a genuine
  source bump propagates within 30 minutes with backups intact and no clobbered local edits.

**QA gate:** `./utils/pdda/pdda.sh run` green; a clean-clone walk shows the docs explain register →
auto-sync → uninstall; CHANGELOG updated; one real propagation observed end-to-end via launchd.

## Resolved decisions

All five settled 2026-06-27:

1. **Source of truth = working tree, dirty-guarded.** Sync the on-disk synced set, but refuse when the
   source repo is git-dirty on **any manifest file** (the guard reads the shared manifest, not a
   hardcoded `utils/pdda/` subtree, so `PROJECT/PDDA.md` is covered); `--allow-dirty` overrides.
2. **`register` confirms by default, `--yes` to bypass.** Friction only at the rare, consequential
   enrollment step; the recurring `run` never prompts (its safety is backups + state-stamp). Aligns
   with GUIDING-PRINCIPLES #6 (low-friction/portable) without surrendering the non-destructive ethos.
3. **`PROJECT/PDDA.md` is in the synced set.** The contract ships with the runtime; a stale contract in
   a target is a real drift footgun.
4. **Backups prune to the last `N` per target** (default 5, `PDDA_SYNC_BACKUPS` override) — bounded
   like the activity-log rotation.
5. **launchd label `com.hiqs.rebalance.pdda-sync`**, per-user LaunchAgent under
   `~/Library/LaunchAgents/`.
