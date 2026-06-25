# CHANGELOG.md

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
