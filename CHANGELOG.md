# CHANGELOG.md

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
