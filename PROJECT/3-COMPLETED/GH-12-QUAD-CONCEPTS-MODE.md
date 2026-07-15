---
title: Quad Concepts mode — an opt-in ≤4 pain→fix glance layer atop plan docs
status: Completed — all 4 phases shipped + consult-passed; 42/42 + 6/6 re-verified 2026-07-09; issue #12 closed
created: 2026-07-07
updated: 2026-07-09
owner: noel
gh_issue: 12
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/12
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 4
goal: >
  Add an opt-in "Quad Concepts" convention to PDDA: tracked plan docs carry a `## Quad Concepts` body
  section of 1–4 pain→fix bullets right after `## Status`, so a human or cold-start agent gets a
  5-second orientation and an operator can see at a glance whether a new plan addresses the real pain
  points. Enabled by an orthogonal opt-in lever (off by default), enforced by a structure-only
  deterministic check plus a warn-only LLM quality rubric. Synthesizes a GLM 5.2 design pass with the
  original design.
---

# Quad Concepts mode

The `## Status` table says *where the work is*; it never says *what the work is*. A cold-start agent or
a human opening a dense plan doc gets no fast orientation, and an operator writing a new plan can't see
whether its **main pain points are actually being addressed**. Quad Concepts is an opt-in glance layer
that closes that gap without adding search machinery or forcing hard enforcement.

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1–4 built.** P1: check + `.pdda-quad`/`PDDA_QUAD` lever + `run` inclusion, consult-hardened. P2: `PROJECT/PDDA.md` clause + `install.sh --quad` + README/CHANGELOG (committed + pushed). P3: warn-only Quad Concepts quality rubric appended to `pdda-doc-ready.sh` when the lever is on (`test/pdda-doc-ready-quad.sh` 3/3). P4: `pdda.sh glance` roll-up (title + Quad Concepts across 2-WORKING) via a shared `pdda_quad_section` parser the check now reuses. `test/pdda-quad-concepts.sh` 38/38. **Final Codex+agy consult over P3+P4: both ship-ready, no blockers** — applied the accepted polish (glance strips YAML title quotes; +glance metachar/empty-dir tests; +doc-ready error→warn clamp test) → 42/42 + 6/6. | Human review, then `git mv` this doc to `PROJECT/3-COMPLETED/`. |

## Quad Concepts
- Dense plan docs give no 5-second orientation → a `## Quad Concepts` section (1–4 bullets) right after `## Status`
- Operators can't tell if a new plan covers the real pains → each bullet is `pain → fix`, so coverage is glanceable
- A new hard requirement risks bureaucratic friction → opt-in lever (off by default) + `quad_exempt` escape hatch + "up to 4" (one bullet is fine)
- A check can't judge whether concepts are *good* → deterministic check does structure only; a warn-only LLM rubric nudges quality/staleness

## Table of contents

1. [Design (locked)](#design-locked)
2. [Phase 1 — deterministic check + lever](#phase-1--deterministic-check--lever)
3. [Phase 2 — contract + surfaces](#phase-2--contract--surfaces)
4. [Phase 3 — LLM readiness rubric](#phase-3--llm-readiness-rubric)
5. [Phase 4 — glance roll-up (stretch)](#phase-4--glance-roll-up-stretch)
6. [Reconciliation with GLM 5.2](#reconciliation-with-glm-52)
7. [Adversarial review (GLM personas, preserved)](#adversarial-review-glm-personas-preserved)
8. [Deferred (parked, not in scope)](#deferred-parked-not-in-scope)
9. [Lessons Learned (For Future Agents)](#lessons-learned-for-future-agents)

## Design (locked)

- **Content — pain → fix.** Each bullet reads `<pain the doc addresses> → <how it's addressed>`, 1–4 of
  them. The deterministic check enforces **structure** (section present, 1–4 bullets, clean
  termination); the pain→fix richness and quality are guided by the seed template + a warn-only LLM
  rubric, **not** brittle regex. (Enforcing the `→` deterministically was considered and rejected — it
  reintroduces exactly the rigid-parser failure mode the adversarial review flags.)
- **Scope — plan + issue + completed docs.** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and
  `PROJECT/3-COMPLETED`. Skips `PROJECT/4-MISC`. `3-COMPLETED` is included per the project-memory-layer
  reframing (completed docs keep a glanceable summary for cold-start recall) — and it's nearly free,
  since the section travels with the doc when it's archived. Per-doc opt-out: `quad_exempt: true`
  (mirrors `roadmap_exempt`).
- **Enablement — orthogonal opt-in lever.** A `.pdda-quad` file (or `PDDA_QUAD=1`), enabled "like the
  enforced mode" but **orthogonal** to `observe/light/full`: the lever decides whether the check joins
  the `run` suite; the existing mode still decides report-only vs blocking. Standalone
  `pdda.sh quad-concepts` always runs (so it's testable regardless of the lever).
- **Two-layer enforcement.** Deterministic `pdda.sh quad-concepts` (presence + 1–4 bullets) + a
  warn-only rubric in `pdda-doc-ready.sh` (vague concepts; concepts drifted from the final status /
  Lessons Learned).
- **Distinct from `context_tags`.** Those are for search/retrieval; Quad Concepts are for human
  cognitive-load reduction at glance-time. Different audiences; they coexist.

## Phase 1 — deterministic check + lever

> **✅ Shipped (consult-hardened).** `test/pdda-quad-concepts.sh` 34/34. Parser hardened after a Codex+agy
> consult: skips fenced code, normalizes CRLF, stops on the next h1/h2 (not h3) or a blank line after a
> bullet, counts only top-level non-empty bullets, reads only the first section.

- `pdda_list_quad_docs()` in `pdda-lib.sh`: 2-WORKING + 1-INBOX(`GH-*`) + 3-COMPLETED, honoring
  `PDDA_ONLY_FILE` (single-file lint path), excluding `blank.md`.
- `quad_is_enabled()` (env `PDDA_QUAD` → first non-comment line of `.pdda-quad` → default off), mirroring
  the `.sentinel-mode` resolver.
- `check_quad_concepts()` in `pdda.sh`: for each scoped doc, skip if `quad_exempt: true`; parse the
  **first** `## Quad Concepts` section and count its **top-level, non-empty** `-`/`*` bullets — from the
  header until the next h1/h2 heading or the first blank line **after** a bullet (blank lines / HTML
  comments before the first bullet are tolerated). Fenced code blocks are skipped (a doc may show an
  example section); indented/nested and empty bullets don't count; CRLF is normalized; duplicate sections
  don't sum. **Error** if the section is missing, has 0 bullets, or has >4. Placement is **conventionally**
  right after `## Status` (the Phase-2 seed template puts it there), but the check enforces presence +
  shape, not exact adjacency — a ToC may legitimately sit between them.
- Dispatch: `pdda.sh quad-concepts` runs it standalone; `cmd_run` includes it in the suite **only when
  the lever is enabled** (keeps a default `run` output unchanged when off).
- `test/pdda-quad-concepts.sh`: valid 1–4 sections pass; missing/empty/>4 error; `quad_exempt` skips;
  scope covers 3-COMPLETED and 1-INBOX, excludes 4-MISC; `run` excludes the check when the lever is off
  and includes it when on.

**QA gate:** the standalone check passes a well-formed doc and errors on missing/0/>4; `quad_exempt`
skips; the lever gates inclusion in `run`; `test/pdda-quad-concepts.sh` green; `pdda.sh run` (lever off)
output and exit code unchanged. Shippable alone.

## Phase 2 — contract + surfaces

> **✅ Shipped.** Contract clause + `pdda.sh quad-concepts` description in `PROJECT/PDDA.md`; the
> `## Quad Concepts` md example (right after `## Status`) documents the seed shape; `install.sh` gains
> `--quad` and seeds a `.pdda-quad` (off by default, verified by a real `--quad` install smoke test);
> README "Quad Concepts" subsection + `--quad` option; CHANGELOG 2026-07-07 entry. No manifest change —
> `.pdda-quad` is a synthesized seed (like `.pdda-mode`), not part of `pdda-sync-manifest.conf`.

Documented the convention where PDDA's contract lives and wired the installer: a `## Quad Concepts` clause
in `PROJECT/PDDA.md`, the `## Quad Concepts` example (right after `## Status`, with the `quad_exempt`
note), `install.sh` (`--quad` flag + a `.pdda-quad` off-by-default seed + usage/blurb), README section,
and CHANGELOG entry.

## Phase 3 — LLM readiness rubric

> **✅ Shipped.** A `QUAD_RUBRIC_APPENDIX` is appended to the working-doc readiness review **only when the
> lever is on** (one model call, not two) — it critiques existing Quad Concepts bullets (vague/generic,
> not real `pain → fix`, or disconnected from `## Status` / `## Lessons Learned`) and never demands a
> missing section. Warn/info only. `test/pdda-doc-ready-quad.sh` (3/3) proves the gating via a fake model.

Warn-only additions to `pdda-doc-ready.sh` (only when the lever is on): flag vague concepts
(`backend`, `bug`) and concepts that appear disconnected from the doc's final `## Status` /
`## Lessons Learned`. Never blocks — honesty over perfection; the human owns closeout updates.

## Phase 4 — glance roll-up (stretch)

> **✅ Shipped.** `pdda.sh glance` prints `title + Quad Concepts` for every `PROJECT/2-WORKING` doc (a
> read-only, non-lever-gated report). To avoid a second copy of the parser, the section logic was
> factored into a shared `pdda_quad_section` helper in `pdda-lib.sh` that BOTH `pdda.sh quad-concepts`
> and `glance` use — one parser, no drift. Covered by `test/pdda-quad-concepts.sh` S21 (38/38 total).

`pdda.sh glance`: print `title + Quad Concepts` across active docs, so the whole portfolio's pain
coverage is visible on one screen. A markdown scrape (the body-section placement makes this less clean
than frontmatter would have) — nice-to-have, not core.

## Reconciliation with GLM 5.2

Adopted from GLM: the **name** ("Quad Concepts"), the **fixed placement** after `## Status`, the
**adversarial-persona review**, the **robust scoped parsing**, the **`quad_exempt` escape hatch**, and
**3-COMPLETED** in scope. **Diverged** on two points, deliberately:

1. **Enablement.** GLM made it a `.pdda-mode: quad-concepts` value, which forces `full`-style blocking.
   That blocks trialing the convention report-only and couples two orthogonal axes. Kept the original
   orthogonal lever so a team can run it in `observe` first.
2. **Content strictness.** GLM's check is bullets-only; the original wanted pain→fix. Reconciled: the
   deterministic check stays **structure-only** (per GLM's rigid-agent mitigation), and pain→fix is
   carried by the template + LLM nudge rather than a brittle `→` regex.

## Adversarial review (GLM personas, preserved)

- **Trivial-fix dev:** "up to 4" allows a single bullet; `quad_exempt: true` for administrative docs.
- **Rigid agent:** deterministic error on a malformed section — but structure-only and lenient on the
  `-`/`*` bullet char, to avoid bureaucratic brittleness.
- **Context drift:** the deterministic check only ensures existence/format; the LLM layer *warns* (never
  blocks) on stale concepts at closeout.
- **Architect:** distinct from `context_tags` (search vs glance); they coexist.

## Deferred (parked, not in scope)

From the P3+P4 consult, deliberately **not** done here (parked in the myriad backlog):
- Wrap the doc body in delimiters in `pdda-doc-ready.sh` to reduce prompt-injection — a **pre-existing**,
  general doc-ready hardening shared by the base rubric ("not newly worse"), not Quad-specific.
- A latent trailing-slash (`$TMPDIR`) portability nit in `test/pdda-publish-projection.sh` — it passes
  17/17 in the real repo; only the consult's throwaway-worktree env tripped it.

Rejected outright: making `pdda.sh glance` honor `PDDA_FORMAT=json` — glance is a human report, not a
findings stream, and isn't part of `pdda.sh run`.

## Lessons Learned (For Future Agents)

- **The lever is orthogonal to the mode — on purpose.** GLM's original design folded Quad Concepts into
  `.pdda-mode` as a value, which would force `full`-style blocking. Keeping `.pdda-quad` separate lets a
  team trial the convention in `observe` first. If you add another opt-in check, prefer a lever over a
  new mode value.
- **Structure-only checks + LLM-nudged quality is the PDDA pattern.** The deterministic check never tries
  to judge whether bullets are *good* `pain → fix` concepts (that's a warn-only rubric). Enforcing the
  `→` with a regex was tried and rejected — it reintroduces the rigid-parser brittleness the adversarial
  review flags.
- **Build-then-cross-model-review earns its keep.** The Phase-1 consult found three real defects the 33
  green tests hid (fenced code, CRLF, blank-line termination). Green tests ≠ correct; a skeptical second
  model reading the code caught what the happy-path tests didn't.
- **Consult findings can be environment artifacts.** Verify a flagged test failure against the real repo
  before acting — the P3+P4 consult's "macOS test failure" didn't reproduce (17/17 locally).
- **One parser, not two.** `glance` and the check share `pdda_quad_section` in `pdda-lib.sh`; a second
  copy of the boundary logic would drift. Factor shared scanning into the lib.
