---
title: PDDA Standalone Roadmap
status: Active
created: 2026-06-24
updated: 2026-06-24
branch: main
goal: >
  Canonical pointer ledger for the standalone PDDA installer repo. This file tracks the repo's
  own maintenance state and points to the canonical contract/install artifacts without copying
  another project's live roadmap.
---

<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by utils/pdda-check-roadmap.sh + utils/pdda-check-roadmap-coverage.sh (deterministic) + utils/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

# PDDA Standalone Roadmap

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.

This standalone repo exists to keep the PDDA contract, shell checks, and extraction manifest in sync.

## Status

| What was just completed | What's next |
|---|---|
| Standalone baseline reset complete: repo-facing docs now describe `pdda` itself, the install manifest matches the shipped suite, and scaffolding uses the expected `blank.md` convention. | Keep the contract and install manifest in lockstep as PDDA evolves. Open a real `PROJECT/**` doc before the next substantive change instead of rebuilding ad hoc notes inside this ledger. |

## Ledger

### Queue / parked intake

- No parked intake docs.

### In progress

- No active `PROJECT/2-WORKING` docs.

### Completed

- **Standalone baseline established** (2026-06-24) - repo-facing docs now describe `pdda` itself, placeholder scaffolding is normalized, and the install manifest matches the shipped scripts. -> [PROJECT/PDDA.md](PROJECT/PDDA.md) and [utils/PDDA-INSTALL.md](utils/PDDA-INSTALL.md)

### Deferred

- No deferred docs.

---

*Add new work here only when a real `PROJECT/**` doc exists to own the execution detail.*
