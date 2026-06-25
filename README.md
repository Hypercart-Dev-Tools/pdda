# PDDA — Project-Driven Doc Automation

PDDA keeps a repo's project plans, bug-fix docs, and roadmap honest enough that a human *or an agent*
can pick up work with minimal drift. Deterministic shell checks enforce the parts that should never
need judgment (frontmatter, an exact status table, no hardcoded paths, a pointer-only roadmap); an
opt-in LLM pass flags the fuzzier readiness gaps. It starts **non-blocking** and you graduate it onto
the rails deliberately.

This is the standalone **source-of-truth installer repo**. The repo also dogfoods itself — its own
`ROADMAP.md`, `CHANGELOG.md`, and `PROJECT/**` docs are live PDDA artifacts, so it doubles as a
working demo.

---

## Install into your repo

PDDA installs *into* your existing project repo — you don't build your app in here.

```bash
# 1. clone this repo
git clone https://github.com/Hypercart-Dev-Tools/pdda.git
cd pdda

# 2. install into your project (zero state, ready to use)
./install.sh /path/to/your-repo
```

That copies the runtime + contract, creates the `PROJECT/**` lifecycle tree, drops blank seed
`ROADMAP.md` / `CHANGELOG.md` / activity-log / `.pdda-mode` files (it never copies this repo's own
content), makes the scripts executable, and runs `pdda.sh run` so you see it working immediately.

Installer options:

```text
--force                overwrite existing seed files (your real PROJECT/** docs are never touched)
--with-startup-docs    also install adapted ROUTER.md + AGENTS.md (agent read-order scaffold)
--mode observe|light|full   initial enforcement mode (default: observe)
-h, --help
```

Re-running is safe: runtime scripts and the contract are refreshed, but existing seeds and your real
docs are kept unless you pass `--force`.

---

## Day-to-day use

After install, everything runs through one dispatcher:

```bash
./utils/pdda.sh run                # all deterministic checks, then the LLM readiness review
./utils/pdda.sh frontmatter        # one check on its own
./utils/pdda.sh roadmap-coverage
./utils/pdda.sh help               # list every command
```

The workflow PDDA expects:

1. New ideas land in `PROJECT/1-INBOX`. Substantive work opens a GitHub issue first and is captured
   as a `GH-<n>-*.md` doc (see the issue-first SOP in `PROJECT/PDDA.md`).
2. Active work lives in `PROJECT/2-WORKING` — each doc needs YAML frontmatter and a near-top
   `## Status` table with the exact columns `What was just completed | What's next`.
3. `ROADMAP.md` stays a one-line **pointer ledger** for every active/queued doc — detail lives in the
   doc, not the roadmap.
4. Finished docs move to `PROJECT/3-COMPLETED`; stale/abandoned ones to `PROJECT/4-MISC` (flagged,
   never auto-moved).
5. Record each substantive iteration in `CHANGELOG.md`.

## Enforcement modes (the adoption ramp)

| Mode | When | Behavior |
|---|---|---|
| `observe` | just installed | reports findings, never blocks (default) |
| `light` | transitioning | reports everything incl. stale flags, still never blocks |
| `full` | on rails | `error` findings block with a non-zero exit |

Set it in `.pdda-mode` (or the `PDDA_MODE` env var). No mode ever mutates your tree.

Wire `./utils/pdda.sh run` into a pre-commit hook, CI, or an hourly cron once you're ready.

---

## Maintaining this repo (contributors)

This repo's job is to keep the PDDA contract and the shipped surface in lockstep:

- `PROJECT/PDDA.md` — the document contract and enforcement model (the source of truth)
- `utils/pdda.sh` — unified entry point: dispatcher for every deterministic check + `pdda.sh run`
  (shared helpers in `utils/pdda-lib.sh`)
- `utils/pdda-doc-ready.sh` — the opt-in, model-dependent LLM readiness review (a separate layer)
- `install.sh` — the executable installer (keep in lockstep with `utils/PDDA-INSTALL.md`)
- `utils/PDDA-INSTALL.md` — the extraction/install manifest for target repos

Read `ROUTER.md` first for the startup order, then `AGENTS.md` for the operating principles. Verify
any change with `./utils/pdda.sh run` before reporting it done.
