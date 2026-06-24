# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = pointer ledger for this repo's own maintenance work
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `PROJECT/PDDA.md` = the canonical PDDA contract and automation rules
- `utils/PDDA-INSTALL.md` = the extraction/install manifest for target repos
- `utils/pdda-*.sh` + `utils/pdda-run.sh` = the shipped runnable install surface

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Read `README.md` for the repo's purpose and baseline usage. -> expect a short explanation of what is canonical here.
4. If the task is about the PDDA contract or enforcement model, read `PROJECT/PDDA.md`. -> expect the source of truth for lifecycle, roadmap, changelog, and enforcement rules.
5. If the task is about installation or extraction into another repo, read `utils/PDDA-INSTALL.md`. -> expect the canonical copy/create list and first-run verification path.
6. Read `ROADMAP.md` only for repo-local maintenance state. -> expect a pointer ledger, not a copied plan body from another repo.
7. Before reporting success on repo changes, run `utils/pdda-run.sh` or the relevant `utils/pdda-*.sh` check. -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
- Keep `PROJECT/PDDA.md`, `utils/PDDA-INSTALL.md`, and the shipped `utils/pdda-*.sh` surface in sync. Do not let the manifest lag the code.
- Do not copy `PROJECT/PDDA-ACTIVITY.jsonl` history into target repos; target repos start with a fresh activity log.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda-check-roadmap-coverage.sh`; governance lives in `PROJECT/PDDA.md` -> "ROADMAP.md contract".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda-check-roadmap-coverage.sh`; governance lives in `PROJECT/PDDA.md` -> "GitHub issue intake" + "ROADMAP.md contract".
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For baseline verification and document hygiene:

```bash
utils/pdda-run.sh
```

For targeted PDDA debugging:

```bash
utils/pdda-check-frontmatter.sh
utils/pdda-check-status-table.sh
utils/pdda-check-hardcoded-paths.sh
utils/pdda-check-roadmap.sh
utils/pdda-check-roadmap-coverage.sh
utils/pdda-check-changelog.sh
utils/pdda-stale-working-docs.sh
utils/pdda-doc-ready.sh   # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## Routing hints

- If the task is about extraction or first install into another repo, start in `utils/PDDA-INSTALL.md`.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about repo-local maintenance state, start in `ROADMAP.md`.
- If the task is about the changelog, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
