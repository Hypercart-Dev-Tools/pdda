---
title: Quad Concepts mode — an opt-in ≤4 pain→fix glance layer atop plan docs
status: Active — Phase 1 in progress (deterministic check + lever)
created: 2026-07-07
updated: 2026-07-07
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
| Synthesized the GLM 5.2 "Quad Concepts" pass with the original design; filed issue [#12](https://github.com/Hypercart-Dev-Tools/pdda/issues/12); promoted this plan doc to `2-WORKING`. Design locked (pain→fix content, 2-WORKING+1-INBOX+3-COMPLETED scope, orthogonal `.pdda-quad` lever, structure-only check + LLM nudge). | Build Phase 1: `check_quad_concepts()` + the `.pdda-quad`/`PDDA_QUAD` lever + `pdda_list_quad_docs()` + dispatch + conditional inclusion in `run`, with `test/pdda-quad-concepts.sh`. |

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

Document the convention where PDDA's contract lives and wire the installer: a `## Quad Concepts` clause
in `PROJECT/PDDA.md`, the seed template (`## Quad Concepts` right after `## Status`, with the
`quad_exempt` note), `install.sh` (seed a `.pdda-quad` off-by-default + usage/blurb text), README
section, CHANGELOG entry, and the install manifest. Lockstep `install.sh` ↔ `utils/PDDA-INSTALL.md`.

## Phase 3 — LLM readiness rubric

Warn-only additions to `pdda-doc-ready.sh` (only when the lever is on): flag vague concepts
(`backend`, `bug`) and concepts that appear disconnected from the doc's final `## Status` /
`## Lessons Learned`. Never blocks — honesty over perfection; the human owns closeout updates.

## Phase 4 — glance roll-up (stretch)

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
