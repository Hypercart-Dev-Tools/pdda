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
| Completed **GH-5** — `pdda.sh issue-doc-sync` (deterministic drift check) + `pdda.sh gh-refresh` (offline gh-state cache) + two-tier PostToolUse/Stop doc-health hooks; all phases shipped, tested (31), committed + pushed; issue #5 closed, doc archived to `PROJECT/3-COMPLETED/`. | The `install.sh` + onboarding item remains in progress. Operator opt-in: `register` real secondary repos (and optionally `install-agent`) for live sync propagation. |

## Ledger

### Queue / parked intake

- No parked intake docs.

### In progress

- **Root `install.sh` + operator onboarding** (2026-06-25) - installer that provisions a foreign repo to a clean zero state; README rewritten for onboarding. Tracking issue pending `gh` re-auth. -> [PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md](PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md)
- **Reconcile pdda-sync `list` vs `status` wording** (2026-06-30) - a just-installed-but-unpushed target read as `not-yet-pushed` in `list` while `status` reported it current; `list` is now content-aware (`current`/`out-of-sync` + `(unpushed)` marker). Iteration 1 shipped. -> [PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md](PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md)

### Completed

- **Multi-device PDDA status via git-pulse piggyback** (2026-06-30) - `install.sh` now publishes a per-device, **path-normalized** registry projection (repo name + date + source commit + mode, no folder path) into a `pdda/` folder of git-pulse's sync repo on every install/upgrade; git-pulse's existing sync carries it across devices. Best-effort/fail-open, no new command or git logic. 10/10 publish test green; today's ledger backfilled. -> [PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md](PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md)

- **Issue↔doc sync check + two-tier doc-health hooks** (2026-06-29) - new warn-only `pdda.sh issue-doc-sync` flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state (both directions); `pdda.sh gh-refresh` writes the offline gh-state cache; two-tier PostToolUse (single-file lint) + Stop (consolidated full-scan) doc-health hooks. Deterministic, warn-only, fail-open; 31 tests; all phases shipped, committed + pushed. Issue [#5](https://github.com/Hypercart-Dev-Tools/pdda/issues/5) (closed). -> [PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md](PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md)
- **PDDA-EOD skill — end-of-day wrap** (2026-06-29) - `/pdda-eod` runs hygiene checks, reconciles docs/ROADMAP/CHANGELOG, helps reach a clean/pushed tree, and closes 100%-done issues (user-verified); delegates deterministic work to `pdda.sh`, all propose-then-confirm. Shipped at `SKILLS/PDDA-EOD/SKILL.md`. Issue [#6](https://github.com/Hypercart-Dev-Tools/pdda/issues/6). -> [PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md](PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md)
- **Sync the PDDA runtime to other repos** (2026-06-27 → completed 2026-06-29) - `utils/pdda/pdda-sync.sh`: HQ → registered-targets, on-demand `push` (manual primary, launchd optional) over an auto-regenerated manifest shared with `install.sh`; content-hash state-stamp copy, delete-mirror with backup, manifest-poisoning guard. Realigned + Codex relay-approved (4 rounds), built in 5 phases, every QA gate green + end-to-end dogfood. -> [PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md](PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md)
- **Standalone baseline established** (2026-06-24) - repo-facing docs now describe `pdda` itself, placeholder scaffolding is normalized, and the install manifest matches the shipped scripts. -> [PROJECT/PDDA.md](PROJECT/PDDA.md) and [utils/PDDA-INSTALL.md](utils/PDDA-INSTALL.md)
- **`utils/` consolidated to 3 files** (2026-06-24) - the 7 per-check scripts + `pdda-run.sh` collapsed into one `pdda.sh` dispatcher (`pdda.sh run` / `pdda.sh <check>`); `pdda-lib.sh` and the opt-in `pdda-doc-ready.sh` stay separate. Breaking change to the install contract; old filenames removed. -> [utils/PDDA-INSTALL.md](utils/PDDA-INSTALL.md)

### Deferred

- No deferred docs.

---

*Add new work here only when a real `PROJECT/**` doc exists to own the execution detail.*
