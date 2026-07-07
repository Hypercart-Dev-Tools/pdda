# Phase 3 — Replay/eval harness (build + run; human scores the go/no-go)

Build `sentinel/replay.sh`: run the Phase 1→2b pipeline over the last 10–20 real commits, headless,
landing nothing, and emit a per-category scored table. Canonical contract:
`PROJECT/2-WORKING/GH-10-SENTINEL.md` → "Phase 3".

## Task

- For each of the last N commits (default 15), run the recommend (`sentinel/run.sh`) → worktree apply +
  gate (`sentinel/apply.sh`) pipeline in dry-run and record the outcome per change `category`:
  would-recommend?, applied?, gate-pass?, diff size.
- Emit a machine-readable results table (TSV/JSON under a gitignored work dir) AND a human-readable
  summary grouped by category.
- The harness must be **idempotent and headless** (no prompts), and must never write to the primary
  tree (same isolation guarantees as `sentinel/apply.sh`).

## Your write lane (STRICT — containment-enforced)

You may edit **only** these three files. Editing anything else fails the turn (containment violation):

- `sentinel/replay.sh` — the replay harness entrypoint.
- `sentinel/replay-lib.sh` — put ALL shared helpers here (your only extra slot).
- `test/sentinel-replay.sh` — the test suite.

**Reuse `sentinel/apply.sh` by calling it** (invoke it as a subprocess for the worktree apply+gate);
do NOT edit it, `sentinel/run.sh`, `sentinel/apply-lib.sh`, `utils/pdda/*`, or the plan doc — read them
for reference only. The harness commits for you; do not run git.

## Guardrails

- Dry-run only; lands nothing. Reuses `sentinel/apply.sh`'s worktree isolation — do not reimplement it.
- The empirical **go/no-go** on whether a category's mapping is clean enough to graduate to live PRs is a
  **HUMAN checkpoint** — the harness produces the numbers; it does NOT decide. Do not add auto-promotion.

## Definition of Done (reviewer gate)

- `test/sentinel-replay.sh` is green: the harness runs headless over a fixture set of ≥3 commits,
  produces the per-category table, and touches no primary-tree file.
- Running `sentinel/replay.sh` over recent real commits produces a readable per-category summary.
- `utils/pdda/pdda.sh run` still green.
- No file outside your write lane (`sentinel/replay.sh`, `sentinel/replay-lib.sh`,
  `test/sentinel-replay.sh`) is modified. (Writing the empirical findings back into the plan doc is a
  follow-up HUMAN step, not part of this artifact.)
