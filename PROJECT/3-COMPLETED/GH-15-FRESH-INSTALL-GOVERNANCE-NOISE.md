---
title: "Fresh installs self-inflict ~30 governance warns from shipped docs (dead refs + phantom env vars)"
status: Completed — all 3 phases shipped + verified, issue closed
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
| Phases 1–3 done: confirmed Option 3 (exempt-by-manifest), built the exemption manifest from an actual scan of a bare `install.sh` target (not the issue's illustrative list — it added `CLAUDE.md` and the legacy `utils/PDDA-INSTALL.md` path, and excluded `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md` as a separate pre-existing bug), implemented + documented in lockstep, and verified: fresh-install governance warns dropped 35→4, negative control confirmed a real dead reference in a repo-authored doc still fires. | Close out: add the CHANGELOG entry, close issue #15, `git mv` this doc to `PROJECT/3-COMPLETED/`. Optionally open a small follow-up for the separate `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md` prose-accuracy drift found in `PROJECT/PDDA.md` during Phase 2 (out of this issue's scope). |

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

**Confirmed 2026-07-08:** Option 3, as recommended. It's the only option consistent with Principle #4 —
Option 1 would fork every target's `ROUTER.md`/etc. as an install-time copy that immediately drifts from
the target's real repo; Option 2 is a one-off patch that regresses the next time a shipped doc gains the
same pattern. Option 3 generalizes via the same allowlist style the check already uses for `GH-<n>-*.md`.

**QA gate:**
- [x] one option selected and the reasoning recorded in this section (Option 3, confirmed above)
- [x] confirmed the selected option does not reintroduce the "shipped doc references a file the installer
      intentionally omits" pattern for any doc not covered by this fix — the exemption is scoped strictly
      to `PDDA_GOV_SHIPPED_DOCS_DEFAULT` (`utils/pdda/PDDA-INSTALL.md`, `PROJECT/PDDA.md`); a
      negative-control test (Phase 3) confirms a repo-authored doc's genuine dead reference still fires

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

**Implemented 2026-07-08** in `utils/pdda/pdda.sh` (`check_governance`): three new manifest constants
(`PDDA_GOV_SHIPPED_DOCS_DEFAULT`, `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`,
`PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT`, each with a `PDDA_GOV_*` env override), consumed by
both the dead-reference loop and the env-var-drift loop, gated on `doc` being one of the two
`PDDA_GOV_SHIPPED_DOCS` entries. **Built from an actual dead-reference scan of a bare `install.sh`
target** (`install.sh <scratch-target> --no-register`, then `pdda.sh governance` there), not retyped
from this doc's Phase-2 candidate list — the real scan added two entries the candidate list missed
(`CLAUDE.md`, and the legacy pre-`utils/pdda/` path `utils/PDDA-INSTALL.md` named only in migration-note
prose) and, importantly, **excluded** `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md`: those don't exist even in
HQ (not an install-omission case — a separate, pre-existing doc-accuracy drift in `PROJECT/PDDA.md`
itself, left flagged rather than silently swept into this manifest).

**QA gate:**
- [x] `utils/pdda/PDDA-INSTALL.md` and the manifest stay in lockstep per `ROUTER.md`'s existing rule —
      the 3 new `PDDA_GOV_*` overrides added to `PDDA-INSTALL.md`'s "Environment overrides" list
- [x] the exemption is scoped narrowly enough that a genuine dead reference in a repo-authored governance doc
      still fires (no over-broad suppression) — verified in Phase 3's negative control
- [x] `PROJECT/PDDA.md`'s `pdda-check-governance` section documents the new exemption manifest and its scope
      in the same change (AGENTS.md #5 — keep the installer surface in lockstep)

## Phase 3 — Verification

Re-run the reporter's repro: fresh `install.sh . --mode observe` into a clean target, first `pdda.sh run`.

**Results (2026-07-08):** fresh-scratch-target `pdda.sh governance` warns dropped **35 → 4**; the
remaining 4 are the two RECAP.md/REAL-AGENT-OBSERVATIONS.md mentions in `PROJECT/PDDA.md` noted above
(pre-existing, out of this issue's scope). Negative control: added a throwaway `ROUTER.md` to the same
fresh target with a genuinely broken reference (`NONEXISTENT-FILE.md`) plus a reference to an exempted
name (`AGENTS.md`) — both still fired as `warn`, since `ROUTER.md` is not in `PDDA_GOV_SHIPPED_DOCS`;
confirms the exemption did not over-suppress. Re-ran `pdda.sh governance` on **this HQ repo itself**
before/after too (errors=2/warns=7 → errors=2/warns=4) — the 2 errors (`glance`/`quad-concepts`
subcommand-drift, ROUTER.md) are pre-existing and unrelated to GH-15, noted separately below; HQ's own
warns dropped from 7 to the same 4 RECAP.md/REAL-AGENT-OBSERVATIONS.md mentions. Full `pdda.sh run`
still exits 0 in both HQ and the fresh target.

**QA gate:**
- [x] fresh-install first run produces zero dead-reference / phantom-env-var warns attributable to the
      install-omission pattern this issue describes (35→4; the remaining 4 are the separate
      RECAP.md/REAL-AGENT-OBSERVATIONS.md drift noted above, not this issue's root cause)
- [x] a deliberately broken reference added to a repo-authored governance doc in the same fresh install still
      gets flagged (negative-control check that the exemption did not over-suppress)
- [x] `CHANGELOG.md` entry added citing issue #15 and the verification result
- [x] issue #15 closed on GitHub once verified

## Follow-ups discovered, out of this issue's scope

- **`PROJECT/PDDA.md`'s own `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md` dead references** (lines ~669–696):
  neither file exists anywhere in this repo, including HQ. Different root cause than GH-15 (not an
  install-omission — these read as claims that current artifacts exist when they don't). Recommend a
  tiny follow-up once a human confirms intent (was `REAL-AGENT-OBSERVATIONS.md` actually retired too, or
  should it exist?) — a ≤2–3 line prose fix, under the issue-first SOP floor, no new GitHub issue needed.
- **HQ's own `ROUTER.md` subcommand-drift errors** (`glance`, `quad-concepts` undocumented): pre-existing,
  unrelated to GH-15, discovered as a side effect of re-running `pdda.sh governance` on HQ during Phase 3
  verification. `full` mode would block on these; HQ currently runs `observe`. Trivial doc-only fix
  (mention both subcommands somewhere in `ROUTER.md`) — flagging for a separate pass rather than folding
  into this diff.

## Lessons Learned (For Future Agents)

- **Always run the actual scan before trusting an issue's illustrative list.** The reporter's candidate
  exemption list (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `CLAUDE.md`, `README.md`, skill
  paths) was close but not exhaustive — installing into a real scratch target and running
  `pdda.sh governance` there surfaced 2 more legitimate entries (the pre-`utils/pdda/` legacy path, and
  a second `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md` HQ-only-doc case) and, more importantly,
  4 warns that *looked* like the same pattern but weren't (`RECAP.md`/`REAL-AGENT-OBSERVATIONS.md`).
  Sandbox note: `/tmp` was write-denied here; use the session scratchpad dir for throwaway install
  targets instead (`git init` + `install.sh <target> --no-register`).
- **"Files the installer omits" and "files that don't exist anywhere" are different bugs with the same
  symptom.** Both show up as `pdda-check-governance` dead-reference warns, but only the first is an
  install-boundary exemption; the second is real doc-accuracy drift (Principle #4) that exempting would
  have silently hidden. When building an allowlist-style fix, check each candidate against the *source*
  repo too, not just the target — if it's missing in both, exempting it hides a real bug instead of a
  false positive.
- **A negative control is cheap and worth the extra 2 minutes.** Adding one throwaway repo-authored file
  with a genuinely broken reference to the same scratch target immediately proved the exemption's scope
  guard (`doc` must be in `PDDA_GOV_SHIPPED_DOCS`) actually worked, rather than trusting the diff by
  inspection alone.
- **Watch for self-referential noise when documenting a dead-reference exemption.** Backtick-wrapping the
  excluded filenames (`` `RECAP.md` ``) in this doc's own prose triggered two *new* dead-reference warns
  against itself on the first pass — the check doesn't distinguish "this is prose about the bug" from "this
  is a live cross-reference." Describe excluded filenames without the `.md`-ending backtick span when
  writing about them inside a governance doc.
