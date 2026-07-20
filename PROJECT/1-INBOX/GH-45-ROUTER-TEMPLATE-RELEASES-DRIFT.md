---
title: ROUTER.target.md template drifted from pdda.sh releases subcommands
status: Proposed (1-INBOX — not yet active)
created: 2026-07-20
owner: Noel Saw
gh_issue: 45
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/45
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
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

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

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
- [ ] Diff `pdda.sh` subcommand list against `templates/ROUTER.target.md` — confirm releases/releases-current are the only gap
- [ ] Name the concrete deliverable + write-set (expected: edit `templates/ROUTER.target.md` only)
- [ ] Reuse the existing ROUTER release wording rather than authoring new copy (`/ponytail`)
- [ ] Clear `ratings_provisional` once the write-set is confirmed a 1-file doc edit

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires
