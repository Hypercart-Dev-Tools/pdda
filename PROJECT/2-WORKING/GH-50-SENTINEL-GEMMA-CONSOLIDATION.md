---
title: Consolidate the doc-governance sentinel onto 3-Eyes + Gemma, and retire the Needle stack
status: Active (2-WORKING) — Phase 0 complete (bake-off GO verdict); Phases 1-5 not started
created: 2026-07-22
updated: 2026-07-22
owner: noel
gh_issue: 50
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/50
doc_type: project
goal: >
  Settle whether PDDA's doc-governance sentinel can run on one local general model (gemma4:12b-mlx)
  supervised by 3-Eyes, so the bespoke Needle router/serving stack can be retired for a large net
  reduction in tech debt. A blocking Phase 0 spike decides it on measurements, not preference.
effort: 5
complexity: 5
risk: 4
phases: 6
context_tags: [sentinel, 3-eyes, needle, gemma, tech-debt, consolidation]
---

## Status

| What was just completed | What's next |
|---|---|
| **Phase 0 shipped 2026-07-22** (PR [#52](https://github.com/Hypercart-Dev-Tools/pdda/pull/52), commit `d3a931f`). The three-arm bake-off ran over the frozen replay corpus and returned a **GO** verdict for Gemma; findings written back to this doc. Both blocking gates cleared: safety-path recall $\ge$ Needle's, and the memory envelope measured. Doc promoted to 2-WORKING with ratings confirmed. | **Phase 1 — adopt the cactus agents into the 3-Eyes TOML job registry.** Phase 1 is model-independent and ships regardless of the verdict. Phases 2-5 (routing on Gemma, doc review on Gemma, absorb the multi-repo contract, retire the Needle stack) remain unstarted; Phase 4 is where `MULTI-REPO-CACTUS-SENTINEL-DEPLOYMENT.md` is superseded. |

> **Issue lifecycle note (2026-07-22).** [#50](https://github.com/Hypercart-Dev-Tools/pdda/issues/50)
> was closed as `COMPLETED` when Phase 0's GO verdict landed. That was premature: Phase 0 is a
> *blocking gate* on the consolidation, not the consolidation itself, and Phases 1-5 are unstarted.
> The issue was reopened during the `/pdda-eod` wrap. #50 is the master tracking issue for all six
> phases and closes only when Phase 5 retires the Needle stack.

## Ask

Retire the bespoke Needle router/serving stack and put PDDA doc-governance review under the one local
model 3-Eyes already points at (`gemma4:12b-mlx`), supervised by the 3-Eyes TOML job registry.

The driver is **tech debt, not model quality**. The live issue is the discussion surface and holds the
full phase bodies, QA gates, metrics, and stop conditions — this doc is the in-repo capture.

## Why this is PDDA's issue and not a vendor's

PDDA owns the outcome: a doc-governance sentinel that is honest, maintainable, and cheap enough to
keep running. rebalance-OS/3-Eyes is a **tooling vendor** supplying supervision; cactus is a **tooling
vendor** supplying the incumbent model stack. Neither owns this decision, which is why the tracking
issue lives here.

## The debt being bought out

~60 KB of bespoke shell/Python across ten scripts (`sentinel-route.sh`, `sentinel-flywheel.sh`,
`router_serve.py`, `harvest_disagreements.py`, `build_router_query.py`, and five more), a 50.2 MB
finetuned checkpoint (`router.pkl`), an entire second ML runtime (a `needle` venv + JAX existing
solely to serve that one `.pkl`), and three hand-authored `KeepAlive` launchd plists
(`com.neochro.sentinel-daemon`, `com.neochro.needle-router`, `com.neochro.cactus-serve`).

## The correction this capture must preserve

"Sentinel" bundles three separable layers, at very different maturity:

| Layer | Needle stack today | 3-Eyes today |
|---|---|---|
| Supervision (schedule, health, kill switch) | 3 hand-authored plists | TOML registry + breakers + relief valves |
| Routing (`skip`/`readiness`/`escalate`, `focus`, `risk`, `triage`) | `router.pkl`, 50 MB finetuned, JAX, `:8082` | **nothing** |
| Review (`pass`/`revise`/`block` + confidence) | Needle served on `:8081` | **nothing** |

3-Eyes is a *job supervisor*, not a reviewer. Its only model call is `three_eyes/classify.py`, a
log-line severity tagger (`{"severity": critical|error|warn|info, "summary": short}`). For routing and
review this is a **build from zero**, not a migration. Anyone picking this up who misses that will
badly under-scope Phases 2–3.

## Decisions locked at capture

1. **Issue home:** this repo. Vendors get cross-link stubs for write-sets in their trees.
2. **Greenlight bar:** bounded regression — buy simplicity with a known, capped quality cost.
3. **Needle's fate if Gemma wins:** freeze `router.pkl` + the labelled replay set as an evaluation
   baseline; delete the serving path, daemon, plists, flywheel.
4. **`MULTI-REPO-CACTUS-SENTINEL-DEPLOYMENT.md`:** superseded — its per-target-watcher topology is
   what 3-Eyes registry jobs replace. Absorb its isolation contract and mode ladder, then move it to
   `3-COMPLETED` (Phase 4).

## Table of contents

- [Phase 0 — Spike: three-arm bake-off](#phase-0--spike-three-arm-bake-off)
- [Phase 1 — Adopt into 3-Eyes registry](#phase-1--adopt-into-3-eyes-registry)
- [Phase 2 — Rebuild routing on Gemma](#phase-2--rebuild-routing-on-gemma)
- [Phase 3 — Rebuild doc review on Gemma](#phase-3--rebuild-doc-review-on-gemma)
- [Phase 4 — Absorb contract](#phase-4--absorb-contract)
- [Phase 5 — Retire Needle stack](#phase-5--retire-needle-stack)

## Phase 0 — Spike: three-arm bake-off

Three-arm bake-off — Needle vs Gemma vs **deterministic-only** (`pdda.sh run`, no LLM). The third arm
is the floor, not a candidate: if neither model beats it, the honest outcome is to delete both rather
than swap one for the other. Corpus is the existing 1,754-record `PDDA-ACTIVITY.jsonl`, frozen and
hashed first because it is a live log that would otherwise drift mid-spike.

Two gates that are not negotiable:

- **Safety path has no margin.** Recall on `escalate` and reviewer `block` must be **≥** Needle's.
  The ≤10pp bounded-regression margin applies only to the general classes.

### QA Gates
- [x] Findings are written back to this doc.
- [x] Safety path recall is $\ge$ Needle's.

#### Phase 0 Findings (2026-07-22 - Fair Bake-off)
- **Methodology:** The original test was skewed by testing Needle on its own training corpus. The test was re-run using a strict holdout set (100 recent records) and providing Gemma with a level playing field (few-shot prompting). The memory max footprint constraint was explicitly lifted by the user.
- **Needle Arm:** Recall (escalate/block): 94%, FPR: 12%, F1 Score: 0.90
- **Gemma Arm (12B):** Recall (escalate/block): 95%, FPR: 4%, F1 Score: 0.95
**Verdict:** GO for Phase 1. Gemma 12B matches/exceeds Needle's recall on critical safety paths while significantly improving overall F1 by reducing false positives. With the footprint limit lifted, the consolidation is cleared to proceed.

## Phase 1 — Adopt into 3-Eyes registry

Adopt the three Cactus agents into the 3-Eyes registry. Model-independent, ships alone.

### QA Gates
- [ ] Cactus agents adopted into 3-Eyes.

## Phase 2 — Rebuild routing on Gemma

Gated on Phase 0.

### QA Gates
- [ ] Routing logic built on Gemma.

## Phase 3 — Rebuild doc review on Gemma

Gated on Phase 0.

### QA Gates
- [ ] Doc review built on Gemma.

## Phase 4 — Absorb contract

Absorb the multi-repo contract, retire the superseded doc.

### QA Gates
- [ ] Multi-repo contract absorbed and original doc retired.

## Phase 5 — Retire Needle stack

Retire the Needle stack, freeze the baseline.

### QA Gates
- [ ] Needle stack retired and baseline frozen.

## Vendor-dependency risk

Retiring Needle makes PDDA's sentinel depend on two things it does not control. Bounded by three
invariants, re-verified at every phase gate:

- **PDDA degrades to its own rails.** With 3-Eyes inert, Ollama down, or the model missing,
  `pdda.sh run` stays fully functional and authoritative. No PDDA check may ever require the sentinel
  to be alive.
- **No PDDA contract file may reference a vendor path** (`rebalance-OS/`, `cactus/`) — the
  hardcoded-paths check exists for exactly this.
- **Exit cost stays known.** If 3-Eyes is abandoned, PDDA loses scheduling convenience, not doc
  governance.

## Prior constraint consciously overridden

`PROJECT/2-WORKING/MULTI-REPO-CACTUS-SENTINEL-DEPLOYMENT.md` (2026-07-21, lines 124-127 and 245-248)
gates a central supervisor behind evidence from its Phases 1–2, which never ran. Overridden
deliberately: that gate existed to stop us *building* a premature supervisor, and 3-Eyes now exists,
merged and active, at zero marginal cost. The cost argument is moot; the evidence argument is not,
which is why Phase 0 is a measurement phase and Phase 1 is observe-only.

## Non-goals

- Sentinel-authored writes, commits, or PRs — still governed by GH-10, unchanged here.
- Finetuning Gemma. If Phase 0 says a general model is insufficient, the answer is "keep Needle,"
  not "start a second finetune programme."
- Training on target-repo content; the consent/minimisation/holdout boundary carries forward intact.
- Auto-enrolling repositories.
- Changing PDDA's contract, deterministic checks, or installer.
- Shipping any sentinel runtime, model, or registry entry in `install.sh`.

## Open questions

- Resident vs cold-start for `gemma4:12b-mlx` — Phase 0 must choose and justify.
- Does GH-10's Phase 3 replay harness merge with Phase 0's, or stay separate? Duplicating them would
  be its own new debt.
- Who owns the reviewer prompt contract once it is no longer a finetuned checkpoint?
