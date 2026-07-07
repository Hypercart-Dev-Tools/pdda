# Phase p1 — myriad-review reader (read-only) + pdda.sh run pointer

Build a tiny, deterministic **reader** for the `/myriad` parking lot and surface a one-line pointer from
`pdda.sh run`. Canonical contract: `PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md`. Issue
[#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11).

## Task

- `utils/pdda/pdda-myriad.sh` with a `review` subcommand and `--weeks N` (default `N=2`): glob
  `2-WORKING/MYRIAD-WEEK-*.md` at the **repo root** (NOT `PROJECT/2-WORKING`), take the most recent N by
  filename date, and print open `- [ ]` items grouped by week, newest week first. Omit checked `- [x]`.
- Add a `pointer` subcommand (or equivalent) that prints exactly one informational line summarizing the
  open count, e.g.: `INFO myriad: 4 open item(s) across 1 week(s) — utils/pdda/pdda-myriad.sh review`.
- Wire that pointer into `pdda.sh run`: emit it as the **final informational line** of the sweep. It must
  NOT change the run's exit code (observe-mode stays report-only). This is the ONLY edit to `pdda.sh` —
  one call at the end of the `run` flow; touch nothing else in that file.
- `test/pdda-myriad.sh`: cover open-vs-checked filtering, week grouping + newest-first ordering, the
  `--weeks N` window bound, and the empty / missing-`2-WORKING`-dir fail-open path (exit 0, clean "no
  parked items").

## Your write lane (STRICT — containment-enforced)

You may edit **only** these files. Editing anything else fails the turn:

- `utils/pdda/pdda-myriad.sh` — the reader (new).
- `test/pdda-myriad.sh` — the test suite (new).
- `utils/pdda/pdda.sh` — **one-line addition only**: call the reader's pointer at the end of `run`.

Read for reference (do NOT edit): `utils/pdda/pdda-lib.sh`, `PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md`,
the `/myriad` weekly file format (`2-WORKING/MYRIAD-WEEK-*.md`). The harness commits for you; do not run git.

## Guardrails

- **Read-only.** The reader NEVER writes to `2-WORKING/` or any myriad file. The `/myriad` helper stays
  the sole owner of the write path. No dedup, no append, no auto-resurface — read half only.
- **Fail-open.** Missing dir / zero files → clean "no parked items", exit 0. Never error the sweep.
- **No global-skill edits.** Do not touch `~/.claude/skills/**` — `/pdda` surfaces the pointer
  transitively because it already runs `pdda.sh run`.

## Definition of Done (reviewer gate)

- `utils/pdda/pdda-myriad.sh review` prints open items grouped by week over a fixture set; `--weeks N`
  bounds the window; checked items are omitted.
- `pdda.sh run` shows the one-line myriad pointer and stays exit-0 in observe mode.
- `test/pdda-myriad.sh` is green; `utils/pdda/pdda.sh run` overall still green.
- No file outside the write lane is modified; the `pdda.sh` change is the single pointer call and nothing
  else.
