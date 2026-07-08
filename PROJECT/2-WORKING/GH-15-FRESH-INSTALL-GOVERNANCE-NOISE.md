---
title: "Fresh installs self-inflict ~30 governance warns from shipped docs (dead refs + phantom env vars)"
status: Active
created: 2026-07-08
updated: 2026-07-08
owner: noel
gh_issue: 15
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/15
doc_type: bugfix
branch: main
effort: 2
complexity: 2
risk: 1
phases: 3
context_tags: [governance, install, onboarding, signal-quality]
goal: >
  Stop a fresh `install.sh . --mode observe` from self-inflicting ~30 governance warns on its own
  first `pdda.sh run`, so a new adopter's first-run signal is their repo's own drift, not PDDA-on-PDDA
  noise from files the installer deliberately does not copy.
related: [PROJECT/PDDA.md, GH-14-GOVERNANCE-FD-EXHAUSTION.md]
---

## Status

| What was just completed | What's next |
|---|---|
| Issue #15 triaged and promoted to `2-WORKING`; the reporter's three candidate fixes transcribed below with a recommended default. | Phase 1 — decide which fix option to take (default: Option 3, exempt-by-manifest) before touching either `PDDA-INSTALL.md` or the governance check. |

## Table of contents

- [Phase 1 — Choose the fix approach](#phase-1--choose-the-fix-approach)
- [Phase 2 — Implement](#phase-2--implement)
- [Phase 3 — Verification](#phase-3--verification)

## Problem

A fresh `install.sh . --mode observe` into a clean target repo produces ~30 governance warns on its very
first `pdda.sh run`, because two files the installer *does* ship — `PDDA-INSTALL.md` and `PROJECT/PDDA.md` —
reference files the installer *deliberately does not copy*: `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`,
`CLAUDE.md`, and various skill paths. Every such reference resolves to a missing file in the target, so
`pdda-check-governance`'s dead-reference scan flags each one (see
[GH-14-GOVERNANCE-FD-EXHAUSTION.md](GH-14-GOVERNANCE-FD-EXHAUSTION.md) for the separate fd-exhaustion bug in
that same check — the reporter notes the ~30 figure was captured *after* patching that bug, since the
unpatched check under-reports and only surfaces 2 of 34 findings on stock macOS).

**Dead-reference warns (~30):** as above.

**Phantom env-var warns (3):** `PDDA-INSTALL.md` documents `PDDA_REGISTRY`, `PDDA_GITPULSE_DIR`, and
`PDDA_SYNC_MAX_SHRINK`, but no script shipped to the target reads them — same family of shipped-doc /
shipped-runtime mismatch, distinct root cause from the dead-reference case (these are HQ-only tool env vars
documented in a doc that ships everywhere; see `PROJECT/PDDA.md`'s existing note on `PDDA_SYNC_BACKUPS` for the
precedent that this specific pattern is an accepted, expected mismatch class, not new drift).

**Why it matters:** observe mode's entire value proposition is signal — "here's what's drifting in *your*
repo." When ~30 of the first-run warns are PDDA's own product debt, a new adopter cannot separate that from
their own repo's debt, and the natural response is to tune warns out — the exact habit-erosion the governance
layer exists to prevent.

### Reporter's candidate fixes

1. Ship the referenced docs (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `CLAUDE.md`, skill paths)
   alongside the runtime.
2. Strip or rewrite the dead references in the *installed copies* of `PDDA-INSTALL.md` and `PROJECT/PDDA.md`
   (leave the HQ originals untouched).
3. Teach the dead-reference check to exempt shipped-runtime docs via a manifest of installer-provided files.

Reporter's own read: Option 2 or 3 is lightest; Option 3 also covers future shipped docs automatically without
a follow-up install-time rewrite step.

## Phase 1 — Choose the fix approach

Weigh the three options against the existing install contract before implementing:

- **Option 1 (ship the docs)** conflicts with `utils/pdda/PDDA-INSTALL.md`'s existing "canonical install set" —
  those governance docs are intentionally repo-authored in the target, not vendored copies of PDDA's own. This
  option is likely the wrong shape; it would also make every target's `ROUTER.md` etc. an install-time fork
  that immediately drifts from the target's real repo, which is the opposite of Principle #4 (one canonical
  place per fact).
- **Option 2 (rewrite installed copies)** is a targeted, low-blast-radius patch but only fixes the two docs
  named in this issue — a third shipped doc added later with the same pattern would silently regress.
- **Option 3 (exempt-by-manifest)** generalizes the fix and matches how `pdda-check-governance`'s existing
  `GH-<n>-*.md` exemption already works (a known-pattern allowlist inside the check itself), so it is
  consistent with the check's existing exemption style rather than a new mechanism.

**Recommended default: Option 3.** Confirm or override before Phase 2 — this doc's decision line is the gate.

**QA gate:**
- [ ] one option selected and the reasoning recorded in this section (already drafted above; confirm or amend)
- [ ] confirmed the selected option does not reintroduce the "shipped doc references a file the installer
      intentionally omits" pattern for any doc not covered by this fix

## Phase 2 — Implement

Implement the selected option. If Option 3 (default):

- add a manifest (e.g. `utils/pdda/pdda-lib.sh` constant or a small data file) listing the file basenames a
  shipped doc is allowed to dead-reference because the installer deliberately does not copy them —
  `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `CLAUDE.md`, **`README.md`**, relevant skill paths.
  (**Note, added from Codex consult review, adjudicated 2026-07-08:** `README.md` was missing from the
  original candidate list even though it's in `pdda-check-governance`'s own default scan set
  (`utils/pdda/PDDA-INSTALL.md:175`) and is referenced by backtick in the same doc's own prose
  (`utils/pdda/PDDA-INSTALL.md:53`) — a target repo installed without `--with-startup-docs` and without its
  own pre-existing `README.md` would still leak a dead-reference warn. Build the manifest from an actual
  scan of what `PDDA-INSTALL.md` and `PROJECT/PDDA.md` dead-reference in a bare target install, not by
  retyping the issue's illustrative list.)
- extend `pdda-check-governance`'s dead-reference scan to skip a match against that manifest, scoped to the
  installer-shipped docs (`PDDA-INSTALL.md`, `PROJECT/PDDA.md`) only — do not weaken the check for
  repo-authored docs, where a dead reference to `ROUTER.md` etc. is a real drift signal
- resolve the phantom-env-var warns the same way: confirm they match the already-accepted "HQ-only tool
  documented in a doc that ships everywhere" pattern (`PDDA-INSTALL.md`'s existing `PDDA_SYNC_BACKUPS`
  precedent in `PROJECT/PDDA.md`) and extend that same exemption list rather than inventing a second mechanism

**QA gate:**
- [ ] `utils/pdda/PDDA-INSTALL.md` and the manifest stay in lockstep per `ROUTER.md`'s existing rule
- [ ] the exemption is scoped narrowly enough that a genuine dead reference in a repo-authored governance doc
      still fires (no over-broad suppression)
- [ ] `PROJECT/PDDA.md`'s `pdda-check-governance` section documents the new exemption manifest and its scope
      in the same change (AGENTS.md #5 — keep the installer surface in lockstep)

## Phase 3 — Verification

Re-run the reporter's repro: fresh `install.sh . --mode observe` into a clean target, first `pdda.sh run`.

**QA gate:**
- [ ] fresh-install first run produces zero dead-reference / phantom-env-var warns attributable to
      `PDDA-INSTALL.md` / `PROJECT/PDDA.md` themselves
- [ ] a deliberately broken reference added to a repo-authored governance doc in the same fresh install still
      gets flagged (negative-control check that the exemption did not over-suppress)
- [ ] `CHANGELOG.md` entry added citing issue #15 and the verification result
- [ ] issue #15 closed on GitHub once verified
