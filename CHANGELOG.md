# CHANGELOG.md

## 2026-06-27

### Agent startup: imperative AGENTS.md trigger + `/pdda` re-orient skill

Closed the gap between the auto-loaded `AGENTS.md` and the `ROUTER.md` startup sequence, and added a
thin re-orientation lever for mid-session inflection points.

- **Imperative startup directive.** `AGENTS.md` (which agent harnesses auto-load) now *instructs* the
  agent to follow the `ROUTER.md` startup sequence on first action, rather than only pointing at it.
  This makes the read-order self-executing without the user typing "read ROUTER.md", and needs no new
  surface — the harness already loads the file.
- **`/pdda` skill (`.claude/skills/pdda/SKILL.md`).** A deliberately dumb read-and-report pass for the
  one case the auto-load can't cover: explicit re-orientation on task switch, resume, post-compact, or
  context drift. It walks `ROUTER.md`, names the next canonical file, and runs `pdda.sh run` for state.
  It re-specifies no contract — points at where each fact lives.
- **Ships via `--with-startup-docs`.** Bundled with `ROUTER.md`/`AGENTS.md` (it's only useful when
  those exist in the target), so no new installer flag. `install.sh`, `utils/PDDA-INSTALL.md`, and the
  `ROUTER.md` routing hints updated in lockstep.

Verification: `bash -n install.sh` clean; `./utils/pdda.sh run` green (pre-existing BLANK.md dogfood
findings only, non-blocking in observe); end-to-end `install.sh --with-startup-docs` into a temp repo
confirmed `ROUTER.md`, `AGENTS.md`, and `.claude/skills/pdda/SKILL.md` all land in the target.

## 2026-06-26

### Triage ratings for medium-large work (effort / complexity / risk / phases)

Added four frontmatter triage fields so automation can select *which* task to pursue without
re-reading every plan: `effort`, `complexity`, `risk` (integers 1–5) and `phases` (positive integer).
Required for medium-large tasks/projects; trivial docs are exempt.

- **No stored composite score.** The combined "easiness" signal is **derived at selection time**, not
  persisted — a frozen aggregate would drift from its components (violating Principle #4, one canonical
  place per fact) and bake in a weighting that couldn't be re-tuned without rewriting docs. PDDA.md
  documents the reference rule: `risk` is a hard safety **gate** (`risk <= 2` eligible; `>= 4` ⇒
  human), `effort + complexity` is the ease axis (they correlate, so summed as one size proxy), with
  `phases` as the tiebreak.
- **Split enforcement.** `pdda.sh frontmatter` now validates the rating *values* when present (1–5
  range; phases a positive int) — unambiguous, so blocking-capable. *Presence* on a medium-large doc is
  a judgment, so it's flagged by the warn-capped LLM layer (`pdda-doc-ready.sh`), never a regex.
- Supersedes the previously-proposed single `priority` scalar; added to the GH-issue-intake minimum
  frontmatter for medium-large captures so the queue can be triaged before promotion.

Verification: `./utils/pdda.sh run` green; new validator unit-checked against good/bad rating docs via
`PDDA_WORKING_DIR` (4 range errors on bad values, clean on valid 1–5).

## 2026-06-25

### Plan contract: TOC + discovery/spike write-back

Extended the active-doc contract in `PROJECT/PDDA.md` with two governance clauses, and wired both into
the LLM readiness rubric. No change to the deterministic checks or the install surface.

- **Table of contents** is now a required contract item for *multi-phase* plans (item 4): a
  `## Table of contents` listing each phase, so a cold agent sees the full phase span and jumps to the
  live one without scrolling. Added to the readiness rubric and the automation-ready checklist.
- **Discovery & spike phases** get a new dedicated contract section: a phase tagged discovery/spike
  must write its findings (what was investigated, what was found with `file:line` pointers, what it
  changes for later phases) **back into the originating plan doc** before its QA gate can pass. Grounded
  in Principle #1 (docs are runtime state) and #4 (one canonical place per fact) — a spike whose
  findings live only in chat is the exact drift PDDA exists to prevent.
- **Enforcement is advisory (LLM layer, warn-capped).** `pdda-doc-ready.sh` now flags a multi-phase
  plan with no TOC and a discovery/spike phase whose findings were not written back. "Did the agent
  actually capture what it learned" is a judgment a regex cannot make honestly, so it stays with the
  reviewer and never blocks a build — consistent with how QA-gate readiness is already enforced.

Verification: `./utils/pdda.sh run` green in this repo (deterministic checks unaffected; the LLM layer
self-skips when no `PDDA_LLM_BIN` is configured).

## 2026-06-25

### Root `install.sh` + operator onboarding

Added a repo-root `install.sh` that installs the PDDA surface into a *foreign* repo in a clean,
ready-to-use zero state, and rewrote `README.md` to lead with operator onboarding.

- `install.sh` is the executable form of `utils/PDDA-INSTALL.md`: it copies the canonical-4 runtime
  (`utils/pdda.sh`, `utils/pdda-lib.sh`, `utils/pdda-doc-ready.sh`, `PROJECT/PDDA.md`), creates the
  `PROJECT/**` lifecycle tree, and **synthesizes blank seed** `ROADMAP.md` / `CHANGELOG.md` /
  `PROJECT/PDDA-ACTIVITY.jsonl` / `.pdda-mode` — it never copies this repo's own ledger/history into a
  target. It `chmod`s the scripts and runs `pdda.sh run` as a post-install smoke test.
- Idempotent: runtime + contract are refreshed on re-run, but existing seeds and real `PROJECT/**`
  docs are kept unless `--force`. Flags: `--force`, `--with-startup-docs`, `--mode observe|light|full`.
  Refuses to target the pdda source repo itself.
- This repo stays a **live dogfood demo**: its own `ROADMAP.md` / `CHANGELOG.md` / `PROJECT/**` are
  not zeroed; only target repos start blank. This change was itself tracked via a `PROJECT/2-WORKING`
  doc + a ROADMAP pointer (the issue-first GitHub step is deferred until `gh` auth is restored).
- Lockstep doc updates: `utils/PDDA-INSTALL.md` (new "Fastest path: install.sh" section) and
  `ROUTER.md` (canonical-files list + routing hint).

Verification: `./install.sh <throwaway-target>` → target `pdda.sh run` exits 0 (fresh + idempotent
re-run + `--force`/`--with-startup-docs`/`--mode` exercised); `./utils/pdda.sh run` green in this repo.

## 2026-06-24

### BREAKING: consolidated `utils/` to 3 files

Collapsed the deterministic check surface from 10 shell files into a single dispatcher. The 7
per-check scripts and `pdda-run.sh` are gone; their logic now lives in `utils/pdda.sh` as
subcommands. `utils/pdda-lib.sh` (shared helpers) and `utils/pdda-doc-ready.sh` (the opt-in LLM
layer) stay separate, so the install set drops from 11 paths to 4.

- New entry point: `pdda.sh run` (aggregate) and `pdda.sh <check>` (e.g. `pdda.sh frontmatter`,
  `pdda.sh roadmap-coverage`). `pdda.sh help` lists every command.
- Each finding keeps its stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
  activity log, so downstream JSON consumers are unaffected.
- **Breaking for existing installs / cron:** the old `utils/pdda-check-*.sh`,
  `utils/pdda-stale-working-docs.sh`, and `utils/pdda-run.sh` paths were removed (clean break, no
  shims). Re-run `utils/PDDA-INSTALL.md` against target repos and repoint any cron/CI that called a
  per-check script to `pdda.sh <check>`.
- The bet: a single dispatcher is cheaper to install (4 paths, one `chmod`) and keeps the
  deterministic/LLM boundary intact; reversibility is **Costly** (versioned contract change, trivially
  revertible in git but target repos must re-install). Verified by diffing old vs new findings,
  summaries, and mode-gated exit codes against a fixture exercising every check — byte-identical.
- Updated `PROJECT/PDDA.md`, `utils/PDDA-INSTALL.md`, `ROUTER.md`, `README.md`, `AGENTS.md`, and
  `ROADMAP.md` in lockstep with the new surface.

Verification: `./utils/pdda.sh run`

### Standalone installer baseline reset

Reset the copied `xyz`-specific repo surface into a standalone PDDA installer baseline.

- Replaced the inherited `ROADMAP.md` and `ROUTER.md` with repo-local versions that describe `pdda` itself.
- Added the missing `AGENTS.md`, `README.md`, and `.pdda-mode` so the startup path is self-consistent.
- Updated `utils/PDDA-INSTALL.md` so the canonical install set and required target-repo files match the live PDDA suite.
- Normalized the scaffold placeholders to `blank.md` so baseline scaffolding is ignored by the checks as intended.

Verification: `./utils/pdda-run.sh` (the runner at the time; now `./utils/pdda.sh run`)
