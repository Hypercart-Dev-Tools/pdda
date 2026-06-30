---
title: Sync the PDDA runtime to other repos (HQ → registered targets, push-based)
status: Active
created: 2026-06-27
updated: 2026-06-29
owner: noel
goal: >
  Let one canonical PDDA source repo ("HQ") distribute its utils/pdda/ runtime into other registered
  repos — an initial install/update on registration, then an on-demand `push` from HQ that re-copies
  only files whose content has actually changed (backing up the target's version first) and mirrors
  HQ-side deletions (also backed up first). The synced file set is an auto-regenerated manifest derived
  from declared source roots, so adding a runtime file or folder propagates without editing a list. The
  set of target repos lives in a machine-local registry at ${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv (written by
  install.sh). A launchd schedule is an OPTIONAL wrapper over the same `push` engine, not the headline.
branch: pdda-sync-to-other-repos
gh_issue: pending (open once scope is approved; rename this doc to GH-<n>-… then)
non_goals: >
  Not a two-way sync, not a git submodule/subtree, not a package manager, not a remote/cross-machine
  service. Source of truth is always this local clone's HQ working tree (dirty-guarded).
effort: 3
complexity: 3
risk: 3
phases: 5
---

## Status

| What was just completed | What's next |
|---|---|
| **Phase 3 SHIPPED (2026-06-29) — onboarding & registry mgmt.** `register` (validates git repo, confirms unless `--yes`/no-TTY-refuses, delegates the copy + registry write to `install.sh`, then seeds state + snapshot so the next push is all-skip), `list` (mode / source-commit / sync state), `status` (current / behind / diverged / missing / to-delete, read-only), `remove` (de-register, keep files), `prune` (drop targets whose dir is gone). **Phase 3 QA gate GREEN (17/17).** Phases 1–2 (manifest expander + push engine) shipped prior. | **Phase 4 — optional launchd wrapper** (`install-agent` / `uninstall-agent` scheduling the same `push`; manual push stays primary). |

## Realignment (2026-06-29)

This doc was reconciled with a generic "HQ distribution system" design so PDDA stays the single
canonical owner of this feature (Principle #4 — one canonical place per fact). Three earlier locked
decisions were intentionally reversed; the rest stand:

| Aspect | Was | Now | Why |
|---|---|---|---|
| **Trigger** | launchd 30-min *pull* job (headline) | **manual `push` from HQ** is primary; launchd is an optional wrapper over the same engine | Operator wants distribution on demand from HQ, not a background daemon. The engine stays daemon-ready, so scheduling is a thin add (Phase 4). |
| **Deletions** | additive only (backup-then-overwrite) | **mirror HQ-side deletes**, backup-first, dry-run-visible, manifest-diff-gated | A file dropped from the runtime should leave targets; a stale file in a target is drift. Safety preserved via backup + only removing paths HQ previously shipped. |
| **Manifest** | hand-maintained static list | **auto-regenerated** from declared source roots via `git ls-files` | New runtime files/folders propagate without editing a list; still DRY and dirty-guardable. |

Unchanged: content-hash change detection, atomic writes, backup-then-overwrite, the state-stamp
decision model, the dirty-source guard, `register` confirms by default, `PROJECT/PDDA.md` in the
synced set, bounded backup retention.

## Table of contents

- [Phase 1 — Registry, manifest expander & state model](#phase-1--registry-manifest-expander--state-model)
- [Phase 2 — Push engine (`pdda-sync.sh push`)](#phase-2--push-engine-pdda-syncsh-push)
- [Phase 3 — `register` / initial sync (reuse `install.sh`) + `list` / `remove` / `prune`](#phase-3--register--initial-sync-reuse-installsh--list--remove--prune)
- [Phase 4 — Optional launchd scheduler (wraps `push`)](#phase-4--optional-launchd-scheduler-wraps-push)
- [Phase 5 — Docs + dogfood verification](#phase-5--docs--dogfood-verification)

## Context

`install.sh` already copies the `utils/pdda/` runtime into a target repo and records the install in a
machine-local registry. So the "initial sync (new copy or update)" is **not new code** — it is
`install.sh` plus *registering* the target. What is new is the **steady-state** layer: an on-demand
`push` from HQ that keeps each registered target current as the source runtime evolves — including
when files or whole folders are added to, or removed from, the runtime.

**Vocabulary:** *HQ* = this canonical local clone, the only writer and source of truth. *Targets* =
other local repos that opted in via `register`. `push` distributes HQ's current runtime to one or all
targets.

The locked decisions (post-realignment):

- **Trigger:** **manual `pdda-sync.sh push [<target>]` from HQ.** No daemon required. A launchd
  LaunchAgent that runs the same `push` on a schedule is an *optional* Phase-4 add for operators who
  want hands-off propagation.
- **Drift policy:** backup-then-overwrite, **and backup-then-delete** for HQ-side removals — HQ is
  canonical, but the target's current file is always saved before it is replaced *or* removed, so
  nothing is ever destroyed irrecoverably.
- **Change detection:** content hash (`shasum`), not mtime. `git` checkouts reset mtimes, so a
  date-based rule misfires; hashing is just as cheap and actually correct.
- **Scope:** the `utils/pdda/` runtime **plus the contract `PROJECT/PDDA.md`**, expressed as an
  **auto-regenerated manifest** — HQ declares *source roots* (the `utils/pdda/` subtree + named files)
  and the expander walks them (`git ls-files`-backed) into a concrete file set at run time. Per-repo
  *adapted* startup docs (`ROUTER.md`, `AGENTS.md`) are left alone so `push` never clobbers
  customization.

### Operating principles this must respect

- **Non-destructive by default** (PDDA's `observe` ethos): a `--dry-run` preview (showing planned
  copies *and* deletions), recoverable backups for every overwrite and delete, and a guard against
  pushing from a dirty HQ.
- **One canonical place per fact:** the synced file set is derived from one manifest declaration,
  shared with `install.sh`, not duplicated.

## Design

### Files & layout

**The registry (SHIPPED) is machine-local, in `$HOME`, NOT in the repo:**

```text
${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv   # one row per target:
  # target <TAB> last_install_utc <TAB> mode <TAB> source_commit <TAB> startup_docs
```

Per-user, per-device, never committed (the repo will be public). Written by `install.sh` on every
install/upgrade (latest-wins dedup on the target path); `source_commit` is what lets `push` later tell
which targets are behind. Lives in `$HOME` rather than the source clone so it survives the temp-clone
upgrade flow and can't leak into the public repo.

Push-only runtime (built later, HQ-side under gitignored `temp/`):

```text
temp/pdda-sync-state/<slug>.tsv     # per-target: <relpath>\t<last-synced-source-hash>
temp/pdda-sync-manifest/<slug>.tsv  # per-target: the expanded relpath set from the LAST push
                                    #   (diffed against the current set to detect HQ-side deletions)
temp/pdda-sync-backups/<slug>/<utc-timestamp>/<relpath>   # pre-overwrite AND pre-delete backups
temp/pdda-sync.log                  # append-only run log (also launchd stdout/stderr sink)
temp/pdda-sync.lock                 # mkdir-based lock; prevents overlapping runs
```

`<slug>` = the target root path sanitized to a filename.

### The auto-regenerated manifest (shared with `install.sh`)

The synced set is the `utils/pdda/` runtime — `pdda.sh`, `pdda-lib.sh`, `pdda-doc-ready.sh`,
`pdda-catchup.sh`, `PDDA-INSTALL.md` — **plus `PROJECT/PDDA.md`** (the contract). Rather than a
hand-maintained list, HQ declares **source roots** in one place both `install.sh` and `pdda-sync.sh`
read:

```text
# the declaration (one canonical place):
dir   utils/pdda/        # whole subtree, recursively — new files/folders auto-included
file  PROJECT/PDDA.md    # single file
# optional exclude globs, e.g.:  exclude  utils/pdda/*.local
```

At run time the expander turns `dir` entries into a concrete relpath set with a bounded walk —
**prefer `git ls-files` over the source root** so untracked junk / `node_modules` never ship (mirrors
the migration scan in `install.sh`). Benefits:

- **DRY** — one declaration feeds initial install (`install.sh`) and steady-state `push`.
- **New files/folders propagate** — a `dir` entry means any file or subfolder added under it is copied
  (and its folder created) in targets on the next `push`, with no list edit.
- **Dirty-source guard covers new files for free** — the guard reads the *expanded* set, so a
  half-finished new runtime file can't slip past it. The per-target state and backup paths key off each
  file's repo-relative path, so a file outside `utils/pdda/` (like `PROJECT/PDDA.md`) needs no
  special-casing.

### Per-file push decision (the state-stamp model)

For each manifest file, against each target, compute `src_hash` and the target's `tgt_hash`, and read
`last_hash` from the per-target state file. HQ-side deletions are found by diffing the *previous*
expanded manifest (persisted per target) against the *current* one:

| Situation | Action |
|---|---|
| target file missing | copy → record `last_hash = src_hash` (`new`) |
| `src_hash == last_hash` (HQ unchanged since last push) | **leave target alone** — respects local edits between source releases (`skip`) |
| HQ advanced **and** target unchanged from `last_hash` | atomic copy → update state (`updated`) |
| HQ advanced **and** target also diverged | **back up target**, then atomic copy → update state (`updated+backup`) |
| **was in last manifest, gone from HQ now** | **back up target's copy, then delete it**, drop the state row (`deleted+backup`) |

The state stamp stops two failure modes a naive "source-wins hash diff" has: (a) **backup spam** —
re-backing-up a persistently-customized target on every run; and (b) **stomping local edits** the
operator made deliberately while the source had not changed. Source only ever overwrites when it has
genuinely advanced. Deletions only fire for paths HQ *previously shipped and has now removed* — a file
the target created itself (never in any HQ manifest) is never touched.

### Safety / ops invariants

- **Atomic writes:** copy to `<file>.pdda-tmp` then `mv` into place (no half-written runtime).
- **Atomic deletes:** back up first, then `rm`; if the backup fails, the delete is skipped + logged
  (never delete without a recoverable copy).
- **Lock:** `mkdir temp/pdda-sync.lock` guard; stale-lock age-out so a crashed run self-heals.
- **Missing targets:** skip + log; `prune` subcommand removes dead entries (never auto-deletes silently).
- **Dirty-source guard:** refuse to push if HQ has uncommitted changes to **any file in the expanded
  manifest** (`--allow-dirty` to override) — prevents pushing half-finished edits to many repos at
  once. Driven off the same expander used for copying, *not* a hardcoded `utils/pdda/` subtree, so a
  file outside that folder (notably the contract `PROJECT/PDDA.md`) can't slip past the guard
  half-edited. (QA: Codex review 2026-06-27.)
- **chmod:** restore the executable bit on copied `*.sh` (mirrors `install.sh`).
- **Recoverability:** every overwrite **of a locally-diverged target** and **every delete** leaves a
  timestamped backup under `temp/pdda-sync-backups/`. A clean `updated` (the target still matched the
  last-synced stamp, i.e. no local edits) is *not* backed up — its prior content is just the previous
  shipped version, recoverable from HQ history, and backing it up every release would be the backup
  spam the state-stamp model exists to avoid. Backups protect **local work**, which a clean target has
  none of. (Implemented per the [state-stamp decision table](#per-file-push-decision-the-state-stamp-model).)
- **Backup retention:** prune to the last `N` backups per target (default `N=5`, `PDDA_SYNC_BACKUPS`
  override) so the backup tree stays bounded — same spirit as the activity-log rotation in
  `pdda-lib.sh`.
- **Delete safety net (manifest-poisoning guard).** A delete is only as safe as the manifest diff that
  drives it, so before removing anything in **any** target the push **aborts the entire delete phase,
  touching no target**, when the expanded manifest looks truncated or poisoned — specifically when:
  - **(a) zero-root:** any declared source root resolves to **zero** tracked files (a mis-declared path
    or an over-broad `exclude`);
  - **(b) empty-after-nonempty:** the current expanded manifest is **empty** while the
    previously-persisted per-target snapshot was non-empty;
  - **(c) shrink-threshold:** the manifest **shrank** by more than a threshold fraction of the prior
    snapshot (default 25%, `PDDA_SYNC_MAX_SHRINK` override).

  Each abort logs the offending root and the prior/current counts, and requires an explicit
  `--force-delete` (a deliberate operator ack that HQ really did drop that much) to proceed. `--no-delete`
  skips all removals unconditionally. **Copies are never gated by this** — a poisoned manifest blocks
  only the destructive delete phase, so a normal run still safely propagates additions/updates.

---

## Phase 1 — Registry, manifest expander & state model

Establish the data layer before any copying.

> **SHIPPED (2026-06-29) — QA gate GREEN (8/8).** Delivered: `utils/pdda/pdda-sync-manifest.conf`
> (the one declaration), `utils/pdda/pdda-manifest.sh` (the `pdda_manifest_expand` expander, git-ls-files
> backed + exclude globs), `utils/pdda/pdda-sync.sh` (router with `manifest`/`list`/help live; registry
> READ helpers; `push`/`register`/`status`/`remove`/`prune`/`*-agent` stubbed for later phases), and
> `install.sh` refactored to copy exactly `pdda_manifest_expand` output (install set == push set by
> construction). The registry remains install.sh-owned (single writer). `temp/` layout is created lazily
> by the engine in Phase 2.

- Create the `temp/` layout above (lazily, on first use — no tracked files).
- Add `utils/pdda-sync.sh` skeleton with subcommand dispatch mirroring `pdda.sh`'s thin-router style:
  `register`, `push`, `list`, `status`, `remove`, `prune`, `install-agent`, `uninstall-agent`, `help`.
- **Manifest expander:** factor the source-root declaration into one place consumed by both
  `install.sh` and `pdda-sync.sh`; expand `dir` roots via `git ls-files` (fallback pruned `find`) into
  a concrete relpath set; apply exclude globs.
- Registry read/append helpers (dedupe on absolute, normalized path; tolerate spaces; ignore `#`/blank).

**QA gate:** `bash -n utils/pdda-sync.sh` clean; `pdda-sync.sh list` on an empty registry prints
nothing and exits 0; registering the same path twice does not duplicate it; the expanded manifest
yields the identical file set `install.sh` copies (diff the two lists); adding a new file — **and a new
nested subfolder + file** — under a declared `dir` root makes both appear in the expanded set with no
code edit.

## Phase 2 — Push engine (`pdda-sync.sh push`)

> **SHIPPED (2026-06-29) — QA gate GREEN (26/26).** `cmd_push` in `utils/pdda/pdda-sync.sh` implements
> the full state-stamp table, delete-mirror with the deferred-deletion snapshot (poison-blocked or
> `--no-delete` removals stay tracked for a later `--force-delete`), the three poisoning guards
> (zero-root / empty / shrink ≥ `PDDA_SYNC_MAX_SHRINK`%, default 25), atomic temp-then-`mv`, backup +
> `prune_backups` retention, mkdir lock with stale age-out, and the dirty-source guard. Flags:
> `--dry-run`, `--target`/positional, `--allow-dirty`, `--no-delete`, `--force-delete`. Engine state
> lives under `temp/` (created lazily). Verified against a throwaway HQ + two targets across 13
> scenarios (26 assertions): new/updated/skip, local-edit preservation, `updated+bak` recovery,
> delete-mirror recovery, folder propagation, dry-run no-write, idempotent no-op, and all poison paths.

The steady-state distributor — the heart of the feature.

- Implement the state-stamp decision table per file, per target, **including the `deleted+backup` row**
  (diff the persisted previous manifest against the current expanded set).
- `shasum`-based comparison; atomic temp-then-`mv`; backup-then-overwrite; backup-then-delete; chmod;
  per-file logging.
- `--dry-run` (report planned copies **and deletions**, write nothing); `--target <path>` (one repo);
  positional `<target>` (one repo) with no arg = every registered target; `--allow-dirty`;
  `--no-delete`; and the manifest-poisoning guard — abort the delete phase before touching any target
  on zero-root / empty-after-nonempty / shrink-over-threshold, overridable only with `--force-delete`.
- Lock acquisition + stale-lock age-out; dirty-source guard on the expanded manifest.
- Backup retention: after writing a backup, prune that target's backups to the last `N` (default 5).
- Persist the current expanded manifest per target after a successful push (input for next run's
  delete-diff).

**QA gate:** against two throwaway target repos — unchanged source ⇒ all `skip`; bump a source file ⇒
exactly that file `updated` in both targets (no backup — target was unchanged), state stamp advanced; add a NEW file under
a declared root ⇒ it copies as `new` in both; **add a NEW nested subfolder + file (e.g.
`utils/pdda/sub/new.sh`) ⇒ the subfolder is created AND the file copies as `new` in both targets, with
no manifest/code edit** (folder propagation, not just file); **delete a file from HQ ⇒ it is backed up
then removed in both targets (`deleted+backup`), recoverable from the backup dir**; locally edit a target file with
source unchanged ⇒ `skip` (local edit preserved); locally edit a target *and* advance source ⇒
`updated+backup`; `--dry-run` writes nothing but lists the pending delete; `--no-delete` copies but
skips removals; **point a declared root at a non-existent/empty path (or empty the whole manifest) ⇒
the delete phase aborts before touching any target, copies still apply, exit is non-zero with the
zero-root/empty/shrink reason logged, and `--force-delete` is required to proceed**; second consecutive
`push` is a clean all-`skip` no-op.

## Phase 3 — `register` / initial sync (reuse `install.sh`) + `list` / `remove` / `prune`

> **SHIPPED (2026-06-29) — QA gate GREEN (17/17).** `cmd_register/list/status/remove/prune` in
> `pdda-sync.sh`. `register` validates the git repo, confirms before the first write (reads `/dev/tty`;
> **refuses on a non-TTY** unless `--yes`), passes `--mode`/`--with-startup-docs` through to
> `install.sh` (the single registry writer), then `seed_target_state` stamps the per-target state +
> manifest snapshot so the next push is all-skip. `remove`/`prune` delete registry rows + their state
> files via `registry_remove` (a deletion op `install.sh` never performs, so no two-writer conflict) and
> leave target files intact. `status` is a read-only classifier (current/behind/diverged/missing/
> to-delete). Verified against the real `install.sh` + runtime on throwaway repos.

Onboarding and registry management.

- `register <target-repo-dir>`: validate it's a git repo; **confirm interactively before first write,
  with `--yes` to bypass for unattended onboarding** (the recurring `push` never prompts); run
  `./install.sh [--with-startup-docs] [--mode <m>] <target>` for the initial copy. **`install.sh` is the
  single registry writer** — it already records the target in `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (latest-wins)
  as part of that run, so `register` does **not** write the registry itself (no second writer — Principle
  #4). After the install returns, `register` only seeds the per-target sync **state stamps and manifest
  snapshot** under `temp/` from the just-installed hashes. (If `--no-register` is ever passed through to
  `install.sh`, `register` is a no-op on the registry by definition.)
- `remove <target>` (de-register, keep files), `prune` (drop registry entries whose dir is gone),
  `list` (show registered targets + last-push summary from the log), `status [<target>]` (per-target
  behind/current/diverged counts — a read-only dry-run-style report).

**QA gate:** `register` on a fresh repo installs the runtime (target `pdda.sh run` works), adds exactly
one registry line, and seeds state + manifest snapshot so the very next `push` is all-`skip`; `remove`
then `list` shows it gone but leaves files intact; `prune` drops a moved/deleted target.

## Phase 4 — Optional launchd scheduler (wraps `push`)

Wrap the on-demand `push` in a native macOS job — **opt-in**, for operators who want hands-off
propagation. The manual `push` is the primary interface; this just schedules it.

- `install-agent`: write `~/Library/LaunchAgents/com.hiqs.rebalance.pdda-sync.plist` with
  `ProgramArguments` → `pdda-sync.sh push` (absolute path to this clone), `StartInterval` 1800,
  `RunAtLoad`, and `StandardOutPath`/`StandardErrorPath` → `temp/pdda-sync.log`; then
  `launchctl bootstrap`/`enable`.
- `uninstall-agent`: `launchctl bootout` + remove the plist.
- Job is a single agent that iterates the whole registry (not one-per-repo) by calling the same
  `push` engine — no scheduler-specific copy logic.

**QA gate (single pass/fail MVP contract — no escape hatch):** after `install-agent`, `launchctl list`
shows the label; the plist sets `StartInterval` 1800 and `RunAtLoad` true, verified by reading it back;
a forced `launchctl kickstart` performs a real push and appends to `temp/pdda-sync.log`; `RunAtLoad`
fires exactly once at load. **MVP scope is explicitly limited to RunAtLoad + the 1800s interval within
the active login session** — logout/login persistence is *not* a gated guarantee (a
`~/Library/LaunchAgents/` agent reloads at next login by construction; the MVP does not test that path,
and the gate does not depend on it). `uninstall-agent` fully removes it (`launchctl list` no longer
shows the label, plist gone); with NO agent installed, manual `push` is fully functional on its own.

## Phase 5 — Docs + dogfood verification

Make it discoverable and prove it end-to-end.

- Document the push system in `utils/pdda/PDDA-INSTALL.md` (or a dedicated section), add a `.gitignore`
  note that `temp/` holds the sync **state, expanded-manifest snapshots, backups, run log, and lockfile**
  — the **registry itself stays machine-local under `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv`, never in `temp/`** —
  and add routing hints in `ROUTER.md`.
- Add a CHANGELOG entry. Update `install.sh` header comment now that the manifest is a shared
  declaration.
- Full dogfood: register 2–3 real secondary repos, run `push` manually, confirm a genuine source bump
  AND a source-side delete both propagate with backups intact and no clobbered local edits. If a
  launchd agent is installed, confirm the scheduled `push` produces the same result within one interval.

**QA gate:** `./utils/pdda/pdda.sh run` green; a clean-clone walk shows the docs explain register →
push (→ optional auto-schedule) → uninstall; CHANGELOG updated; one real propagation (copy + delete)
observed end-to-end.

## Resolved decisions

Realigned 2026-06-29 (see [Realignment](#realignment-2026-06-29)). Current state:

1. **Source of truth = HQ working tree, dirty-guarded.** Push the on-disk synced set, but refuse when
   HQ is git-dirty on **any expanded manifest file** (the guard reads the expander output, not a
   hardcoded `utils/pdda/` subtree, so `PROJECT/PDDA.md` and any new runtime file are covered);
   `--allow-dirty` overrides.
2. **Trigger = manual `push` from HQ; launchd optional.** *(Reversed 2026-06-29 — was launchd-primary.)*
   On-demand distribution is the default interface; the scheduler is a thin opt-in wrapper over the
   same engine (Phase 4). Aligns with GUIDING-PRINCIPLES #6 (low-friction/portable).
3. **Deletions = mirror HQ-side removals, backup-first.** *(Reversed 2026-06-29 — was additive-only.)*
   A file dropped from the runtime is removed from targets, but only after a recoverable backup and
   only for paths HQ previously shipped (manifest-diff-gated). The blast radius is contained by the
   **manifest-poisoning guard** — the delete phase aborts before touching any target on **zero-root**,
   **empty-after-nonempty**, or **shrink-beyond-threshold** (`PDDA_SYNC_MAX_SHRINK`, default 25%),
   overridable only with an explicit `--force-delete` ack — plus `--no-delete` to skip removals entirely.
4. **Manifest = auto-regenerated from declared source roots.** *(Reversed 2026-06-29 — was a static
   list.)* New runtime files/folders propagate without a list edit; still DRY and dirty-guardable via
   the `git ls-files`-backed expander.
5. **`register` confirms by default, `--yes` to bypass.** Friction only at the rare, consequential
   enrollment step; the recurring `push` never prompts (its safety is backups + state-stamp).
6. **`PROJECT/PDDA.md` is in the synced set.** The contract ships with the runtime; a stale contract in
   a target is a real drift footgun.
7. **Backups prune to the last `N` per target** (default 5, `PDDA_SYNC_BACKUPS` override) — bounded
   like the activity-log rotation.
8. **launchd label `com.hiqs.rebalance.pdda-sync`**, per-user LaunchAgent under
   `~/Library/LaunchAgents/` (only when the optional agent is installed).
