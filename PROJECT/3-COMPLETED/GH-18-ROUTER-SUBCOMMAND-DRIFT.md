---
gh_issue: 18
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/18
title: "ROUTER.md doesn't document the glance and quad-concepts pdda.sh subcommands (governance error)"
status: Fixed (pending PR merge)
created: 2026-07-08
doc_type: bugfix
context_tags: [governance, install, quad-concepts]
related: [ROUTER.md, GH-12-QUAD-CONCEPTS-MODE.md, GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md]
---

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

Added both subcommands to `ROUTER.md`'s "Command rails" list, in the same order `pdda.sh help` already
lists them (`quad-concepts` after `status-table`, `glance` right after that) — matching the fact that
`README.md` already documented both correctly, so `ROUTER.md` was the only doc actually out of lockstep.

**Verified:** `pdda.sh governance` now reports `errors=0 warns=0` (previously `errors=2`). Full `pdda.sh
run` clean. Shipped together with GH-17 on branch `fix/GH-17-GH-18`; PR open, not yet merged.
