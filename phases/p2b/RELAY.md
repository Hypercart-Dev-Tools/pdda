# Marathon Phase p2b
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-P2B-TURN builder=agy reviewer=codex round-cap=7 -->

## Phase Brief

# Phase 2b — Worktree executor (dry-run finalizer)

Build `sentinel/apply.sh`: the worktree-isolated apply+gate stage that turns a validated Phase-1
recommendation into a **diff artifact**, landing nothing. Promote the four tested primitives from the
Phase-2a spike (`sentinel/spike/apply-spike.sh`): `apply_full_file`, `apply_search_replace`,
`hardened_gate`, `allowlist_check`.

Canonical contract: `PROJECT/2-WORKING/GH-10-SENTINEL.md` → "Phase 2b" and the "Phase 2a findings".
Reuse `utils/pdda/pdda-lib.sh` and mirror the idiom of the shipped `sentinel/run.sh`.

## Task

- Entry: `sentinel/apply.sh <sha>` (or accept a recommendation JSON) — resolve the reviewed `<sha>`.
- Create a git worktree from the **reviewed `<sha>`** (NOT `origin/main`) on a **collision-safe** temp
  branch/dir (suffix a PID/token, e.g. `docgov/<sha>-<token>`).
- Second, tightly-scoped model call (via the `PDDA_LLM_BIN` seam) renders the edit for the recommended
  targets in **full-file** format (the Phase-2a chosen primary; search/replace is the fallback path).
- Apply the edit confined to the **realpath-hardened allowlist** (`allowlist_check`): any absolute /
  `..` / symlinked / outside-allow-root / wrong-case target aborts the run.
- Run the **hardened gate** (`hardened_gate`): deterministic checks only, count-based, with
  `PDDA_ACTIVITY_LOG` redirected outside the worktree. Never invoke the LLM `doc-ready` layer.
- Emit the resulting diff as an artifact + an activity-log entry. **No PR, no commit.**
- Tear the worktree + temp branch down with a `trap` on `EXIT INT TERM HUP`
  (`git worktree remove --force` + `git branch -D`), idempotent, even on gate-fail / error / SIGINT.

## Your write lane (STRICT — containment-enforced)

You may edit **only** these three files. Editing anything else fails the turn (containment violation):

- `sentinel/apply.sh` — the executor entrypoint.
- `sentinel/apply-lib.sh` — put ALL shared helpers here (this is your only extra slot).
- `test/sentinel-apply.sh` — the test suite.

To reuse the four Phase-2a primitives (`apply_full_file`, `apply_search_replace`, `hardened_gate`,
`allowlist_check`), **copy them into `sentinel/apply-lib.sh`** — do NOT edit `sentinel/spike/*`,
`sentinel/run.sh`, `utils/pdda/*`, the plan doc, or any file outside your lane (read them for reference
only). The harness commits for you; do not run git.

## Guardrails

- Dry-run only. The PRIMARY working tree must be provably untouched (`git status` clean, incl. the
  activity log). Do not open a PR, push, or commit anything outside your write lane.
- Model seam unset → clean self-skip (mirror `sentinel/run.sh`).

## Definition of Done (reviewer gate)

- `test/sentinel-apply.sh` is green and covers: allowlisted full-file edit → clean worktree diff + gate
  pass; out-of-allowlist / `..` / symlinked / absolute target refused; primary tree provably untouched
  after the run; worktree+branch always cleaned up on success, gate-fail, error, AND SIGINT; two
  concurrent runs don't collide (distinct branch/dir).
- `utils/pdda/pdda.sh run` still green for the repo's docs.
- No file outside `sentinel/apply.sh` + `test/sentinel-apply.sh` is modified.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): sentinel/apply.sh,sentinel/apply-lib.sh,test/sentinel-apply.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick
   - /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick claim MARATHON-P2B-TURN --agent agy --paths "phases/p2b/RELAY.md,sentinel/apply.sh,sentinel/apply-lib.sh,test/sentinel-apply.sh"
   - /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick ping MARATHON-P2B-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick release MARATHON-P2B-TURN --agent agy --to codex
4. Edit ONLY these paths: phases/p2b/RELAY.md and sentinel/apply.sh,sentinel/apply-lib.sh,test/sentinel-apply.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: sentinel/apply.sh,sentinel/apply-lib.sh,test/sentinel-apply.sh.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick release MARATHON-P2B-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick done MARATHON-P2B-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/pdda/.xyz/bin/tick
   Edit ONLY phases/p2b/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
