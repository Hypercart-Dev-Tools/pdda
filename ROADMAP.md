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
| GH-17 + GH-18 fixed on branch `fix/GH-17-GH-18` (PR open, not yet merged): `PROJECT/PDDA.md`'s stale RECAP.md/REAL-AGENT-OBSERVATIONS.md references genericized (turned out to be copy-paste leftovers from the origin repo, not this repo's own files), `ROUTER.md` now documents `glance`/`quad-concepts`. `pdda.sh governance` errors=0 warns=0 on the branch. | Merge the PR once reviewed. GH-14 Phase 1 (verified one-line fd fix) still queued to start. GH-10 Sentinel remains the other active build (Phase 2b executor). |
| **GH-23 shipped and closed (P1–P4, PR #32 → 5ef638a), closing the "a check that could not run reports success" family.** Targets no longer inherit the canonical router (#25 fixed alongside); `install.sh` validates every startup doc it writes; the dead-ref scan reads `.sh` including command-position paths; **GH-14 Phase 2 (BUG-001b)** landed with P3 — `run` can no longer report "all checks passed" over errors the mode gate merely stopped from blocking; and P4 made the on-ramp cheap (`/pdda`) then optionally enforceable. Doc moved to `3-COMPLETED`. Follow-ups **#33** (interpreter-wrapped `.sh` invocations) and **#34** (`find -name` glob → literal basename) landed 2026-07-11; governance suite 41 → 47. Earlier: GH-27 made the wrap loop fire, and GH-12/GH-15 wrapped and closed. | **Repair the `LTVera-Pandas` install** — it still carries the pre-P1 verbatim router; needs an explicit `install.sh --with-startup-docs --force` (`pdda-sync.sh push` cannot reach a target's `ROUTER.md`), backing up its 60KB `AGENTS.md` first (tracked as [BinoidCBD/LTVera-Pandas#49](https://github.com/BinoidCBD/LTVera-Pandas/issues/49)). **GH-10 Sentinel** is the other active build — Phase 3 replay/eval harness next. |
| **GH-35 shipped (2026-07-14): Release primitive — first-class GitHub Releases integration.** `PROJECT/releases/` lifecycle bucket; `pdda.sh release-readiness` (new deterministic check); `pdda.sh gh-release-sync` (parallel to `gh-refresh`); `roadmap-coverage` extended to cover release docs; `/release` skill; `install.sh` + `PDDA-INSTALL.md` + `.gitignore` updated. Four-tier chain: task/issue → project → marathon → release. Additive, non-breaking. Earlier: **GH-23 shipped and closed (P1–P4, PR #32 → 5ef638a)**; follow-ups **#33 + #34** landed 2026-07-11; governance suite 41 → 47. | **Repair the `LTVera-Pandas` install** — it still carries the pre-P1 verbatim router; needs an explicit `install.sh --with-startup-docs --force` (`pdda-sync.sh push` cannot reach a target's `ROUTER.md`), backing up its 60KB `AGENTS.md` first (tracked as [BinoidCBD/LTVera-Pandas#49](https://github.com/BinoidCBD/LTVera-Pandas/issues/49)). **GH-10 Sentinel** is the other active build — Phase 3 replay/eval harness next. |

## Ledger

### Queue / parked intake
- **GH-41 — Marathon triage 2026-07-17 follow-ups** (2026-07-18) - master tracking issue for the
  held candidate pool: 0 of 8 open items are marathon-ready, all failing `swarm-preflight` exit 3 on a
  missing `## Swarm Preflight Contract` block. Covers `AGENTS-BUILDER-SKILL.md`'s orphaned state,
  contract authoring for #9/#10/#14 and #13/#36/#40, scope calls on #38/#39, and the held 2026-07-07
  marathon-leftover sweep. Triage items 1-2 landed in 0fae994; the #11 Myriad decision resolved
  2026-07-18 (moved to giant-brains). Issue
  [#41](https://github.com/Hypercart-Dev-Tools/pdda/issues/41). ->
  [PROJECT/1-INBOX/MARATHON-TRIAGE-2026-07-17.md](PROJECT/1-INBOX/MARATHON-TRIAGE-2026-07-17.md)
- **Marathon Plan (2026-07-07)** (2026-07-07) - the canonical XYZ-format marathon plan doc
  (hand-authored per `.xyz/README.md`'s Option B — the ROADMAP auto-generator, Option A, currently
  reports 0 active lanes) for the two build phases below, distinct from the machine-executable
  `marathon/MARATHON-2026-07-07.yaml`. ->
  [PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md)
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
- **GH-10 — Sentinel: repo-driven doc-governance automation** (2026-07-04) - the act-on-it layer for
  PDDA: on merge to `main`, build context from the diff, ask the model (via `PDDA_LLM_BIN`) whether
  governance docs should change, apply edits inside a git worktree on an allowlisted path set, gate on
  `pdda.sh run`, and finalize as dry-run → PR → selective local-commit under a deterministic policy
  gate + per-category trust score. One pipeline; only the finalizer graduates. 7 phases (replanned
  after a GLM 5.2 review). **Phase 1 shipped** (dry-run orchestrator `sentinel/run.sh`, 26/26 tests);
  Phase 2 (worktree apply) next. Issue [#10](https://github.com/Hypercart-Dev-Tools/pdda/issues/10).
  -> [PROJECT/2-WORKING/GH-10-SENTINEL.md](PROJECT/2-WORKING/GH-10-SENTINEL.md)

### Completed

- **GH-28 — Audit & fix registry-to-git-pulse-sync projection drift** (2026-07-09 → closed) - Phase 0
  found `install.sh`'s projection write is actually correct; the real gap was that it never warned when
  the git-pulse checkout it targets is dirty/behind and never reaching origin. Phase 1 added
  `warn_stale_projection_destination()` + 4 test cases (21/21 passing); Phase 2 documented it in
  `PDDA-INSTALL.md` and `install.sh --help`. The residual operator git-pulse-checkout item is an
  explicit non-goal of this doc, not owed work here. Issue
  [#28](https://github.com/Hypercart-Dev-Tools/pdda/issues/28). ->
  [PROJECT/3-COMPLETED/GH-28-REGISTRY-PROJECTION-DRIFT.md](PROJECT/3-COMPLETED/GH-28-REGISTRY-PROJECTION-DRIFT.md)
- **GH-21 — SKILLS/PDDA-hook opt-in SessionStart doc-governance reminder** (2026-07-08 → closed) - new
  bundled skill that installs a `SessionStart` hook re-anchoring `ROUTER.md`/`AGENTS.md`/`PROJECT/PDDA.md`
  at every context boundary (startup/resume/clear/compact), auto-scoped via `PROJECT/PDDA.md` detection,
  global- or repo-local-scoped, propose-then-confirm, never touches a repo's committed `settings.json`.
  Implemented same-session as capture; shipped as `SKILLS/PDDA-hook/`. Issue
  [#21](https://github.com/Hypercart-Dev-Tools/pdda/issues/21). ->
  [PROJECT/3-COMPLETED/GH-21-PDDA-HOOK-SKILL.md](PROJECT/3-COMPLETED/GH-21-PDDA-HOOK-SKILL.md)
- **GH-17 — PROJECT/PDDA.md dead-references RECAP.md/REAL-AGENT-OBSERVATIONS.md** (2026-07-08) - two
  claims in `PROJECT/PDDA.md`'s CHANGELOG section didn't match reality. Root cause found: both filenames
  are real artifacts in the sibling `xyz-3-agents-swarm` repo this standalone repo's docs were extracted
  from — Trinity-spike-specific files, never real here. Present since this repo's first commit
  (confirmed via `git log -S`), a copy-paste leftover rather than an intentional claim. Fixed by
  genericizing the three affected passages to describe the concept (a superseded narrative log; an
  optional local compliance-observations doc) without naming specific filenames. `pdda.sh governance`
  dead-reference warns for this doc: 4→0. Shipped with GH-18 on branch `fix/GH-17-GH-18` (PR open, not
  yet merged). Issue [#17](https://github.com/Hypercart-Dev-Tools/pdda/issues/17). ->
  [PROJECT/3-COMPLETED/GH-17-RECAP-STALE-REFS.md](PROJECT/3-COMPLETED/GH-17-RECAP-STALE-REFS.md)
- **GH-18 — ROUTER.md missing glance/quad-concepts subcommand docs** (2026-07-08) - `pdda-check-governance`'s
  subcommand-drift check errored on HQ (`glance`, `quad-concepts` from GH-12 never got added to
  `ROUTER.md`'s Command rails list, though `README.md` already had them). Fixed: both added to
  `ROUTER.md` in `pdda.sh help`'s own subcommand order. `pdda.sh governance` errors: 2→0. Shipped with
  GH-17 on branch `fix/GH-17-GH-18` (PR open, not yet merged). Issue
  [#18](https://github.com/Hypercart-Dev-Tools/pdda/issues/18). ->
  [PROJECT/3-COMPLETED/GH-18-ROUTER-SUBCOMMAND-DRIFT.md](PROJECT/3-COMPLETED/GH-18-ROUTER-SUBCOMMAND-DRIFT.md)
- **GH-23 — agent on-ramp is wrong, expensive, and unenforced** (2026-07-09 → closed 2026-07-10) - four
  phases, all shipped in PR #32. `--with-startup-docs` advertised an "adapted" `ROUTER.md` while
  `copy_runtime` copied it verbatim, so every target inherited the canonical router — naming `install.sh`
  and `pdda-sync.sh`, neither of which exists in a target, with no check able to see it. **P1** routes each
  startup doc by owner (fixing #25); **P2** makes `install.sh` validate its own output; **P3** widens the
  dead-ref scan to command-position `.sh` and carries **GH-14 Phase 2 / BUG-001b** (`run` no longer reports
  "all checks passed" over gated errors); **P4** makes reminder directive 1 cheap (`/pdda`) then verifiable
  via an opt-in default-off `PreToolUse` gate that fails open when it cannot prove the router went unread.
  Codex consult caught a fail-closed path pre-merge; 273 assertions green; follow-ups #33/#34 filed (resolved 2026-07-11). Issue
  [#23](https://github.com/Hypercart-Dev-Tools/pdda/issues/23) (closed). ->
  [PROJECT/3-COMPLETED/GH-23-AGENT-ONRAMP.md](PROJECT/3-COMPLETED/GH-23-AGENT-ONRAMP.md)
- **GH-27 — issue-doc-sync stopped watching a doc at the moment it completed** (2026-07-09) - the loop
  was never missing: it reported `warns=0` over two live leaks while the `Stop` hook printed "all clear",
  because it scanned `2-WORKING` only and the gh-state cache was never written. Now scans both buckets,
  warns when it *cannot* evaluate, persists the cache on every live lookup, and points the operator at
  `/pdda-eod` — retargeted from the clock to completion. Warn-only, recommend-never-act. Suite 14 → 33.
  Wrapped #12 and #15. Issue [#27](https://github.com/Hypercart-Dev-Tools/pdda/issues/27) (closed). ->
  [PROJECT/3-COMPLETED/GH-27-ISSUE-DOC-RECONCILE.md](PROJECT/3-COMPLETED/GH-27-ISSUE-DOC-RECONCILE.md)
- **GH-12 — Quad Concepts mode** (2026-07-07 → wrapped 2026-07-09) - opt-in glance layer: a `.pdda-quad`
  lever (off by default), a structure-only check, a warn-only LLM rubric, a `pdda.sh glance` roll-up. All
  4 phases shipped; 42/42 + 6/6 re-verified at wrap. Sat done-but-open for two days — the live evidence
  for GH-27's leak 2. Issue [#12](https://github.com/Hypercart-Dev-Tools/pdda/issues/12) (closed). ->
  [PROJECT/3-COMPLETED/GH-12-QUAD-CONCEPTS-MODE.md](PROJECT/3-COMPLETED/GH-12-QUAD-CONCEPTS-MODE.md)
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
  Verified: 35→4 warns on a fresh target. Re-verified at wrap 2026-07-09: a fresh install now reports
  **1** warn (GH-23 P1 removed the target router's dead refs). This entry falsely read "(closed)" for a
  day — the drift GH-27's `3-COMPLETED` pass now catches. Issue
  [#15](https://github.com/Hypercart-Dev-Tools/pdda/issues/15) (closed 2026-07-09). ->
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
