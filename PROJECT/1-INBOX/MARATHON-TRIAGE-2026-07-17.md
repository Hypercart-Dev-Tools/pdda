---
title: Marathon triage — 2026-07-17
created: 2026-07-17
owner: noel
doc_type: project
status: Proposed (1-INBOX — triage output, not a work item)
---

# Marathon triage — 2026-07-17

Ran `utils/marathon-triage`'s procedure against `pdda` (main, clean). Bottom line: **zero
lanes are marathon-ready today.** Every open, docced item fails preflight on contract
grounds (exit 3 — missing/invalid `## Swarm Preflight Contract` json block), confirmed
both by hand and by `.xyz/utils/marathon-plan.sh --dry-run --deep` (exit 4, drift=true,
held=8). This is a "nothing to fire" triage, not a stalled one — the candidate pool is
real, it just needs contracts authored first.

## Classification

| GH# | Doc | Location | Issue state | Bucket | Notes |
|---|---|---|---|---|---|
| 9 | GH-9-WEEKLY-PROGRESS-COUNTER.md | 1-INBOX | OPEN | NEEDS-CONTRACT (+ needs promote) | effort 3 / cx 3 / risk 1 / phases 2 |
| 10 | GH-10-SENTINEL.md | 2-WORKING | OPEN | NEEDS-CONTRACT | Has a "## Preflight contract" heading, but it's prose (bet/reversibility/blast-radius per AGENTS.md #2/#3), not a fenced json block. The one json block in the doc lives under "## Structured output contract" — that's Sentinel's own LLM output schema, not a swarm contract. 36K doc, Phase 2b complete, Phase 3 next. |
| 11 | GH-11-MYRIAD-REVIEW-READER.md | 2-WORKING | OPEN | NEEDS-CONTRACT + **stale dependency** | Built to read the `/myriad` parking lot — but the Myriad skill itself was deleted from this repo on 2026-07-09 ("Remove Myriad skill - moved to giant brains", `ec886b6`). Doc still reads "queued for the 2026-07-07 marathon." Needs an operator call before it's worth contracting: close #11 as obsolete, or re-scope against wherever Myriad lives now. |
| 14 | GH-14-GOVERNANCE-FD-EXHAUSTION.md | 2-WORKING | OPEN | NEEDS-CONTRACT | effort 2 / cx 2 / risk 1 / phases 3, `doc_type: bugfix` |
| 21 | GH-21-PDDA-HOOK-SKILL.md | 1-INBOX | **CLOSED** | STALE-CLOSED | Propose archive → `3-COMPLETED/`. Independently flagged by `marathon-plan.sh` (`already-closed`, still listed under ROADMAP's "Queue / parked intake"). |
| 28 | GH-28-REGISTRY-PROJECTION-DRIFT.md | 2-WORKING | **CLOSED** | STALE-CLOSED | Propose archive → `3-COMPLETED/`. Same `already-closed` flag from `marathon-plan.sh`. Doc's own status line notes "one non-code follow-up remains (operator's stalled git-pulse checkout)" — confirm that's not still owed before archiving. |
| — | AGENTS-BUILDER-SKILL.md | 2-WORKING | **no linked GH issue** | NEEDS-CONTRACT | Also stale-referenced to the 2026-07-07 marathon (`marathon/briefs/p2-agents-builder-skill.md`); nothing was ever built (no skill file exists anywhere in the tree). Can't be preflighted by `--gh-issue` at all — needs either a filed issue or a decision to drop it. |
| 13 | *(none)* | — | OPEN | NEEDS-CONTRACT (no doc) | Small, well-scoped: bracketless changelog-date regex false-positive. Issue body already contains the fix diff. |
| 36 | *(none)* | — | OPEN | NEEDS-CONTRACT (no doc) | Small, well-scoped: governance exemption matcher over-normalizes `../` paths. Issue body already has a suggested fix direction. Severity noted as low by the reporter. |
| 40 | *(none)* | — | OPEN | NEEDS-CONTRACT (no doc) | Small, well-scoped: warn when `Release:` isn't SemVer. Issue body already has explicit acceptance criteria — closest of the three to contract-ready. |
| 38 | *(none)* | — | OPEN | **NOT-A-WORK-ITEM** | "Always on - Cactus SLM sentinel" — an unsolicited architecture brainstorm ("Verdict: Not crazy"), no concrete deliverable or acceptance criteria. Exclude from the marathon track entirely. |
| 39 | *(none)* | — | OPEN | **NOT-A-WORK-ITEM** (yet) | "Multi-project/repo Release schedule" — one sentence, no scope, depends on an undefined HQ integration. Needs a `/idea` capture pass before it's even a triage candidate. |

Two more `marathon-plan.sh` flags are noise, not findings: **"Standalone baseline
established"** and **"utils/ consolidated to 3 files"** are both 2026-06-24 entries
already in ROADMAP's Completed section, from before the GH-issue-per-item convention —
they point straight at `PROJECT/PDDA.md`/`PDDA-INSTALL.md` instead of a capture doc, which
trips the planner's `note-only`/`undocumented-partial-completion` heuristics. No action
needed; ledger format could be tidied to stop the noise on future runs.

## Ranked candidate list

Not applicable this run — every open item is `NEEDS-CONTRACT` (preflight exit 3). There is
no ready set to rank or preflight-verify yet.

## Forward-looking collision read

Once contracts exist, most of this pool collides on one file. GH-9, GH-13, GH-14, GH-36,
and GH-40 all land in `utils/pdda/pdda.sh` / `pdda-lib.sh` (progress subcommand, changelog
regex, governance fd/exemption fixes, releases SemVer warn) — that's kernel-zone
territory, so treat these as **one serialized lane**, not a parallel wave, regardless of
how small each fix is individually. GH-10 (Sentinel) is the one item with a genuinely
disjoint footprint (new `sentinel/` surface, no touches to `pdda.sh` core) — the only
candidate that could run its own lane alongside the pdda.sh-core lane once both are
contracted. GH-11 and AGENTS-BUILDER-SKILL.md stay out of any wave until their stale-doc
questions below are resolved.

## Needs a decision (operator)

1. Archive `GH-21` and `GH-28` docs to `3-COMPLETED/` (issues closed) — confirm GH-28's
   noted git-pulse-checkout follow-up isn't still owed first.
2. Drop or move the `GH-21`/`GH-28` pointers out of ROADMAP's "Queue / parked intake" —
   same `already-closed` flag `marathon-plan.sh` raises every run until this is fixed.
3. Resolve `GH-11`: its dependency (the Myriad skill) was deleted from this repo
   2026-07-09. Close as obsolete, or re-scope against wherever Myriad lives now
   ("giant brains").
4. Resolve `AGENTS-BUILDER-SKILL.md`: stale 2026-07-07 marathon reference, no linked
   issue, nothing built. File an issue, fold it into existing scope, or drop it.
5. Author preflight contracts for `GH-9`, `GH-10`, `GH-14` — already promoted/rated, just
   missing the machine-readable `## Swarm Preflight Contract` json block.
6. Capture + contract `GH-13`, `GH-36`, `GH-40` — issue-only today, but all three are small
   and their issue bodies already carry most of what a contract needs (fix location, diff
   or acceptance criteria).
7. Run `GH-39` through `/idea` before treating it as marathon material; exclude `GH-38`
   entirely.
8. Minor cleanup: repo-root `2-WORKING/MYRIAD-WEEK-2026-07-06.md` and
   `marathon/{MARATHON-2026-07-07.yaml,briefs/p1-myriad-review-reader.md,briefs/p2-agents-builder-skill.md}`
   are tracked leftovers from the 2026-07-07 marathon that never fired cleanly — worth a
   pass now that both queued items (#11, agents-builder) are confirmed stale.

No lane fired, no doc promoted, no issue closed — this doc is a proposal for the operator
to act on.

## Disposition (2026-07-18)

Acted on. Items 1-2 landed in `0fae994`: GH-21 and GH-28 capture docs archived to
`3-COMPLETED/`, both ROADMAP entries moved from "Queue / parked intake" to "Completed".
Verified `pdda.sh governance` and `roadmap-coverage` at errors=0 warns=0, and
`marathon-plan.sh --dry-run --deep` drift `true -> false` with both `already-closed`
flags cleared (`held=8` unchanged — those are the NEEDS-CONTRACT items).

Items 3-8 are tracked as a checklist on issue
[#41](https://github.com/Hypercart-Dev-Tools/pdda/issues/41), which also carries two
residuals this doc didn't call out: GH-28's non-goal git-pulse-checkout follow-up
(recorded so archiving didn't bury it) and the ROADMAP ledger-format tidy for the
2026-06-24 pre-convention entries noted above. Item 8 (marathon leftovers) was
deliberately **held** rather than swept — those artifacts belong to the marathon whose two
phases are exactly items 3 and 4, so clearing them would presume those decisions.

Harness defect found during this run filed upstream as
[xyz-3-agents-swarm#247](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/247):
`marathon-triage`'s bare `utils/` script paths don't resolve in a vendored `.xyz/` install,
which is why this run required hand-substituting `.xyz/utils/marathon-plan.sh`.
