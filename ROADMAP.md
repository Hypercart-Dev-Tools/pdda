---
title: PDDA Standalone Roadmap
status: Active
created: 2026-06-24
updated: 2026-07-07
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
| **Canonical-repo governance cleared to zero.** GH-17 (retired RECAP / REAL-AGENT-OBSERVATIONS prose drift) and GH-18 (`ROUTER.md` missing `glance`/`quad-concepts`) both fixed and promoted to `3-COMPLETED`; three inactive docs archived to `4-MISC`. `pdda.sh run` on the canonical repo went 3 errors + 6 warns → **0 errors + 0 warns**. The `experimental/PRD-pdda/` synthesis skill is registered below. | **GH-23 (agent on-ramp) is queued for immediate work** — targets inherit the canonical repo's `ROUTER.md` verbatim despite the "adapted" claim, and no deterministic check can see it. It rhymes with GH-14 Phase 2 (BUG-001b): both are cases of `pdda.sh run` reporting success over a real defect, so consider landing them together. Then close issues #17 and #18. GH-12 is ready to close to `3-COMPLETED`. GH-10 Sentinel remains the other active build (Phase 2b executor). |

## Ledger

### Queue / parked intake
- **GH-21 — SKILLS/PDDA-hook opt-in SessionStart doc-governance reminder** (2026-07-08) - new bundled
  skill that installs a `SessionStart` hook re-anchoring `ROUTER.md`/`AGENTS.md`/`PROJECT/PDDA.md` at
  every context boundary (startup/resume/clear/compact), auto-scoped via `PROJECT/PDDA.md` detection,
  global- or repo-local-scoped, propose-then-confirm, never touches a repo's committed `settings.json`.
  Implemented same-session as capture. Issue [#21](https://github.com/Hypercart-Dev-Tools/pdda/issues/21). ->
  [PROJECT/1-INBOX/GH-21-PDDA-HOOK-SKILL.md](PROJECT/1-INBOX/GH-21-PDDA-HOOK-SKILL.md)
- **Marathon Plan (2026-07-07)** (2026-07-07) - the canonical XYZ-format marathon plan doc
  (hand-authored per `.xyz/README.md`'s Option B — the ROADMAP auto-generator, Option A, currently
  reports 0 active lanes) for the two build phases below, distinct from the machine-executable
  `marathon/MARATHON-2026-07-07.yaml`. ->
  [PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md)
- **GH-11 — myriad-review reader** (2026-07-06) - give the `/myriad` parking lot a read path: a tiny
  read-only `utils/pdda/pdda-myriad.sh review [--weeks N]` that prints open items grouped by week, plus a
  one-line pointer from `pdda.sh run` so `/pdda` surfaces the backlog transitively. Queued as phase `p1`
  of the [2026-07-07 marathon](marathon/MARATHON-2026-07-07.yaml). Issue
  [#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11). -> [PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md](PROJECT/2-WORKING/GH-11-MYRIAD-REVIEW-READER.md)
- **agents-builder skill** (2026-07-06) - a Claude Code skill that interviews a user (scenario → infer
  camps) and writes an `AGENTS-TEMP.md` from the architectural camps in
  `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/OPINIONATED-PATTERNS.md`; never touches an existing
  `AGENTS.md`. Global skill, content embedded; built repo-local then hand-installed.
  Queued as phase `p2` of the [2026-07-07 marathon](marathon/MARATHON-2026-07-07.yaml). ->
  [PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md](PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md)
- **GH-9 — weekly progress counter (open GH issues + closed tasks this week)** (2026-07-03) - new
  deterministic `pdda.sh progress` subcommand for maintainer visibility; builds on the existing
  gh-state cache + `3-COMPLETED/` doc lifecycle. "Closed Marathons" (a `tick`/xyz-3-agents-swarm
  concept, not a PDDA one) is explicitly out of scope for this issue. Issue
  [#9](https://github.com/Hypercart-Dev-Tools/pdda/issues/9). -> [PROJECT/1-INBOX/GH-9-WEEKLY-PROGRESS-COUNTER.md](PROJECT/1-INBOX/GH-9-WEEKLY-PROGRESS-COUNTER.md)

### In progress

- **GH-23 — agent on-ramp is wrong, expensive, and unenforced** (2026-07-09) - **active; promoted to
  `2-WORKING` 2026-07-09, built on branch `gh-23-agent-onramp`.** `--with-startup-docs` advertises an
  "adapted" `ROUTER.md` but `copy_runtime` copies it verbatim (`install.sh:65` vs `install.sh:245`), so
  every target inherits the canonical repo's router — telling agents to run `install.sh` and `utils/pdda/pdda-sync.sh`,
  neither of which exists in a target. The deterministic surface can't see it: `_pdda_gov_extract_refs`
  matches only `.md` refs by design, so `pdda.sh run` reports "all checks passed" on a router that
  misdirects. Found by dogfooding in `LTVera-Pandas`, where the GH-21 `SessionStart` hook fired correctly
  and the agent still skipped directive 1 — the one directive that is expensive (66KB of reading) and
  unverifiable. 4 phases, each gated on a green `pdda.sh run`: template the target router, post-install
  self-check, widen dead-ref scanning to `.sh`, then make directive 1 cheap (`/pdda`) and optionally
  gated. Shares a root cause with GH-14 Phase 2 (BUG-001b) — both are `run` reporting success over a real
  defect — so P3 is a candidate to land alongside it. Issue
  [#23](https://github.com/Hypercart-Dev-Tools/pdda/issues/23). ->
  [PROJECT/2-WORKING/GH-23-AGENT-ONRAMP.md](PROJECT/2-WORKING/GH-23-AGENT-ONRAMP.md)
- **PRD generator skill exploration — PRD-Kimi vs PRD-Perplexity, synthesized into PRD-pdda** (2026-07-08) -
  three draft-stage variants of a not-yet-built `product-prd-builder` skill (structured PRD →
  Spec/Roadmap interview). `PRD-Perplexity/` is the original draft (renamed, unchanged) and is the only
  one shaped as a real skill (frontmatter + a `references/` folder); `PRD-Kimi/` is a single-file design
  narrative that embeds its six proposed reference files inline as fenced blocks, and forks Phase 2 on an
  Iron Triangle choice (Faster/Better/Cheaper). `PRD-pdda/` is the **synthesis of both**, and is the one
  to build from: Perplexity's execution rigor (FR-IDs, P0/P1/P2, verifiable acceptance criteria, data
  model, NFR table, guardrail metric, agent-executable milestones) written in Kimi's plain-English voice,
  with Kimi's Iron Triangle promoted from a label to the *governor* of milestone count, pacing, and
  validation-gate density. Adds a two-mode intake (quick-fire vs. brain dump) over one shared field set
  and one shared inference library, capped at ≤10 interview questions. Kimi's Cheaper-branch "UX/Dev Ratio
  Discipline" is carried through verbatim in spirit — the load-bearing idea that Cheaper's failure mode is
  an *uneven* UX-vs-dev split, not underspending, and so demands *more* operator discipline than the other
  two branches, not less. No `PROJECT/**` doc or GH issue yet (exploratory content, outside
  `pdda.sh roadmap-coverage` scope); not yet converted into an installed skill. ->
  [experimental/PRD-pdda/SKILL.md](experimental/PRD-pdda/SKILL.md),
  [experimental/PRD-Kimi/SKILL.md](experimental/PRD-Kimi/SKILL.md),
  [experimental/PRD-Perplexity/SKILL.md](experimental/PRD-Perplexity/SKILL.md)
- **GH-14 — governance fd exhaustion on stock macOS bash 3.2** (2026-07-08) - dead-reference scan in
  `pdda-check-governance` (`utils/pdda/pdda.sh:695`) exhausts file descriptors under bash 3.2.57 (stock
  macOS, no Homebrew bash); worse, a crashed check still lets `pdda.sh run` report "all checks passed"
  (BUG-001b). **Phase 1 shipped** (the one-line fix, applied by hand after an Aider/GLM-5.2 pipeline
  test attempt didn't land it — see the completed spike doc below); verified 5/5 clean runs on this
  repo's own bash 3.2.57. Phase 2 (BUG-001b summary field) next. Issue
  [#14](https://github.com/Hypercart-Dev-Tools/pdda/issues/14). ->
  [PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md](PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md)
- **GH-12 — Quad Concepts mode** (2026-07-07) - opt-in glance layer: tracked plan docs carry a
  `## Quad Concepts` section of 1–4 `pain → fix` bullets after `## Status`, so a cold-start reader gets
  5-second orientation and an operator can see if a plan covers the real pains. Orthogonal opt-in lever
  (`.pdda-quad`, off by default), structure-only deterministic check + warn-only LLM rubric. Synthesizes
  a GLM 5.2 pass + two Codex/agy consults. **All 4 phases shipped + consult-passed** (check+lever, LLM
  quality rubric, `pdda.sh glance` roll-up; 42/42 + 6/6). Ready to close to `3-COMPLETED`. Issue
  [#12](https://github.com/Hypercart-Dev-Tools/pdda/issues/12). -> [PROJECT/2-WORKING/GH-12-QUAD-CONCEPTS-MODE.md](PROJECT/2-WORKING/GH-12-QUAD-CONCEPTS-MODE.md)
- **GH-10 — Sentinel: repo-driven doc-governance automation** (2026-07-04) - the act-on-it layer for
  PDDA: on merge to `main`, build context from the diff, ask the model (via `PDDA_LLM_BIN`) whether
  governance docs should change, apply edits inside a git worktree on an allowlisted path set, gate on
  `pdda.sh run`, and finalize as dry-run → PR → selective local-commit under a deterministic policy
  gate + per-category trust score. One pipeline; only the finalizer graduates. 7 phases (replanned
  after a GLM 5.2 review). **Phase 1 shipped** (dry-run orchestrator `sentinel/run.sh`, 26/26 tests);
  Phase 2 (worktree apply) next. Issue [#10](https://github.com/Hypercart-Dev-Tools/pdda/issues/10).
  -> [PROJECT/2-WORKING/GH-10-SENTINEL.md](PROJECT/2-WORKING/GH-10-SENTINEL.md)

### Completed

- **GH-17 — PROJECT/PDDA.md dead-referenced two retired conventions** (2026-07-08) - `PROJECT/PDDA.md`'s
  CHANGELOG section claimed `RECAP.md` was "retired → `PROJECT/4-MISC/`" and that
  `REAL-AGENT-OBSERVATIONS.md` "still holds run-specific compliance findings". Neither file has ever
  existed in this repo's git history — both were aspirational text inherited from the upstream repo PDDA
  was extracted from. Maintainer confirmed both conventions retired; prose reworded to drop the
  backticked-filename form the dead-reference check reads as a live cross-reference, and compliance
  findings explicitly reassigned to `CHANGELOG.md` rather than silently orphaned. Verified: governance
  dead-ref warns 4 → 0. Issue [#17](https://github.com/Hypercart-Dev-Tools/pdda/issues/17) (fixed;
  pending close). -> [PROJECT/3-COMPLETED/GH-17-RECAP-STALE-REFS.md](PROJECT/3-COMPLETED/GH-17-RECAP-STALE-REFS.md)
- **GH-18 — ROUTER.md missing glance/quad-concepts subcommand docs** (2026-07-08) - GH-12 added both
  subcommands to the `pdda.sh` dispatcher and to `pdda.sh help`, but never to `ROUTER.md`'s Command rails
  list, so `pdda-check-governance`'s subcommand-drift check errored on the canonical repo itself (AGENTS.md #5 lockstep).
  Fixed by adding both lines with blurbs lifted verbatim from `pdda.sh help`. Verified: subcommand-drift
  errors 2 → 0. Issue [#18](https://github.com/Hypercart-Dev-Tools/pdda/issues/18) (fixed; pending
  close). -> [PROJECT/3-COMPLETED/GH-18-ROUTER-SUBCOMMAND-DRIFT.md](PROJECT/3-COMPLETED/GH-18-ROUTER-SUBCOMMAND-DRIFT.md)
- **GH-15 — fresh installs self-inflict ~30 governance warns** (2026-07-08) - `PDDA-INSTALL.md` and
  `PROJECT/PDDA.md`, both shipped by the installer, dead-referenced files the installer deliberately
  omits (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `CLAUDE.md`, skill paths) plus 3 phantom
  env-var warns, muddying first-run observe-mode signal for new adopters. Fixed via an exemption
  manifest in `pdda-check-governance`, built from an actual fresh-install scan rather than the issue's
  illustrative list (added `CLAUDE.md` + a legacy path the list missed; deliberately excluded two
  lookalike warns — `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md` — that turned out to be a separate,
  pre-existing doc-accuracy drift in `PROJECT/PDDA.md`, flagged as a follow-up rather than exempted).
  Verified: 35→4 warns on a fresh target, negative control confirmed no over-suppression. Issue
  [#15](https://github.com/Hypercart-Dev-Tools/pdda/issues/15) (closed). ->
  [PROJECT/3-COMPLETED/GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md](PROJECT/3-COMPLETED/GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md)
- **Spike: XYZ harness -> Aider -> OpenRouter -> GLM 5.2** (2026-07-08) - tested whether the vendored
  `.xyz/relay-automation/aider-turn.sh` shim could drive GLM 5.2 (via OpenRouter) to autonomously execute
  GH-14 Phase 1. Pipeline wiring confirmed end-to-end (found + fixed 2 real integration bugs: Aider drops
  gitignored `--file` paths despite `--no-gitignore`; the lane-attempt-cap correctly required `--force`
  to re-fire). The model did not land the edit across 2 attempts and a real success-classification gap
  was found in the shim (it reports "committed" without verifying the target file actually changed). GH-14
  Phase 1 applied by hand instead. -> [PROJECT/3-COMPLETED/AIDER-GLM-XYZ-HARNESS-TEST-2026-07-08.md](PROJECT/3-COMPLETED/AIDER-GLM-XYZ-HARNESS-TEST-2026-07-08.md)
- **Defacto Project Memory Layer** (2026-07-06) - reframed PDDA as a de facto project memory layer via three coordinated conventions and no new deterministic surface: `ROUTER.md` startup now retrieves prior context from `3-COMPLETED/`/`CHANGELOG.md` when exploring or blocked; spikes are framed as **Memory Injection** and a `## Lessons Learned (For Future Agents)` section is required before completion; optional `context_tags` frontmatter + two warn-only LLM nudges (`related:` on medium-large plans, `decisions/` link on `risk: 4`/`5`). Governance clean; README "The project memory layer" section added. -> [PROJECT/3-COMPLETED/PROJECT-MEMORY-LAYER.md](PROJECT/3-COMPLETED/PROJECT-MEMORY-LAYER.md)
- **GH-7 — auto-detect git-pulse repo path for the registry projection** (2026-06-30) - the multi-device projection silently skipped on devices where git-pulse's sync repo isn't at the hardcoded default `~/.config/git-pulse/repo` (e.g. `~/git-pulse-sync` on Mac Studio); `publish_registry_projection()` now resolves it via `PDDA_GITPULSE_DIR` → git-pulse `config.sh` `sync_repo_dir` → candidate list, still best-effort/fail-open. 17/17 publish tests (new autodetect case) + real-world plain-install verification; lockstep `install.sh`/`PDDA-INSTALL.md`. Issue [#7](https://github.com/Hypercart-Dev-Tools/pdda/issues/7) (closed). -> [PROJECT/3-COMPLETED/GH-7-GITPULSE-PATH-AUTODETECT.md](PROJECT/3-COMPLETED/GH-7-GITPULSE-PATH-AUTODETECT.md)
- **Multi-device PDDA status via git-pulse piggyback** (2026-06-30) - `install.sh` now publishes a per-device, **path-normalized** registry projection (repo name + date + source commit + mode, no folder path) into a `pdda/` folder of git-pulse's sync repo on every install/upgrade; git-pulse's existing sync carries it across devices. Best-effort/fail-open, no new command or git logic. 10/10 publish test green; today's ledger backfilled. -> [PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md](PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md)

- **Issue↔doc sync check + two-tier doc-health hooks** (2026-06-29) - new warn-only `pdda.sh issue-doc-sync` flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state (both directions); `pdda.sh gh-refresh` writes the offline gh-state cache; two-tier PostToolUse (single-file lint) + Stop (consolidated full-scan) doc-health hooks. Deterministic, warn-only, fail-open; 31 tests; all phases shipped, committed + pushed. Issue [#5](https://github.com/Hypercart-Dev-Tools/pdda/issues/5) (closed). -> [PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md](PROJECT/3-COMPLETED/GH-5-ISSUE-DOC-SYNC.md)
- **PDDA-EOD skill — end-of-day wrap** (2026-06-29) - `/pdda-eod` runs hygiene checks, reconciles docs/ROADMAP/CHANGELOG, helps reach a clean/pushed tree, and closes 100%-done issues (user-verified); delegates deterministic work to `pdda.sh`, all propose-then-confirm. Shipped at `SKILLS/PDDA-EOD/SKILL.md`. Issue [#6](https://github.com/Hypercart-Dev-Tools/pdda/issues/6). -> [PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md](PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md)
- **Sync the PDDA runtime to other repos** (2026-06-27 → completed 2026-06-29) - `utils/pdda/pdda-sync.sh`: canonical → registered-targets, on-demand `push` (manual primary, launchd optional) over an auto-regenerated manifest shared with `install.sh`; content-hash state-stamp copy, delete-mirror with backup, manifest-poisoning guard. Realigned + Codex relay-approved (4 rounds), built in 5 phases, every QA gate green + end-to-end dogfood. -> [PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md](PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md)
- **Standalone baseline established** (2026-06-24) - repo-facing docs now describe `pdda` itself, placeholder scaffolding is normalized, and the install manifest matches the shipped scripts. -> [PROJECT/PDDA.md](PROJECT/PDDA.md) and [utils/pdda/PDDA-INSTALL.md](utils/pdda/PDDA-INSTALL.md)
- **`utils/` consolidated to 3 files** (2026-06-24) - the 7 per-check scripts + `pdda-run.sh` collapsed into one `pdda.sh` dispatcher (`pdda.sh run` / `pdda.sh <check>`); `pdda-lib.sh` and the opt-in `pdda-doc-ready.sh` stay separate. Breaking change to the install contract; old filenames removed. -> [utils/pdda/PDDA-INSTALL.md](utils/pdda/PDDA-INSTALL.md)

### Deferred

Archived to `PROJECT/4-MISC/` on 2026-07-08 — inactive, not completed. Each had tripped
`pdda.sh stale`; archiving records that honestly rather than promoting them to `3-COMPLETED`
(which would claim a completion none of them actually reached).

- **Root `install.sh` + operator onboarding** (2026-06-25, archived 2026-07-08) - installer that
  provisions a foreign repo to a clean zero state; README rewritten for onboarding. The installer
  itself ships and works; the doc stalled at "tracking issue pending `gh` re-auth" and went 10 days
  untouched. Revive it here if the tracking issue ever gets filed. ->
  [PROJECT/4-MISC/INSTALL-SCRIPT-AND-ONBOARDING.md](PROJECT/4-MISC/INSTALL-SCRIPT-AND-ONBOARDING.md)
- **Reconcile pdda-sync `list` vs `status` wording** (2026-06-30, archived 2026-07-08) - a
  just-installed-but-unpushed target read as `not-yet-pushed` in `list` while `status` reported it
  current; `list` is now content-aware (`current`/`out-of-sync` + `(unpushed)` marker). Iteration 1
  shipped and no iteration 2 was ever scoped. ->
  [PROJECT/4-MISC/SYNC-LIST-STATUS-RECONCILE.md](PROJECT/4-MISC/SYNC-LIST-STATUS-RECONCILE.md)
- **QUAD-GML52 — raw GLM 5.2 design pass for Quad Concepts** (archived 2026-07-08) - the unedited
  model output (concept + adversarial persona review + implementation plan) that seeded GH-12. Kept as
  a provenance artifact; GH-12's own doc owns the execution detail, and all 4 of its phases shipped. It
  was never an active working doc, only mis-filed as one. ->
  [PROJECT/4-MISC/QUAD-GML52.md](PROJECT/4-MISC/QUAD-GML52.md)

---

*Add new work here only when a real `PROJECT/**` doc exists to own the execution detail.*
