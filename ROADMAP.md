---
title: PDDA Standalone Roadmap
status: Active
created: 2026-06-24
updated: 2026-07-06
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
| Completed the **Defacto Project Memory Layer** reframing — `ROUTER.md` retrieval step, `PROJECT/PDDA.md` Memory Injection + Lessons Learned + `context_tags`, and two warn-only memory nudges in `pdda-doc-ready.sh`; CHANGELOG logged, README "The project memory layer" section added, doc archived to `PROJECT/3-COMPLETED/`. | GH-10 Sentinel is the active build (Phase 2b executor next). Operator opt-in still open: `register` real secondary repos for live sync propagation. |

## Ledger

### Queue / parked intake

- **GH-11 — myriad-review reader** (2026-07-06) - give the `/myriad` parking lot a read path: a tiny
  read-only `utils/pdda/pdda-myriad.sh review [--weeks N]` that prints open items grouped by week, plus a
  one-line pointer from `pdda.sh run` so `/pdda` surfaces the backlog transitively. Queued as phase `p1`
  of the [2026-07-07 marathon](marathon/MARATHON-2026-07-07.yaml). Issue
  [#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11). -> [PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md](PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md)
- **agents-builder skill** (2026-07-06) - a Claude Code skill that interviews a user (scenario → infer
  camps) and writes an `AGENTS-TEMP.md` from the architectural camps in `AGENTS-BUILDER.md`; never
  touches an existing `AGENTS.md`. Global skill, content embedded; built repo-local then hand-installed.
  Queued as phase `p2` of the [2026-07-07 marathon](marathon/MARATHON-2026-07-07.yaml). ->
  [PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md](PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md)
- **GH-9 — weekly progress counter (open GH issues + closed tasks this week)** (2026-07-03) - new
  deterministic `pdda.sh progress` subcommand for maintainer visibility; builds on the existing
  gh-state cache + `3-COMPLETED/` doc lifecycle. "Closed Marathons" (a `tick`/xyz-3-agents-swarm
  concept, not a PDDA one) is explicitly out of scope for this issue. Issue
  [#9](https://github.com/Hypercart-Dev-Tools/pdda/issues/9). -> [PROJECT/1-INBOX/GH-9-WEEKLY-PROGRESS-COUNTER.md](PROJECT/1-INBOX/GH-9-WEEKLY-PROGRESS-COUNTER.md)

### In progress

- **GH-10 — Sentinel: repo-driven doc-governance automation** (2026-07-04) - the act-on-it layer for
  PDDA: on merge to `main`, build context from the diff, ask the model (via `PDDA_LLM_BIN`) whether
  governance docs should change, apply edits inside a git worktree on an allowlisted path set, gate on
  `pdda.sh run`, and finalize as dry-run → PR → selective local-commit under a deterministic policy
  gate + per-category trust score. One pipeline; only the finalizer graduates. 7 phases (replanned
  after a GLM 5.2 review). **Phase 1 shipped** (dry-run orchestrator `sentinel/run.sh`, 26/26 tests);
  Phase 2 (worktree apply) next. Issue [#10](https://github.com/Hypercart-Dev-Tools/pdda/issues/10).
  -> [PROJECT/2-WORKING/GH-10-SENTINEL.md](PROJECT/2-WORKING/GH-10-SENTINEL.md)
- **Root `install.sh` + operator onboarding** (2026-06-25) - installer that provisions a foreign repo to a clean zero state; README rewritten for onboarding. Tracking issue pending `gh` re-auth. -> [PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md](PROJECT/2-WORKING/INSTALL-SCRIPT-AND-ONBOARDING.md)
- **Reconcile pdda-sync `list` vs `status` wording** (2026-06-30) - a just-installed-but-unpushed target read as `not-yet-pushed` in `list` while `status` reported it current; `list` is now content-aware (`current`/`out-of-sync` + `(unpushed)` marker). Iteration 1 shipped. -> [PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md](PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md)

### Completed

- **Defacto Project Memory Layer** (2026-07-06) - reframed PDDA as a de facto project memory layer via three coordinated conventions and no new deterministic surface: `ROUTER.md` startup now retrieves prior context from `3-COMPLETED/`/`CHANGELOG.md` when exploring or blocked; spikes are framed as **Memory Injection** and a `## Lessons Learned (For Future Agents)` section is required before completion; optional `context_tags` frontmatter + two warn-only LLM nudges (`related:` on medium-large plans, `decisions/` link on `risk: 4`/`5`). Governance clean; README "The project memory layer" section added. -> [PROJECT/3-COMPLETED/PROJECT-MEMORY-LAYER.md](PROJECT/3-COMPLETED/PROJECT-MEMORY-LAYER.md)
- **GH-7 — auto-detect git-pulse repo path for the registry projection** (2026-06-30) - the multi-device projection silently skipped on devices where git-pulse's sync repo isn't at the hardcoded default `~/.config/git-pulse/repo` (e.g. `~/git-pulse-sync` on Mac Studio); `publish_registry_projection()` now resolves it via `PDDA_GITPULSE_DIR` → git-pulse `config.sh` `sync_repo_dir` → candidate list, still best-effort/fail-open. 17/17 publish tests (new autodetect case) + real-world plain-install verification; lockstep `install.sh`/`PDDA-INSTALL.md`. Issue [#7](https://github.com/Hypercart-Dev-Tools/pdda/issues/7) (closed). -> [PROJECT/3-COMPLETED/GH-7-GITPULSE-PATH-AUTODETECT.md](PROJECT/3-COMPLETED/GH-7-GITPULSE-PATH-AUTODETECT.md)
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
