# Phase 5 — Trust registry fed by PR outcomes

Build `sentinel/trust.sh`: per-category trust tracking in a plain JSON file, fed by objective PR
outcomes (not hand-scoring). Canonical contract: `PROJECT/2-WORKING/GH-10-SENTINEL.md` → "Phase 5" and
"Trust model".

## Task

- `sentinel/trust.json` schema (JSON only — no SQLite): per category → reviewed runs, accepted,
  acceptance rate, serious misses, eligible flag.
- `sentinel/trust.sh` operations:
  - `reconcile`: derive acceptance from PR state (merged→accept, closed-unmerged→reject,
    human-edit-then-merge→partial/flag), reusing the offline gh-state cache pattern from
    `utils/pdda/pdda.sh issue-doc-sync` (degrade gracefully when `gh` is absent).
  - `seed`: initialize from a Phase-3 replay results file.
  - `status`: print per-category acceptance + eligibility.
  - Promotion rule: category stays PR-only until ≥10 reviewed runs, promotes to `local_commit`-eligible
    only at ≥85–90% acceptance with no serious miss in the last 5; ONE material error demotes to PR.

## Guardrails

- Read-only against GitHub (never writes to PRs/issues). Registry writes are atomic (temp + `mv`).
- `gh` absent/offline → degrade gracefully, never hard-fail.

## Definition of Done (reviewer gate)

- `test/sentinel-trust.sh` is green: reconcile maps merged/closed/edited PR states to accept/reject/
  partial correctly (with a `gh` stub); promotion/demotion thresholds enforced (no category eligible
  below the bar; one material error demotes); `status` prints per-category state; registry writes are
  atomic and survive a simulated concurrent write.
- `utils/pdda/pdda.sh run` still green.
- No file outside `sentinel/trust.sh` + `test/sentinel-trust.sh` (+ a generated `sentinel/trust.json`)
  is modified.
