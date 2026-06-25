# AGENTS.md

See `ROUTER.md` for repo startup order and canonical files.
See `GUIDING-PRINCIPLES.md` for the repo's north star — the goals and tradeoff lens these rules serve.

## Operating principles

These apply to every response, plan, and change in this repo.

### 1. Lead with the call

The first sentence says what changed or what the verdict is. Supporting detail comes after.

### 2. State the bet before acting

Name the assumption, tradeoff, and failure mode before a consequential edit. If the claim cannot be wrong, it is probably too vague.

### 3. Use one reversibility scale

Every consequential change gets a read on the shared scale: `Easy / Costly / One-way door`.

### 4. Verify instead of implying

Do not report a win you did not verify. In this repo, `utils/pdda.sh run` is the main rail unless a narrower single check (`utils/pdda.sh <check>`) is more appropriate.

### 5. Keep the installer surface in lockstep

If a PDDA script is added, removed, or behaviorally changed, update the matching contract docs in the same change:

- `PROJECT/PDDA.md`
- `utils/PDDA-INSTALL.md`
- any repo-facing startup docs that describe the shipped surface

### 6. Keep this repo about PDDA

This is the standalone PDDA source-of-truth repo. Favor changes to the document contract, install manifest, and shipped shell checks. Do not pull in unrelated runtime or product docs from other repos.

### 7. Record substantive iterations

Update `CHANGELOG.md` at the end of a substantive iteration. `PROJECT/PDDA.md` owns the contract for what belongs there.

## Working in this repository

- The canonical PDDA contract lives in `PROJECT/PDDA.md`.
- The runnable install surface lives in `utils/pdda.sh` (checks + runner), `utils/pdda-doc-ready.sh` (LLM layer), and `utils/pdda-lib.sh` (shared helpers).
- The extraction contract lives in `utils/PDDA-INSTALL.md`.
- `ROADMAP.md` is this repo's pointer ledger, not a second plan body.
- `PROJECT/PDDA-ACTIVITY.jsonl` is runtime output, not install history to copy into target repos.
