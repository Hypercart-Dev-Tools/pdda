# Phase 4 — Policy gate + PR-finalizer logic (CODE + TESTS ONLY; no live wiring)

Build the deterministic policy engine and the PR-finalizer *logic*, fully unit-tested. Canonical
contract: `PROJECT/2-WORKING/GH-10-SENTINEL.md` → "Phase 4" and "Policy gate".

## Task

- `sentinel/policy.sh`: a **pure function** over the recommendation + diff facts (risk, changed doc
  lines, file count, allowlist result, gate result, confidence, per-category trust). It only ever
  *downgrades* the model's `mode_recommendation` (`local_commit`→`open_pr`→`dry_run`), never upgrades.
  Encodes the [policy gate](../../PROJECT/2-WORKING/GH-10-SENTINEL.md) table exactly.
- `sentinel/finalize.sh`: the `open_pr` finalizer **logic** — assemble the branch/commit/PR-body from a
  gated worktree diff, and the **self-retrigger guard** (skip Sentinel's own merges by bot-author /
  `Sentinel-Run:` commit trailer / `sentinel` label). Provide a `--dry-run` that PRINTS what it would
  do (branch name, trailer, PR title/body, `gh pr create` argv) and returns it — WITHOUT running `gh`,
  pushing, or committing.

## Guardrails (hard)

- **No outward effects in this phase.** Do NOT run `gh`, do NOT push, do NOT open a real PR, do NOT add
  or push a GitHub Actions workflow file. Those are a deliberate HUMAN step, out of scope here.
- Everything is pure logic + `--dry-run` printing. The finalizer's live path may exist as code but MUST
  be unreachable without an explicit real-run flag that this phase does not exercise.

## Definition of Done (reviewer gate)

- `test/sentinel-policy.sh` is green with a fixture per policy rule: high-risk→PR, oversized diff→PR,
  too many files→PR, out-of-allowlist→block, low-confidence→dry_run, gate-fail→dry_run/block, trusted
  low-risk category→local_commit allowed; and self-retrigger guard skips a Sentinel-authored merge.
- `sentinel/finalize.sh --dry-run` prints the intended PR plan and makes NO outward call (assert `gh` is
  never invoked — e.g. via a PATH shim in the test that fails if `gh` runs).
- `utils/pdda/pdda.sh run` still green.
- No file outside the three declared artifacts is modified.
