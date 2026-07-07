---
title: myriad-review reader — surface the parked backlog on demand (and via /pdda)
status: Active — planned; queued for the 2026-07-07 marathon (phase p1)
created: 2026-07-06
updated: 2026-07-06
owner: noel
gh_issue: 11
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/11
doc_type: project
effort: 2
complexity: 2
risk: 1
phases: 1
goal: >
  Give the /myriad parking lot a read path. The /myriad skill writes deferred items to repo-root
  2-WORKING/MYRIAD-WEEK-*.md but nothing surfaces them, and those files sit outside PDDA's scan
  surface. Add a tiny deterministic reader that globs the last N weekly files and prints open items
  grouped by week, and have pdda.sh run emit a one-line pointer so /pdda surfaces the backlog
  transitively — with no edit to the global skill and no new write path.
---

# myriad-review reader

The [`/myriad`](file) end-of-day triage skill parks non-critical items in a **write-only** parking lot
at repo-root `2-WORKING/MYRIAD-WEEK-<monday>.md`. The write path is trustworthy (idempotent, fuzzy-dedup,
read-back-verified), but there is **no reader**: nothing rolls the backlog back into view, and the files
live **outside** PDDA's scan surface (`pdda.sh run` scans `PROJECT/2-WORKING/` only). Deferring is safe
but invisible to recall. This adds the missing read path — and only the read path.

## Status

| What was just completed | What's next |
|---|---|
| Planned + issue [#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11) filed. Design locked: read-only reader under `utils/pdda/`, `pdda.sh run` emits a one-line pointer so `/pdda` surfaces it transitively (no global-skill edit). Queued as phase `p1` of the [2026-07-07 marathon](../../marathon/MARATHON-2026-07-07.yaml). | Build `utils/pdda/pdda-myriad.sh` + `test/pdda-myriad.sh`, wire the pointer into `pdda.sh run`. |

## Design (locked)

- **Reader — read-only, never writes.** `utils/pdda/pdda-myriad.sh review [--weeks N]` (default `N=2`):
  glob `2-WORKING/MYRIAD-WEEK-*.md`, take the most recent N by filename date, print open `- [ ]` items
  grouped by week (newest first). Checked `- [x]` items are omitted. The `/myriad` helper stays the sole
  owner of the write path — this component never touches it.
- **Surface via `pdda.sh run`, not a skill edit.** `pdda.sh run` gains a final **informational** line —
  `INFO myriad: N open item(s) across M week(s) — utils/pdda/pdda-myriad.sh review`. Because the `/pdda`
  skill already runs `pdda.sh run` as its state-read step, `/pdda` surfaces the pointer **transitively**;
  no edit to the global `~/.claude/skills/pdda/SKILL.md` is required (and a marathon can't edit it anyway
  — it's outside the repo). Optionally, a one-line prose mention can be added to that skill later by hand.
- **Fail-open.** No `2-WORKING/` dir, or zero week files → clean "no parked items", exit 0. The pointer
  in `pdda.sh run` never changes the run's exit code (observe-mode stays report-only).
- **Scope guard.** This is the read half only. It does not add auto-resurfacing, reminders, or any write
  to the parking lot.

## Phase p1 — the reader + the pointer

- `utils/pdda/pdda-myriad.sh` with a `review` subcommand and `--weeks N` (default 2).
- `pdda.sh run` emits the one-line informational myriad pointer at the end of the sweep.
- `test/pdda-myriad.sh` covering: open-vs-checked filtering, week grouping + newest-first ordering,
  `--weeks N` window bound, and the empty / missing-dir fail-open path.

**QA gate:** `utils/pdda/pdda-myriad.sh review` prints open items grouped by week over a fixture set and
`--weeks N` bounds the window; `pdda.sh run` shows the pointer and stays exit-0 in observe mode;
`test/pdda-myriad.sh` is green; `pdda.sh run` overall still green. Shippable alone.
