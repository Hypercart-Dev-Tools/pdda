# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = the north star; what the repo's goals and design tradeoffs answer to
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = pointer ledger for this repo's own maintenance work
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `PROJECT/PDDA.md` = the canonical PDDA contract and automation rules
- `utils/PDDA-INSTALL.md` = the extraction/install manifest for target repos
- `install.sh` = the executable installer (automates `utils/PDDA-INSTALL.md`; keep the two in lockstep)
- `utils/pdda.sh` = the unified runnable surface (dispatcher + every deterministic check + `run`)
- `utils/pdda-doc-ready.sh` = the opt-in LLM readiness review; `utils/pdda-lib.sh` = shared helpers

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `GUIDING-PRINCIPLES.md` for the repo's north star. -> expect the goals and tradeoff lens that every design choice answers to.
3. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
4. Read `README.md` for the repo's purpose and baseline usage. -> expect a short explanation of what is canonical here.
5. If the task is about the PDDA contract or enforcement model, read `PROJECT/PDDA.md`. -> expect the source of truth for lifecycle, roadmap, changelog, and enforcement rules.
6. If the task is about installation or extraction into another repo, read `utils/PDDA-INSTALL.md`. -> expect the canonical copy/create list and first-run verification path.
7. Read `ROADMAP.md` only for repo-local maintenance state. -> expect a pointer ledger, not a copied plan body from another repo.
8. Before reporting success on repo changes, run `utils/pdda.sh run` or the relevant single check (`utils/pdda.sh <check>`). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
- Keep `PROJECT/PDDA.md`, `utils/PDDA-INSTALL.md`, and the shipped `utils/pdda-*.sh` surface in sync. Do not let the manifest lag the code.
- Do not copy `PROJECT/PDDA-ACTIVITY.jsonl` history into target repos; target repos start with a fresh activity log.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` -> "ROADMAP.md contract".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` -> "GitHub issue intake" + "ROADMAP.md contract".
- The long-term canonical deterministic surface is `utils/pdda.sh`; do not add wrapper commands unless a real external integration forces them.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For baseline verification and document hygiene:

```bash
utils/pdda.sh run
```

For targeted PDDA debugging, run a single check by name:

```bash
utils/pdda.sh frontmatter
utils/pdda.sh status-table
utils/pdda.sh hardcoded-paths
utils/pdda.sh roadmap
utils/pdda.sh roadmap-coverage
utils/pdda.sh changelog
utils/pdda.sh stale
utils/pdda.sh doc-ready   # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
utils/pdda.sh help        # list every command
```

## Routing hints

- If the task is about installing PDDA into another repo, run `install.sh <target>`; for the
  underlying spec or a by-hand/adapted install, start in `utils/PDDA-INSTALL.md`.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about repo-local maintenance state, start in `ROADMAP.md`.
- If the task is about the changelog, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- To re-run this startup sequence mid-session (task switch, resume, post-compact, context drift), invoke the `/pdda` skill (`.claude/skills/pdda/SKILL.md`) instead of re-reading by hand.
