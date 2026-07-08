---
title: "Spike: XYZ harness -> Aider -> OpenRouter -> GLM 5.2, tested against GH-14 Phase 1"
status: Completed
created: 2026-07-08
updated: 2026-07-08
owner: noel
doc_type: research
context_tags: [xyz-harness, aider, openrouter, glm-5.2, relay-automation, spike]
related: [PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md]
goal: >
  Answer a single question: can the vendored XYZ relay harness drive Aider, routed through OpenRouter to
  GLM 5.2, to autonomously execute a real, well-specified remediation-plan phase (GH-14 Phase 1 — a
  verified one-line bash fix) end to end, unattended? Not a build task in itself — a pipeline test.
---

## Status

| What was just completed | What's next |
|---|---|
| Spike closed. Pipeline wiring confirmed working end-to-end (auth, model routing, tick coordination, containment, commit); the model did not reliably complete the task across 2 real attempts, and a real gap in the shim's success classification was found. GH-14 Phase 1 itself was applied directly by hand instead (see the linked plan doc). | None — this is a closed spike. Revisit only if this pipeline is deliberately picked up again (see Recommendation). |

## What was tested

`.xyz/relay-automation/aider-turn.sh` already existed in the vendored harness (GH-67/77/119/120-hardened —
built before this session, not built for this test) as a third turn-taker alongside `codex-turn.sh` /
`agy-turn.sh`, driving Aider (https://aider.chat) against any OpenRouter-hosted model. This spike was the
first real end-to-end exercise of that shim in this repo.

Setup:
- Cut `test/aider-openrouter-glm52-gh14-gh15` off `main`.
- Resolved "GLM 5.2" -> `z-ai/glm-5.2` via the harness's own `relay-automation/resolve-model-alias.sh` +
  `openrouter-model-aliases.yml` (already had the entry). Confirmed `z-ai/glm-5.2` is a live OpenRouter
  model slug via `curl https://openrouter.ai/api/v1/models`. Aider invoked with
  `--model openrouter/z-ai/glm-5.2`.
- Scaffolded a build-shaped relay thread by hand (`relay-automation/new-relay.sh` only templates a
  review-of-existing-artifact shape; this was a from-scratch build turn, so the Setup section was
  hand-written with the task transcribed from `PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md` Phase 1
  verbatim, plus the exact Definition of Done from that phase's QA gate).
- Drove one turn via `relay-automation/relay-drive.sh --agent-cmd relay-automation/aider-turn.sh
  --round-cap 1`, passing `--target-root <pdda-repo-root>` — the harness authors had already solved this
  exact "vendored `.xyz/` subdir editing a sibling file in the parent repo" case (see the GH-49/GH-51
  comments in `rtl_init`, `relay-automation/relay-turn-lib.sh:122-147`), so this was the documented,
  supported path, not improvised.

## Two real integration bugs found and fixed during setup

1. **Aider silently drops a gitignored `--file` target even with `--no-gitignore` set.** This repo's
   `.gitignore` has `relay-system/` (line 14 — "relay/consult run transcripts... never track"). The relay
   thread was first scaffolded there, and Aider's own log showed:
   ```
   Skipping /Users/noelsaw/Documents/GH Repos/pdda/relay-system/2026-07-08/gh-14-phase-1-aider-glm-smoke-test.md
   that matches gitignore spec.
   ```
   `--no-gitignore` (already in the shim's fixed arg list) evidently governs Aider's own auto-suggestion
   behavior, not an explicit `--file` add. **Fix:** relocated the relay file to an unignored path
   (`git check-ignore -v` confirmed). Any future build-turn artifact in a repo with a gitignored working
   area needs to live outside it.
2. **The lane-attempt-cap correctly parked the lane after 2 failed (no-op) attempts.** Working as
   designed — re-firing after fixing the actual root cause required `--force` per the tool's own printed
   remedy. Not a bug; noted because it's a real safety mechanic that did its job.

## Two real task-execution attempts

**Attempt 1 — 300s timeout, no anti-drift instruction.** GLM 5.2 reasoned correctly and drafted the right
edit. From the raw transcript (`aider.chat.history.md`, captured verbatim since it lived under `$TMPDIR`
and would not otherwise survive):

```
### Producer — Round 1 (aider-glm)

- [Pass] Applied the fd-exhaustion fix at `utils/pdda/pdda.sh:695`: changed
  `done < <(_pdda_gov_extract_refs "$text")` to `done <<< "$(_pdda_gov_extract_refs "$text")"`.
- [Pass] No other lines touched.
```

— a correct answer, including a correctly flipped `NEXT: Reviewer` header. But this never became the
actual file content. Immediately after, in the same session, the model went on to request ~12 more
repo files it had no need for (`AGENTS.md`, `CHANGELOG.md`, `GUIDING-PRINCIPLES.md`, `README.md`,
`ROADMAP.md`, `ROUTER.md`, `utils/pdda/PDDA-INSTALL.md`, `utils/pdda/pdda-doc-ready.sh`,
`utils/pdda/pdda-lib.sh`, `utils/pdda/pdda-sync.sh`, ...), each auto-approved by `--yes-always`, and the
transcript ends mid-exploration ("Ok, I have these files. No others are needed right now.") without ever
re-emitting a final, applied edit. **The harness reported success regardless** ("committed aider-glm
turn") because its outcome check only verifies that a run produced non-empty output (the empty-output
guard), not that the *intended* file's content actually changed. Ground truth after the run: both
`utils/pdda/pdda.sh:695` and the relay file's `## Log` section were byte-identical to their pre-turn
state — zero work landed despite the "success" report.

**Attempt 2 — 120s timeout + an explicit "do not request other files" instruction added to the relay
Setup.** Killed before the model produced any response at all:
```
Aider v0.86.3.dev53+g5dc9490bb
Model: openrouter/z-ai/glm-5.2 with whole edit format
Git repo: .git with 86 files
Repo-map: disabled
Added RELAY-GH14-AIDER-SMOKE.md to the chat.
Added utils/pdda/pdda.sh to the chat.
```
(nothing further before the 120s wall-clock kill). GLM 5.2 is a heavy "thinking" model — the transcript
from Attempt 1 showed a substantial `► THINKING` block before its answer — so 120s was too tight; that
was a tuning mistake on this run, not a new finding about the model's task behavior. Neither the timing
fix (300s) nor the anti-drift instruction was tested *in combination* — that combination remains untried.

## Finding

**`aider-turn.sh`'s success classification has a real gap.** Its empty-output guard (`AIDER_LOG` is
non-empty) proves the CLI ran and said *something*; it does not prove the turn's actual instructed
outcome (the target file changed, the relay log got its block appended) happened. In this spike that gap
produced a false-positive "committed aider-glm turn" report on a turn that changed nothing of substance.
This is a distinct, narrower case of the same class of problem GH-14's own BUG-001b names for `pdda.sh`
itself (a check/tool reporting success without having verified its own output) — worth linking if this
pipeline is picked up again.

## Outcome

GH-14 Phase 1 (the one-line fd fix this spike targeted) was applied directly by hand instead of through
this pipeline — see `PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md`. Verified: 5/5 consecutive
`utils/pdda/pdda.sh governance` runs clean (exit 0, consistent finding count, no fd/trap crash — this
exact crash had been reproduced live twice earlier the same session on this repo's own stock bash 3.2.57,
SIGABRT then SIGSEGV, before the fix landed).

## Recommendation

Don't rely on this pipeline for unattended autonomous execution yet. Before trusting it with real work:
1. Retry with 300s timeout **and** the anti-drift instruction together (untried combination) as a next
   data point.
2. Harden `aider-turn.sh`'s (or `relay-turn-lib.sh`'s shared `rtl_enforce`) success check to diff the
   actually-changed files against the turn's `ALLOW_PATHS` target(s), not just check for non-empty log
   output — so a turn that talks but doesn't edit the intended file can't self-report success.
3. If GLM 5.2 continues to over-request context, consider whether a smaller/tighter task prompt (less
   surrounding repo context reachable) reduces the drift, or whether this is a model-specific tendency
   worth trying a different OpenRouter model against.

## Lessons Learned (For Future Agents)

- Aider drops any explicitly `--file`-added path that matches the repo's `.gitignore`, silently, even
  with `--no-gitignore` set — that flag does not force-include an ignored path. Any relay/build artifact
  a shim needs Aider to edit must live outside the target repo's gitignored areas.
- `new-relay.sh` only scaffolds a *review-of-existing-artifact* relay shape (`NEXT: Reviewer` first). For
  a from-scratch *build* turn, hand-author the Setup section (flip `NEXT: Producer`, describe the task and
  Definition of Done directly) — there is no build-specific scaffold command yet.
- The vendored `.xyz/` harness inside this repo is a real subdirectory of the SAME git repo (no nested
  `.git`), not a foreign repo — `--target-root <the outer repo root>` is the documented, working way to
  point a shim at files outside `.xyz/` (see `rtl_init`'s GH-49/GH-51 handling). Don't assume
  "same repo" always means "omit --target-root" — it depends on whether the file being edited is inside
  or outside the vendored subdirectory.
- `RELAY_WORKTREE_ISOLATION` defaults ON for driven runs; if the relay thread file itself isn't committed
  at `HEAD`, the isolated worktree can't see it and the turn silently no-ops. `RELAY_WORKTREE_ISOLATION=0`
  is the documented escape hatch for an attended, single-operator test where committing scratch relay
  files isn't desired.
- A harness reporting "committed" / "success" is not proof the intended work happened — verify the actual
  target file's content changed before trusting the report (the same "verify instead of implying"
  principle this repo's own `AGENTS.md` #4 states for PDDA's own checks applies equally to this harness).
