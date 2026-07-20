---
title: ROUTER.target.md template drifted from pdda.sh releases subcommands
status: Completed (2026-07-20 → PR #46 merged, issue #45 closed)
created: 2026-07-20
owner: Noel Saw
gh_issue: 45
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/45
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - Reworking how install.sh derives ROUTER.md from the template
  - Auditing every other subcommand for template coverage beyond releases/releases-current
related:
  - PROJECT/3-COMPLETED/GH-18-ROUTER-SUBCOMMAND-DRIFT.md
  - PROJECT/3-COMPLETED/GH-23-AGENT-ONRAMP.md
goal: >
  Bring templates/ROUTER.target.md back into lockstep with pdda.sh so a fresh
  --with-startup-docs install passes pdda-check-governance instead of reporting two
  undocumented-subcommand errors (releases, releases-current) on its first run.
---

# GH-45 — ROUTER.target.md template drifted from pdda.sh releases subcommands

> **Completed.** A one-file bugfix that went capture → fix → merge in a single session, so it never
> passed through `PROJECT/2-WORKING/` — the write-set was scoped and verified from the capture itself.
> Landed in PR [#46](https://github.com/Hypercart-Dev-Tools/pdda/pull/46) (merged), issue
> [#45](https://github.com/Hypercart-Dev-Tools/pdda/issues/45) closed.

## Key concepts
- `install.sh --with-startup-docs` writes a target's `ROUTER.md` from `templates/ROUTER.target.md`
  (the canonical `ROUTER.md` is deliberately not copied — it documents install/sync/xyz surfaces a
  target lacks, GH-23).
- `pdda-check-governance` asserts every `pdda.sh` subcommand is documented in `ROUTER.md`.
- The template never picked up the `releases` / `releases-current` rail that the canonical
  `ROUTER.md` carries, so the assertion fires against every freshly installed target.

## Idea
templates/ROUTER.target.md is out of lockstep with pdda.sh: the `releases` and `releases-current`
subcommands are documented in the canonical ROUTER.md but missing from the ROUTER.target.md template,
so every new install's first governance run reports 2 errors (pdda-check-governance, non-blocking in
observe, would block in full).

## Why
The template is the canonical router minus the sections a target doesn't have — but a subcommand rail
is exactly the kind of content a target *does* need. When it drifts, the install's own verification
pass flags the target for a defect the target's maintainer didn't introduce and can't easily explain.
This is the same failure class GH-18 (ROUTER subcommand drift) and GH-23 (dead-reference self-check on
the written router) already fought; the release subcommands slipped through because they postdate the
template's last lockstep pass. `TODO(operator)`: confirm no other subcommand is missing from the
template while fixing releases.

## Phase 0 — Explore & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Diff `pdda.sh` subcommand list against `templates/ROUTER.target.md` — confirm releases/releases-current are the only gap
- [x] Name the concrete deliverable + write-set (expected: edit `templates/ROUTER.target.md` only)
- [x] Reuse the existing ROUTER release wording rather than authoring new copy (`/ponytail`)
- [x] Clear `ratings_provisional` once the write-set is confirmed a 1-file doc edit

### Findings
Reproduced the check's own extraction logic (`pdda.sh` § "subcommand drift", the `case "$cmd" in`
awk scan minus `run|help|-h|--help|*`): `pdda.sh` ships **16** dispatcher subcommands. Cross-referenced
against `templates/ROUTER.target.md` — `releases` and `releases-current` were the **only** two missing,
matching the install-time governance report exactly. No other subcommand had drifted.

Write-set was a single file, `templates/ROUTER.target.md`, with two verbatim grafts from the canonical
`ROUTER.md`:
- **Command rails** — added the `releases` and `releases-current` lines (canonical L81–82) before
  `governance`. This is the edit that clears the two governance errors.
- **Role split** — added the `RELEASES.md` legend line (canonical L27). `install.sh` seeds a
  `RELEASES.md` into every target, so the router should name the file it ships; this keeps the
  template honest, not just green.

Verified by a fresh `install.sh --with-startup-docs --mode observe --no-register` into a scratch git
repo: `pdda-check-governance` went from `errors=2` to `errors=0`. (The scratch run shows 2 unrelated
`README.md` dead-reference *warnings* only because the empty scratch repo has no README; a real target
does.)

### QA checklist — Phase 0
- [x] The scope is grounded in real code/history, not a hypothetical
- [x] Composes with existing commands rather than adding a parallel path
- [x] A human checkpoint remains before anything fires
