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
     Enforced by `pdda.sh roadmap` + `pdda.sh roadmap-coverage` (deterministic) + utils/pdda/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

# PDDA Standalone Roadmap

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.

This standalone repo exists to keep the PDDA contract, shell checks, and extraction manifest in sync.

## Status

| What was just completed | What's next |
|---|---|
| Added root `install.sh` (installs the PDDA surface into a foreign repo in a clean zero state) and rewrote `README.md` for operator onboarding; `PDDA-INSTALL.md` + `ROUTER.md` updated in lockstep. | Re-auth `gh`, open the tracking issue, rename the working doc to `GH-<n>-…`, then merge the branch. |

## Ledger

### Queue / parked intake

- No parked intake docs.

### In progress

- **Root `install.sh` + operator onboarding** (2026-06-25) - installer that provisions a foreign repo to a clean zero state; README rewritten for onboarding. Tracking issue pending `gh` re-auth. -> [PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md](PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md)
- **Sync the PDDA runtime to other repos** (2026-06-27) - register repos for the `utils/pdda/` runtime, then a launchd job every 30 min content-hash-syncs changes (backup-then-overwrite); registry lives in gitignored `temp/`. Plan/decisions captured; impl pending approval. -> [PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md](PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md)

### Completed

- **Standalone baseline established** (2026-06-24) - repo-facing docs now describe `pdda` itself, placeholder scaffolding is normalized, and the install manifest matches the shipped scripts. -> [PROJECT/PDDA.md](PROJECT/PDDA.md) and [utils/PDDA-INSTALL.md](utils/PDDA-INSTALL.md)
- **`utils/` consolidated to 3 files** (2026-06-24) - the 7 per-check scripts + `pdda-run.sh` collapsed into one `pdda.sh` dispatcher (`pdda.sh run` / `pdda.sh <check>`); `pdda-lib.sh` and the opt-in `pdda-doc-ready.sh` stay separate. Breaking change to the install contract; old filenames removed. -> [utils/PDDA-INSTALL.md](utils/PDDA-INSTALL.md)

### Deferred

- No deferred docs.

---

*Add new work here only when a real `PROJECT/**` doc exists to own the execution detail.*
