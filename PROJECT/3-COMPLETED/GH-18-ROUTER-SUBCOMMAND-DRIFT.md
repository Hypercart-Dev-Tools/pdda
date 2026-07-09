---
gh_issue: 18
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/18
title: "ROUTER.md doesn't document the glance and quad-concepts pdda.sh subcommands (governance error)"
status: Completed — both subcommands documented; governance subcommand-drift errors cleared
created: 2026-07-08
updated: 2026-07-08
owner: noel
doc_type: bugfix
context_tags: [governance, install, quad-concepts]
related: [ROUTER.md, GH-12-QUAD-CONCEPTS-MODE.md, GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md]
goal: >
  Restore AGENTS.md #5 installer-surface lockstep by documenting the `glance` and `quad-concepts`
  subcommands — both added to the `pdda.sh` dispatcher by GH-12 — in ROUTER.md's Command rails list,
  clearing the two error-level `pdda-check-governance` findings on HQ.
---

## Status

| What was just completed | What's next |
|---|---|
| Added `pdda.sh quad-concepts` and `pdda.sh glance` to `ROUTER.md`'s Command rails list, with inline blurbs copied from `pdda.sh help` so the two surfaces read identically. Verified: `pdda.sh governance` subcommand-drift errors went 2 → 0. | Nothing. Close issue #18. |

## Problem

`pdda-check-governance`'s subcommand-drift check (error-level; `PROJECT/PDDA.md` § "I. `pdda.sh
governance`", check (3)) currently fails on this HQ repo:

```
ERROR [pdda-check-governance] ROUTER.md:1 pdda.sh subcommand 'glance' is not documented anywhere in ROUTER.md — keep the installer surface in lockstep (AGENTS.md #5)
ERROR [pdda-check-governance] ROUTER.md:1 pdda.sh subcommand 'quad-concepts' is not documented anywhere in ROUTER.md — keep the installer surface in lockstep (AGENTS.md #5)
```

Both `glance` (the Quad Concepts portfolio roll-up) and `quad-concepts` (the opt-in structure check) were
added to `utils/pdda/pdda.sh`'s dispatcher as part of GH-12 (Quad Concepts mode), but `ROUTER.md`'s
"Command rails" subcommand list was never updated to mention them. Found during GH-15 Phase 3
verification (2026-07-08) as a side effect of re-running `pdda.sh governance` on HQ itself.

## Impact

A real, currently-failing governance check on HQ (`errors=2`). Silent today only because this repo runs
in `observe` mode; would block a build in `full` mode. Exactly the class of installer-surface/doc drift
`pdda.sh governance`'s subcommand-drift check exists to catch (AGENTS.md #5).

## Fix

Trivial, doc-only: add `pdda.sh glance` and `pdda.sh quad-concepts` to `ROUTER.md`'s "Command rails"
subcommand list, matching how every other subcommand is already documented there. ≤2-3 lines — falls
under the issue-first SOP's trivial-edit floor; tracked here only because it surfaced mid-way through
unrelated GH-15 work and shouldn't get lost.

## Resolution (2026-07-08)

Applied as specified. Two lines added to `ROUTER.md`'s Command rails block, positioned after `stale`
and before `issue-doc-sync`, with blurbs lifted verbatim from `pdda.sh help` so the two surfaces cannot
drift apart on wording:

```
utils/pdda/pdda.sh quad-concepts    # opt-in: a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
```

**Verified:** `utils/pdda/pdda.sh governance` → subcommand-drift `errors=2` before, `errors=0` after.

## Lessons Learned (For Future Agents)

- The subcommand-drift check reads `ROUTER.md` for *any* mention of the subcommand name, not a
  specific format. It caught this because GH-12 shipped dispatcher entries and `help` text but stopped
  short of `ROUTER.md` — the one surface an agent reads first. **Adding a `pdda.sh` subcommand is a
  three-file change (dispatcher + `help` + `ROUTER.md`), not two.**
- Copying the blurb from `pdda.sh help` verbatim, rather than paraphrasing, means a future wording
  change in one place is a visible diff in the other.
