---
title: Reconcile pdda-sync `list` vs `status` currency wording
status: Active
created: 2026-06-30
updated: 2026-06-30
owner: noel
goal: >
  Make `pdda-sync.sh list` report content currency consistent with `pdda-sync.sh status`, so a target
  that install.sh just provisioned (files identical to HQ, but `push` never run) no longer reads as
  `not-yet-pushed` (which implies it is stale and needs action) while `status` simultaneously reports it
  `behind=0 diverged=0`. The two read-only surfaces must not contradict each other.
branch: main
gh_issue: pending (gh auth re-login required; rename this doc to GH-<n>-… once the issue exists)
---

## Status

| What was just completed | What's next |
|---|---|
| Iteration 1 shipped: `cmd_list` is now content-aware via a new `target_is_current()` helper — a just-installed-but-unpushed target reads `current (unpushed)` instead of `not-yet-pushed`, consistent with `status`. Verified `list` agrees with `status` for both registered targets; `pdda.sh run` clean. | Re-auth `gh`, open the tracking issue, rename this doc to `GH-<n>-…`. Optionally fold the `(unpushed)` distinction into `status` or add a per-target file count to `list` (deferred). |

## Problem

The two read-only sync surfaces disagree for a just-installed-but-never-pushed target:

- `list` decided its currency column purely on **state-file existence** (`$STATE_DIR/<slug>.tsv`). install.sh
  writes the registry row but never writes a sync state file (only `push` does), so a freshly installed
  target had no state file → `list` printed `not-yet-pushed`.
- `status` computes currency by **hashing actual file content** against the HQ manifest, so the same target
  printed `current=9 behind=0 diverged=0`.

Observed live against the real registry (both repos installed today, never pushed):

```
list:   rebalance-OS  …  not-yet-pushed          <-- implies stale / action needed
status: rebalance-OS  …  current=9 behind=0 …    <-- authoritative: nothing to do
```

`not-yet-pushed` is true from sync's *bookkeeping* view (push has never stamped the target) but reads to a
human as "out of date," contradicting `status`. The defect is purely in the `list` signal — `status` is
correct and authoritative.

## Decision

`list` stays the lightweight roster; `status` stays the authoritative per-file drift report. But `list`'s
currency column becomes **content-aware** (cheap — the manifest is ~9 files) so it never implies staleness it
cannot verify:

- `current` — every manifest file matches HQ (⟺ `status` would report `behind=0 diverged=0`).
- `out-of-sync` — at least one file is missing or differs.
- ` (unpushed)` suffix — informational marker when no sync state file exists yet (the post-install,
  pre-`push` case). It annotates provenance without implying staleness.

So the just-installed target now reads `current (unpushed)` — consistent with `status`, and honest about the
fact that `push` has not yet adopted it.

## Scope / anti-goals

- **In:** the `cmd_list` currency column only; a small shared content-currency helper.
- **Out:** changing `status` (it is correct); merging `list` into `status`; adding new columns or flags;
  any change to `push`, the registry schema, or install.sh. Authoritative drift detail remains `status`'s job.

## Iteration log

### Iteration 1 — 2026-06-30 — content-aware `list`

- Added `target_is_current()` helper (hashes each manifest file in the target against HQ; mirrors the
  current/behind/diverged logic `status` already uses, collapsed to a single boolean).
- Rewrote `cmd_list` to print `current` / `out-of-sync` with an `(unpushed)` marker when no state file exists,
  replacing the binary `synced` / `not-yet-pushed` that ignored content.
- Verification: `utils/pdda/pdda-sync.sh list` now agrees with `utils/pdda/pdda-sync.sh status` for both
  registered targets; `utils/pdda/pdda.sh run` clean.

## Possible later iterations (not committed)

- Surface a per-target file count in `list` (e.g. `current 9/9`) if the single word proves too coarse.
- Fold the `(unpushed)` distinction into `status` too, if operators want push-adoption state there.
