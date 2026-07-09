# CHANGELOG.md

## 2026-07-08

### HQ governance cleared to zero: GH-17 + GH-18 fixed, three inactive docs archived

`utils/pdda/pdda.sh run` on this repo went from **3 errors + 6 warns → 0 errors + 0 warns**. PDDA had
been dogfooding itself into a permanently dirty baseline, which made every new finding easy to dismiss
as "pre-existing." Five distinct fixes:

**GH-17 (4 dead-reference warns).** `PROJECT/PDDA.md`'s CHANGELOG section claimed `RECAP.md` was
"retired → `PROJECT/4-MISC/`" and that `REAL-AGENT-OBSERVATIONS.md` "still holds run-specific compliance
findings." Neither file exists, and `git log --all` shows neither ever has — this was aspirational text
inherited from the upstream repo PDDA was extracted from, not a record of deleted files. Maintainer
confirmed both conventions retired. Prose reworded to drop the backticked-filename form (the
dead-reference check is purely lexical and reads any `` `X.md` `` as a live cross-reference regardless of
surrounding "retired"/"former" prose). The third claim was load-bearing: deleting it outright would have
left run-specific compliance findings with no destination at all, so that role was explicitly reassigned
to `CHANGELOG.md` rather than silently dropped.

**GH-18 (2 subcommand-drift errors).** GH-12 shipped `glance` and `quad-concepts` into the `pdda.sh`
dispatcher *and* into `pdda.sh help`, but never into `ROUTER.md`'s Command rails list — so
`pdda-check-governance` errored on HQ itself, exactly the AGENTS.md #5 lockstep violation that check
exists to catch. Both lines added, blurbs lifted verbatim from `pdda.sh help` so the two surfaces can't
drift on wording. The generalizable lesson: **adding a `pdda.sh` subcommand is a three-file change
(dispatcher + `help` + `ROUTER.md`), not two.**

**1 roadmap-coverage error + 2 stale-doc warns.** Three docs archived to `PROJECT/4-MISC/` via `git mv`:
`QUAD-GML52.md` (the raw, unedited GLM 5.2 design pass that seeded GH-12 — a provenance artifact
mis-filed as active work, still carrying its chatbot preamble), plus `INSTALL-SCRIPT-AND-ONBOARDING.md`
(10d stale) and `SYNC-LIST-STATUS-RECONCILE.md` (8d stale). Archived, deliberately **not** promoted to
`3-COMPLETED` — both shipped their stated goal but neither reached a completion anyone declared, and
`3-COMPLETED` would have claimed one. `ROADMAP.md`'s previously-empty "Deferred" section now records all
three with why. GH-17 and GH-18's docs were promoted `1-INBOX → 3-COMPLETED`, each with a Resolution and
a Lessons Learned section.

The bet: a zero-finding baseline is worth more than the three docs' nominal "active" status, because a
noisy baseline trains operators to ignore the tool. Reversibility: **Easy** — every move is a `git mv`,
every edit is prose, nothing was deleted.

Verification: `utils/pdda/pdda.sh run` → `errors=0 warns=0` across all nine checks (was `errors=3
warns=6`). Note the run *already* printed "PDDA run complete: all checks passed" when it had 3 errors,
because this repo is in `observe` mode and the gate returns exit 0 regardless — that is BUG-001b, tracked
as GH-14 Phase 2, and this iteration hit it firsthand. **A green summary line from `pdda.sh run` is not
currently evidence of a clean run; read the per-check `SUMMARY` lines.**

### Registered experimental/PRD-pdda: synthesis of the PRD-Kimi and PRD-Perplexity drafts

New third variant, `experimental/PRD-pdda/` (`SKILL.md` + six `references/` files), synthesizing the two
competing drafts rather than replacing either — both sibling folders are untouched. Perplexity's
execution rigor (FR-IDs, P0/P1/P2 with justification, verifiable acceptance criteria, explicit data
model, NFR table, guardrail metric, agent-executable milestones with scope/dependency/completion-criteria
/implementation-prompt structure) is preserved but rewritten in Kimi's plain-English, non-jargon voice.

The substantive merge: Kimi's Iron Triangle (Faster/Better/Cheaper) is promoted from a *label* to the
**governor** of the build plan. Perplexity gave every product the identical fixed 5-milestone ladder
regardless of tradeoff; here each branch doc carries a "Milestone shape (governs MILESTONES.md)" section
setting milestone count, pacing, and validation-gate density, and `milestone-template.md` explicitly
instructs: *"Do not emit the default 5-milestone ladder regardless of the choice."* The branch doc sets
the plan's shape; the template sets each milestone's format.

Kimi's Cheaper-branch "UX/Dev Ratio Discipline" is carried through with all four guardrails intact — the
load-bearing insight that Cheaper's failure mode is an *uneven* UX-vs-dev split (dev rabbit-holing while
messaging gets the remainder), not underspending, and therefore demands *more* operator discipline than
Faster or Better, not less. Its "good enough" bar now explicitly exempts onboarding and value-prop copy:
everything else in a Cheaper build may ship rough; the messaging may not.

Also new: a two-mode intake (Mode A quick-fire, one short question at a time; Mode B brain dump with an
explicit extract → transform → infer pass and `(Inferred)` tagging), both routing through one shared
target field set and one shared category-based inference library, with propose-a-default
(Confirm/Adjust/Override) as the *default* behavior rather than a fallback. The whole interview is capped
at **≤10 questions** across both intake and spec-grounding — one budget, not two — with Q7 firing
conditionally (Cheaper only), so the realistic count is 9–10 and the ceiling is not a target.

Correcting an assumption worth recording: **`PRD-Kimi/` has no `references/` folder.** It is a single
511-line design narrative that embeds all six of its proposed reference files inline as fenced code
blocks. `PRD-Perplexity/` is the only one of the two shaped as a real, installable skill. `PRD-pdda/`
follows Perplexity's shape.

Still draft-stage: not yet converted into an installed `.claude/skills/product-prd-builder/`. No
`PROJECT/**` doc or GH issue (exploratory content, outside `pdda.sh roadmap-coverage` scope). Registered
as a pointer in `ROADMAP.md`'s "In progress" ledger.

Verification: `utils/pdda/pdda.sh run` → `errors=0 warns=0`. All 7 `references/*.md` cross-references in
`SKILL.md` resolve to real files; `git status` confirms `PRD-Kimi/` and `PRD-Perplexity/` unmodified.

### Experimental PRD generator skill draft: split into PRD-Kimi and PRD-Perplexity variants

Reorganized `experimental/PRD/` (a single early `SKILL.md` draft for a not-yet-built
`product-prd-builder` skill) into two parallel variants: `experimental/PRD-Perplexity/` (rename of
the original draft, content unchanged) and a new `experimental/PRD-Kimi/SKILL.md`, which adds Iron
Triangle branching (Faster/Better/Cheaper) as the primary Phase 2 scoping lever, plus Fast Track,
table-stakes, and moat-question design decisions.

Followed up by expanding the Cheaper branch (the Q7 interview script, the locked-decisions table,
and `references/iron-triangle-cheaper.md`) with a "Cheaper isn't the easy corner" framing: Faster
has a deadline as its forcing function and Better has a quality bar, but Cheaper has neither, so
effort silently reallocates. Its real failure mode is an uneven UX-vs-dev time/budget split — dev
work rabbit-holing on the technical problem while UX, copy, and messaging get whatever's left —
not underspending outright. Added an explicit "UX/Dev Ratio Discipline" section: declare the split
before Phase 1, time-box dev overruns as a gold-plating checkpoint, treat messaging/onboarding as a
first-class deliverable every phase, and surface (not silently absorb) a broken ratio mid-build.

Both variants remain draft-stage design docs, not yet converted into an installed
`.claude/skills/product-prd-builder/` skill; no `PROJECT/**` doc or GH issue filed (exploratory
content, outside `pdda.sh roadmap-coverage` scope). Registered a pointer in `ROADMAP.md`'s "In
progress" ledger for visibility on request.

Verification: `utils/pdda/pdda.sh run` — no new findings from this change (pre-existing
`PROJECT/2-WORKING/QUAD-GML52.md` frontmatter error and `ROUTER.md` `glance`/`quad-concepts`
subcommand-drift errors are unrelated, already tracked).

### GH-21 shipped: SKILLS/PDDA-hook opt-in SessionStart doc-governance reminder

New bundled skill, `SKILLS/PDDA-hook/`, so PDDA compliance doesn't depend on the model remembering to
(re-)read `ROUTER.md`/`AGENTS.md`/`PROJECT/PDDA.md` across a long session, after `/compact`, or after
`/clear`. Installs a `SessionStart` hook (`scripts/pdda-doc-governance-reminder.sh`, `startup`/`resume`/
`clear`/`compact` matchers) that re-injects a short doc-governance reminder at every context boundary,
auto-scoped via a `PROJECT/PDDA.md` runtime check so one registration is safe across both PDDA and
non-PDDA repos. Personal, propose-then-confirm, and only ever writes to the operator's own
`~/.claude/settings.json` (global scope) or a repo's `.claude/settings.local.json` (repo-local scope) —
never a repo's committed `settings.json`.

Global scope is a deliberate, called-out exception to this repo's norm of wiring hooks repo-local
(`utils/pdda/pdda-edit-doc-hook.sh`, `utils/pdda/pdda-stop-doc-health.sh` both live in the committed
`.claude/settings.json`): "remember to open ROUTER.md" is a cross-repo operator habit, not a per-repo
lint rule, so this skill is allowed to write to `~/.claude` where PDDA's other tooling otherwise avoids
it.

Follow-up hardening after an initial review found two gaps: the globally-deployed script had drifted
from the skill's canonical source (re-synced, now byte-identical), and the repo-local guardrail claimed
`.claude/settings.local.json` was "gitignored by convention" without verifying that — it was only
ignored via the operator's personal global git ignore, not this repo's own `.gitignore`. Fixed both:
`SKILL.md` now runs `git check-ignore` before a repo-local write and asks before proceeding if nothing
covers the file, and this repo's `.gitignore` now excludes `.claude/settings.local.json` directly so a
fresh clone is covered without relying on the operator's machine config.

Verification: `./utils/pdda/pdda.sh run` (pre-existing, unrelated findings only — QUAD-GML52.md
frontmatter/roadmap-coverage, `ROUTER.md` `glance`/`quad-concepts` subcommand drift); manually diffed
the reconciled hook script against `SKILLS/PDDA-hook/scripts/pdda-doc-governance-reminder.sh` (now
identical); confirmed the hook is live and firing via this session's own `SessionStart` reminder.

### GH-15 Phases 1–3 shipped: exemption-manifest fix for fresh-install governance noise

Implemented the Option-3 fix (exempt-by-manifest, confirmed in the prior Codex-consult entry below) in
`utils/pdda/pdda.sh`'s `check_governance`: three new manifest constants
(`PDDA_GOV_SHIPPED_DOCS_DEFAULT`, `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`,
`PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT`, each with a `PDDA_GOV_*` env override), scoped strictly
to `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` — the two docs `install.sh` ships to every target.
Built from an **actual dead-reference scan** of a bare `install.sh` target (not the issue's illustrative
list): the real scan found two entries the candidate list missed (`CLAUDE.md`, and the legacy
pre-`utils/pdda/` path `utils/PDDA-INSTALL.md` named only in migration-note prose) and — importantly —
excluded `RECAP.md`/`REAL-AGENT-OBSERVATIONS.md`, which don't exist even in HQ and are therefore a
separate, pre-existing doc-accuracy drift, not this issue's install-omission pattern; left flagged rather
than silently swept into the manifest. `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` updated in the
same change to document the new overrides (AGENTS.md #5).

**Verification:** fresh `install.sh . --mode observe` into a clean scratch target, `pdda.sh governance`
warns dropped **35 → 4** (the remaining 4 are the out-of-scope RECAP.md/REAL-AGENT-OBSERVATIONS.md
mentions). Negative control: a throwaway repo-authored `ROUTER.md` added to the same target with a
genuinely broken reference plus a reference to an exempted name — both still fired as `warn`, confirming
the exemption didn't over-suppress. Re-ran on HQ itself too: warns 7 → 4 (same 4 remaining), errors
unchanged at 2 (pre-existing `glance`/`quad-concepts` subcommand-drift in `ROUTER.md`, unrelated to
GH-15, noted as a separate follow-up in the working doc). Full `pdda.sh run` exits 0 in both repos.

Two follow-ups noted in the working doc, deliberately left out of this diff: the RECAP.md/
REAL-AGENT-OBSERVATIONS.md prose-accuracy drift in `PROJECT/PDDA.md` (needs a human call on those files'
fate), and HQ's own `ROUTER.md` subcommand-drift errors (trivial, unrelated fix).

### GH-14 + GH-15 triaged into remediation plans, reviewed by a Codex consult

Two GitHub issues from an external beta test (`EOS-daily-skill` install exercise) triaged straight into
`PROJECT/2-WORKING/` as PDDA-compliant remediation plans (issue-first SOP, promoted directly since
execution review starts immediately): [GH-14-GOVERNANCE-FD-EXHAUSTION.md](PROJECT/2-WORKING/GH-14-GOVERNANCE-FD-EXHAUSTION.md)
(fd exhaustion in `pdda-check-governance`'s dead-reference scan under stock macOS bash 3.2, plus BUG-001b —
a crashed check silently reporting "all checks passed") and
[GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md](PROJECT/2-WORKING/GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md) (fresh
installs self-inflict ~30 governance warns from shipped docs dead-referencing files the installer
intentionally omits). Ran a one-shot `/relay-xyz` consult (`relay-automation/consult.sh`) with Codex against
both plans; findings adjudicated against `GUIDING-PRINCIPLES.md` and folded back into both docs:

- **[Confirmed, GH-14]** BUG-001b's `checks-failed-to-run` field only covers a check that *soft-degrades*
  (swallows an internal error and still returns 0) — a *hard crash* that kills the whole `pdda.sh` process
  can't self-report, since nothing survives to emit the field. Reproduced live during this triage: `bash
  utils/pdda/pdda.sh governance` exited 134 (SIGABRT) under a raised `ulimit`, matching the reporter's row-2
  matrix case exactly, on this very repo's default bash 3.2.57. Phase 2's QA gate tightened to require the
  check body itself to detect and convert soft-degrade cases, not just format a summary line.
- **[Confirmed, GH-15]** the exemption-manifest candidate list (Option 3) was missing `README.md` — it's in
  `pdda-check-governance`'s own default scan set and referenced by the same shipped docs the issue names.
  Phase 2 now directs building the manifest from an actual dead-reference scan of a bare target install, not
  by retyping the issue's illustrative file list.
- **[Confirmed, both]** neither plan had an explicit "update `PROJECT/PDDA.md` in the same change" QA gate
  for the behavior changes each introduces (new summary field; new exemption manifest) — added per AGENTS.md
  #5 (keep the installer surface in lockstep).

No code changed yet — both docs are queued for phase-by-phase execution next. `pdda.sh run` clean against
both new docs (frontmatter/status-table/roadmap-coverage/hardcoded-paths).

### GH-14 Phase 1 shipped; spike closed on XYZ harness -> Aider -> OpenRouter -> GLM 5.2

On `test/aider-openrouter-glm52-gh14-gh15` (off `main`), tested whether the vendored
`.xyz/relay-automation/aider-turn.sh` shim (built earlier, GH-67/77/119/120-hardened; this was its first
real exercise in this repo) could drive Aider through OpenRouter to GLM 5.2 to autonomously execute GH-14
Phase 1 end to end. Full writeup: [AIDER-GLM-XYZ-HARNESS-TEST-2026-07-08.md](PROJECT/3-COMPLETED/AIDER-GLM-XYZ-HARNESS-TEST-2026-07-08.md).

- Pipeline wiring confirmed end-to-end: OpenRouter model resolution (`glm-5.2` -> `z-ai/glm-5.2` via the
  harness's own alias table), `tick` token coordination, containment, file-scoped commit. Found and fixed
  2 real integration bugs along the way: Aider silently drops a gitignored `--file` target even with
  `--no-gitignore` set; the lane-attempt-cap correctly required `--force` to re-fire after the first two
  no-op attempts.
- The model did not land the edit across 2 real attempts — it drafted the correct fix once but then
  spiraled into requesting ~12 unrelated repo files and never finalized it, while the harness reported
  false success ("committed") because its outcome check only verifies non-empty output, not that the
  intended file actually changed. A second attempt with a tighter timeout was killed before the model
  (a heavy "thinking" model) could respond at all — a tuning mistake, not a new finding.
- **Bet:** the harness's success signal (empty-output guard) is not sufficient proof of task completion;
  don't trust it for unattended runs without hardening the outcome check to diff the actual target files.
  Revisit only if this pipeline is deliberately picked up again — see the spike doc's Recommendation.
- GH-14 Phase 1 (the one-line fd fix) applied directly by hand instead. Verified 5/5 consecutive
  `utils/pdda/pdda.sh governance` runs clean (exit 0, consistent finding count, no fd/trap crash — this
  crash had been reproduced live twice earlier the same session on this repo's own stock bash 3.2.57,
  SIGABRT then SIGSEGV). Full `pdda.sh run` also clean. GH-14 plan doc's Status + Phase 1 QA gate updated.

## 2026-07-07

### `/triage` + `/idea` — two PDDA intake front-door skills, hardened by a Codex + agy consult

Two sibling Claude Code skills that turn work intake into a PDDA-compliant capture, then a two-pass
cross-model consult (Codex `gpt-5.4` + agy, independent) that found real drift in both. Both advisors
said keep them; the fixes below are their reconciled findings, each verified against the shipped checks.

- **`.claude/skills/triage/SKILL.md`** — incoming external report (URL) → `PROJECT/1-INBOX/GH-<n>-*.md`
  remediation capture: distilled problem summary, a **light first-pass validation** table
  (`Confirmed / Plausible / Unclear / Not-yet-verified`), and checklist phases with a dedicated
  deeper-exploration spike. Resolves or opens the tracking issue; parks a `ROADMAP.md` queue pointer.
- **`.claude/skills/idea/SKILL.md`** — net-new operator idea → the same capture shape, with a fixed
  4-question intake and an LLM **synthesis** step (Why, Key Concepts, `non_goals`, provisional ratings)
  that a static template structurally can't produce. Built from xyz-3-agents-swarm GH-164's deferred
  `/idea` sketch, but made **self-sufficient** (direct PDDA write) since PDDA's vendored `hq` lacks the
  `HQ_PARK_*` synthesis interface; `hq park --create` stays an optional accelerator.
- **Consult fixes (both skills):** the advertised `pdda.sh frontmatter` verify was a **false green** —
  `check_frontmatter` iterates `pdda_list_working_docs` (`2-WORKING` only), so it never validated the
  1-INBOX capture it had just written. Verification now names the check that actually covers the path:
  `roadmap-coverage` for a capture, `frontmatter`+`status-table`+`roadmap-coverage` for `--working`,
  plus `quad-concepts` when the lever is on. Also: conditional `## Quad Concepts` block (1-INBOX/GH-* is
  in quad scope), `owner` derived from `git config user.name` instead of hardcoded, `gh` unsandboxed-retry
  preflight, and a one-doc-per-issue guard.
- **`/triage` only:** `--working` now emits a real active doc (populated `## Status` table, `updated` +
  `goal`, TOC/QA gates when multi-phase) and parks its pointer in the **active ledger**, not the queue
  section; origin-vs-foreign detection normalizes SSH/HTTPS/`.git` to `host/owner/repo` before comparing.
- **`/idea` only:** `--queue` **removed** — a 1-INBOX capture has no write-set and is un-promoted, so it
  cannot be a runnable marathon lane; queuing is now an explicit post-promotion step. Collapsed to one
  preview → one confirmation (resolving the GH-number-before-filename ordering), `doc_type` mapped
  deterministically from the rough shape, and `non_goals` de-duplicated to frontmatter only.
- **`PROJECT/PDDA.md`** — the reference selection rule is now
  `eligible = risk <= 2 AND not ratings_provisional`. `ratings_provisional: true` is an **eligibility
  gate, not just metadata**: auto-drafted intake ships best-guess ratings, and a rough `risk: 2` on a
  large effort must not become auto-selectable on the strength of that guess. Same "route to a human"
  posture as `risk >= 4`. (agy's finding; Codex had read provisional ratings as inert metadata.)

### Quad Concepts — an opt-in ≤4 pain→fix glance layer for plan docs (GH-12)

A new **opt-in** convention (off by default): when the `.pdda-quad` / `PDDA_QUAD` lever is on, tracked
plan docs carry a `## Quad Concepts` section of 1–4 `pain → fix` bullets so a human or cold-start agent
gets a 5-second orientation and an operator can see whether a plan covers the real pains. The lever is
**orthogonal** to the enforcement mode — the lever decides whether `pdda.sh quad-concepts` joins
`pdda.sh run`; `observe/light/full` still decides report-vs-block. Synthesizes a GLM 5.2 design pass with
a Codex + agy consult that hardened the parser.

- **Deterministic check** `pdda.sh quad-concepts` (structure-only): first `## Quad Concepts` section,
  1–4 top-level non-empty `-`/`*` bullets; skips fenced code, indented/nested and empty bullets;
  normalizes CRLF; stops on the next h1/h2 or a blank line after a bullet; duplicate sections don't sum.
  Scope: `2-WORKING` + `1-INBOX/GH-*` + `3-COMPLETED`; per-doc opt-out `quad_exempt: true`.
- **Lever + install:** `quad_is_enabled()` resolves `PDDA_QUAD` → `.pdda-quad` file → off; `install.sh`
  gains `--quad` and seeds a `.pdda-quad` (off by default). Contract documented in `PROJECT/PDDA.md`.
- **Tests:** `test/pdda-quad-concepts.sh` (34/34). Default `pdda.sh run` output is unchanged when off.
- Follow-up (Phase 3): a warn-only readiness rubric in `pdda-doc-ready.sh` for concept *quality*/staleness.

## 2026-07-06

### Reframe PDDA as a de facto project memory layer (contract + LLM nudges)

PDDA already enforced document hygiene so work could be *resumed*; this iteration strengthens that
contract into a practical memory layer that also keeps durable context, decisions, and lessons a cold
agent would otherwise re-learn the hard way. Three coordinated changes, no new deterministic shell
surface:

- **`ROUTER.md`** — the startup sequence now tells an agent that is exploring an unknown system,
  proposing a spike, or blocked to first search `PROJECT/3-COMPLETED/` and `CHANGELOG.md` for prior
  context (memory *retrieval*).
- **`PROJECT/PDDA.md`** — a `## Lessons Learned (For Future Agents)` section is now required before a
  doc moves to `PROJECT/3-COMPLETED/`; the discovery/spike phase is reframed as **Memory Injection**
  (findings must be written back into the plan, not left in chat context); and `context_tags` is
  documented as an optional recommended frontmatter field. `context_tags` needs no change to `pdda.sh`
  — `check_frontmatter` ignores unknown keys — so it stays a documentation-only convention.
- **`utils/pdda/pdda-doc-ready.sh`** — the LLM readiness rubric gained two warn-capped nudges: a
  medium-large plan/project with an empty `related:` field, and a `risk: 4`/`risk: 5` plan that links
  no `decisions/` record. Both remain warnings — they add memory pressure without ever blocking a
  deterministic run.

Verification: `pdda.sh governance` clean (`errors=0`; the 10 pre-existing `blank.md`/`RECAP.md`-style
warns in `PROJECT/PDDA.md` are unrelated and left as flagged). Full plan doc moved to
`PROJECT/3-COMPLETED/PROJECT-MEMORY-LAYER.md`. Lockstep: `README.md` § "The project memory layer",
`ROUTER.md` (startup sequence), `PROJECT/PDDA.md` (Lessons Learned + Memory Injection + frontmatter).

## 2026-07-03

### New `pdda.sh governance` check + `/governance-audit` skill for cross-doc consistency

PDDA had no check for the governance docs themselves (`ROUTER.md`, `AGENTS.md`,
`GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`, `PROJECT/PDDA.md`, `utils/pdda/PDDA-INSTALL.md`) —
only project docs in `PROJECT/2-WORKING` were linted. Added `pdda.sh governance`: dead `.md`
cross-references (`warn`; bare filenames fall back to a repo-wide basename search so multi-copy names
like `blank.md` don't false-flag, and `GH-<n>-*.md` naming-convention examples are exempt), orphan
governance docs `ROUTER.md` never points at (`warn`), `pdda.sh` dispatcher subcommands undocumented in
`ROUTER.md` (`error` — mechanical, parses the real `case` block), and `PDDA_*` env vars documented but
implemented in no shipped script (`error`). Wired into `pdda.sh run`'s deterministic suite. Companion
`.claude/skills/governance-audit/SKILL.md` runs the check, then reads the doc set for the semantic
contradictions a regex can't prove (conflicting thresholds/ownership claims across docs).

Dogfooding the new check against this repo surfaced two real, pre-existing drifts, both fixed in this
change: `ROUTER.md` and `utils/pdda/PDDA-INSTALL.md` still pointed at
`PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md`, which had since been completed and moved to
`PROJECT/3-COMPLETED/`; and `ROUTER.md`'s command-rails list never mentioned the shipped `gh-refresh`
and `catchup` subcommands. `PROJECT/PDDA.md` still has two known, left-as-flagged findings (`RECAP.md`
and `REAL-AGENT-OBSERVATIONS.md` referenced as if live but absent from the repo) — a content call left
for a human to triage rather than rewritten here.

Verification: new `test/pdda-governance-check.sh` (9/9: dead-ref detection, bare-filename fallback,
GH-doc exemption, orphan-doc, subcommand drift, env-var drift); full existing suite still green
(`pdda-changelog.sh`, `pdda-doc-health-hooks.sh`, `pdda-issue-doc-sync.sh`,
`pdda-publish-projection.sh`); `pdda.sh run` clean end-to-end. Lockstep:
`PROJECT/PDDA.md` § "I. `pdda.sh governance`", `utils/pdda/PDDA-INSTALL.md` (env-var list + Purpose
section), `ROUTER.md` (Command rails).

## 2026-06-30

### install.sh auto-detects the git-pulse repo path for the projection (GH-7)

The multi-device projection silently skipped on any device where git-pulse's sync repo isn't at the
hardcoded default `~/.config/git-pulse/repo` — `publish_registry_projection()` gated on
`[ -d "$PDDA_GITPULSE_DIR/.git" ]` and fail-opened. Observed on `noels-mac-studio`, where git-pulse
keeps its checkout at `~/git-pulse-sync`: every install registered locally but never rolled up.

`publish_registry_projection()` now resolves the git-pulse checkout in priority order: explicit
`PDDA_GITPULSE_DIR` override → `sync_repo_dir` sourced from git-pulse's own `config.sh` (the same file
already sourced for `device_id`) → first existing of `~/.config/git-pulse/repo` or `~/git-pulse-sync`.
The final `[ -d "$gp/.git" ]` gate is unchanged, so it stays best-effort / fail-open, and setting
`PDDA_GITPULSE_DIR` to a nonexistent path still disables it. The top-level default is now empty
(`""` = "auto-detect"); resolution lives in the function's existing config-sourcing subshell.

Verification: `test/pdda-publish-projection.sh` extended with Case 4 (autodetect via `sync_repo_dir`
when no override is given) → 17/17; `bash -n` clean; real-world proof on `noels-mac-studio` — deleting
the projection and running a plain `./install.sh` (no env override) re-published
`~/git-pulse-sync/pdda/registry-noels-mac-studio.tsv`; `pdda.sh run` green for this change. Issue
[#7](https://github.com/Hypercart-Dev-Tools/pdda/issues/7). Lockstep: `install.sh` comment/usage +
`utils/pdda/PDDA-INSTALL.md` step 4c. -> `PROJECT/1-INBOX/GH-7-GITPULSE-PATH-AUTODETECT.md`

### install.sh auto-publishes multi-device PDDA status via git-pulse

Wired Iteration 1 of the multi-device rollup: `install.sh` now has `publish_registry_projection()`, called
from `register_install()` on every successful install/upgrade. When git-pulse (a separate GitHub-backed
activity-sync tool) is present, it writes a **path-normalized** projection of the registry into
`<git-pulse-repo>/pdda/registry-<device>.tsv` — col 1 reduced to the bare repo name, **no absolute paths**,
plus a maintainer-LLM header with exact-then-fuzzy `find` commands to locate a repo on another machine.
git-pulse's own sync carries the file across devices, so PDDA adds no git logic and no new command.

Best-effort and fail-open (GUIDING-PRINCIPLES #6): absent git-pulse it silently skips and the install is
unaffected. The local `~/.config/pdda/registry.tsv` stays the source of truth and keeps absolute paths
(#4) — the projection is one-way, rewritten in full each run, so it can't drift. The projection is written
**temp-then-`mv` (atomic)** so git-pulse's concurrent sync can never publish a half-truncated snapshot, and
a failed generation leaves the prior good projection untouched (mirrors the local registry write; found in a
headless Codex relay review). Location overridable with `PDDA_GITPULSE_DIR`; `--no-register` skips it too.
Lockstep: `install.sh` usage + `utils/pdda/PDDA-INSTALL.md` step 4c.

Verification: new `test/pdda-publish-projection.sh` 14/14 (publish present, normalized/no-path-leak,
local registry intact, fail-open when git-pulse absent, no stray dir, atomic-write preserves prior
projection on failure); `bash -n` clean; `pdda.sh run` green; reviewed end-to-end by Codex via relay-xyz.
-> `PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md`

### `pdda.sh changelog` now accepts semver-style dated headings

`check_changelog` only matched bare `## YYYY-MM-DD` headings, so repos using the common
Keep-a-Changelog style `## [x.y.z] - YYYY-MM-DD` could false-flag as stale by falling through to an
older legacy bare-date heading lower in the file. Fixed the matcher to accept both heading forms while
keeping the existing "first matching heading wins" newest-first assumption, and updated the fallback
warning + contract text to reflect the dual-format behavior.

Added `test/pdda-changelog.sh` to lock the regression down across three cases: semver-only headings,
bare-date-only headings, and a mixed file where the top semver heading must beat a lower legacy bare
date.

Verification: `bash -n utils/pdda/pdda.sh test/pdda-changelog.sh`; `bash test/pdda-changelog.sh`
(7/7); `utils/pdda/pdda.sh changelog` -> `errors=0 warns=0 info=0`.

### pdda-sync `list` now content-aware (reconciles with `status`)

`pdda-sync.sh list` decided its currency column purely on sync-state-file existence, so a target that
`install.sh` had just provisioned (content identical to HQ, but `push` never run) printed `not-yet-pushed`
— implying staleness — while `pdda-sync.sh status` simultaneously hashed the files and reported it
`current=9 behind=0 diverged=0`. The two read-only surfaces contradicted each other for every
just-installed target.

Fix: added a `target_is_current()` helper (hashes each manifest file in the target against HQ; collapses
status's current/behind/diverged to one boolean) and rewrote `cmd_list` to print `current` / `out-of-sync`
with an `(unpushed)` marker when no sync-state file exists yet. A just-installed target now reads
`current (unpushed)` — consistent with `status`, honest that `push` has not adopted it. `status` is
unchanged (it was already authoritative); blast radius is the `list` column only.

Verification: `pdda-sync.sh list` now agrees with `pdda-sync.sh status` for both registered targets
(rebalance-OS, xyz-3-agents-swarm); `pdda.sh run` all checks passed. -> `PROJECT/2-WORKING/SYNC-LIST-STATUS-RECONCILE.md`

## 2026-06-29

### Deterministic issue↔doc sync check + two-tier doc-health hooks (GH-5)

New `pdda.sh issue-doc-sync` flags `PROJECT/2-WORKING/GH-*.md` docs drifted from their GitHub issue
state, both directions: (a) issue CLOSED but the doc still sits in `2-WORKING` → `warn` + a `git mv`
recommendation to `3-COMPLETED`; (b) issue OPEN but the doc's status lead word declares it done →
`warn` to reconcile. Warn-only + flag-only (mirrors `pdda.sh changelog`; never blocks, even in `full`).
gh-degrades: live `gh` → cached `.pdda-gh-state.tsv` (written by the new `pdda.sh gh-refresh`) → an
`info` skip. Anchors (b) on the status lead word so `Active — Phase 0 complete` never false-flags.

Plus a two-tier, warn-only / fail-open doc-health hook system (both always exit `0`, can never block):

- **tier 1 — `pdda-edit-doc-hook.sh` (`PostToolUse`):** fast LOCAL single-file lint of an edited doc
  (`frontmatter`/`status-table`/`hardcoded-paths`/`roadmap-coverage`; `roadmap` for `ROADMAP.md`),
  scoped via the new `PDDA_ONLY_FILE` seam — no network, no `gh`, no LLM.
- **tier 2 — `pdda-stop-doc-health.sh` (`Stop`):** one consolidated system-wide scan per turn (the
  deterministic suite incl. `issue-doc-sync` read from the cached gh-state, so no network call).

Lockstep: `PROJECT/PDDA.md` (check H + Doc-health hooks layer + Stop scan + hourly refresh cadence),
`utils/pdda/PDDA-INSTALL.md` (install set, env vars, chmod), `ROUTER.md` (command rails), `install.sh`
(gitignores `.pdda-gh-state.tsv` in targets). Establishes the repo's first `test/` dir.

- Bet: every drift class is mechanical, so a deterministic warn-only check carries zero false-judgment
  risk; a false flag is one ignorable line, a missed flag leaves today's manual reconciliation — both
  cheap, which is why warn-only/fail-open is the right calibration. Reversibility: **Easy** — additive
  subcommand + hooks + a new test dir + a new `.claude/settings.json`; revert = delete the additions.

Verification: `test/pdda-issue-doc-sync.sh` 13/13 (both directions, gh-absent degrade, never-blocks,
filename fallback); `test/pdda-doc-health-hooks.sh` 18/18 (no-op, warn-but-exit-0, fail-open,
no-network, consolidated report); `pdda.sh run` green; live tree reports no drift; both hooks proven to
always exit `0`. Built in 4 phases, every QA gate green, committed + pushed. Issue #5 (closed).

### `/pdda-eod` skill scaffold

Added the first `SKILL.md` scaffold for the planned `/pdda-eod` end-of-day wrap, at the user-requested
path `SKILLS/PDDA-EOD/SKILL.md`.

- Encodes the GH-6 runtime order as an operator workflow: gather read-only state, reconcile project
  docs, reconcile `ROADMAP.md` and `CHANGELOG.md`, write the dated EOD summary before the final
  commit, then push and optionally close user-verified issues.
- Keeps the skill intentionally thin: guardrails, command rails, confirmation model, and degradation
  behavior when `gh` is unavailable. The detailed design remains in
  `PROJECT/2-WORKING/GH-6-PDDA-EOD.md` rather than being duplicated into the skill.
- Bet: a lean skill file is enough to make `/pdda-eod` usable without creating a second source of
  truth. Reversibility: **Easy** — one new skill file and a changelog entry.

Verification: reviewed against `PROJECT/2-WORKING/GH-6-PDDA-EOD.md`, `ROUTER.md`, and the existing
`.claude/skills/pdda/SKILL.md` pattern; `utils/pdda/pdda.sh changelog` reports clean for this
doc-only iteration.

### PDDA sync/push system (HQ → registered targets)

Built the steady-state distribution layer the registry foundation was for: `utils/pdda/pdda-sync.sh`
keeps the PDDA runtime current across several repos from one canonical source ("HQ" = this clone),
on-demand. Realigned + Codex relay-approved (4 rounds), then built phase-by-phase with a QA gate per
phase.

- **Auto-regenerated manifest** (`utils/pdda/pdda-sync-manifest.conf` + `pdda-manifest.sh`), shared
  with `install.sh` so the install set == the push set by construction; new files/folders under
  `utils/pdda/` propagate with no list edit. (Phase 1, QA 8/8.)
- **`push` engine** — content-hash state-stamp table (new/updated/updated+bak/skip; local target edits
  preserved between releases), delete-mirror (backup-then-delete for HQ-side removals), a
  manifest-poisoning guard (zero-root / empty / shrink > `PDDA_SYNC_MAX_SHRINK`% + `--force-delete`),
  atomic temp-then-`mv`, backups + retention, mkdir lock, dirty-source guard, `--dry-run`/`--no-delete`.
  (Phase 2, QA 26/26.)
- **`register`/`list`/`status`/`remove`/`prune`** — `register` delegates the copy + registry write to
  `install.sh` (single writer) then seeds sync state so the next push is all-skip; confirms unless
  `--yes`. (Phase 3, QA 17/17.)
- **Optional launchd wrapper** — `install-agent`/`uninstall-agent` (30-min `push` over the whole
  registry); the live daemon is opt-in. (Phase 4, QA 11/11.)
- State lives under gitignored `temp/`; the registry stays machine-local under
  `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/`. Docs: `utils/pdda/PDDA-INSTALL.md` + `ROUTER.md`.

Verification: per-phase QA gates green; end-to-end dogfood (register → push → source bump → source
delete) propagates with backups intact and no clobbered local edits. See
`PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md`.

### `install.sh`: per-user install registry (sync foundation)

`install.sh` now records every install/upgrade in a machine-local registry so a future sync layer
knows where each copy of the PDDA runtime lives — the registry only, no sync yet (deliberate).

- **Location:** `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv`. Per-user, per-device, lives in
  `$HOME` (not the repo), so it can't leak into the eventually-public repo and survives the temp-clone
  upgrade flow. Override with `PDDA_REGISTRY`; skip with `--no-register`. `.config/` also gitignored
  defensively.
- **Schema (sync-ready):** one tab-delimited row per target —
  `target · last_install_utc · mode · source_commit · startup_docs`, latest-wins dedup on the path.
  `source_commit` is the field a later sync uses to tell which targets are behind, so no schema change
  is needed when the sync project starts.
- Best-effort: a registry-write failure never fails the install. `PDDA-INSTALL.md` updated in lockstep;
  the sync plan doc records the registry as shipped (its Phase 1 registry slice).

Verification: `bash -n` clean; tested fresh write, latest-wins dedup on re-install, `--no-register`,
and a custom `PDDA_REGISTRY` path; `source_commit` recorded from the source clone's HEAD.

### `install.sh`: hardening from an Agy review relay

Drove `install.sh` through a headless Agy review relay; landed all three findings (2 blockers + 1 nit),
each re-tested.

- **Git detection handles worktrees/submodules.** `is_git_repo()` now uses
  `git rev-parse --is-inside-work-tree` instead of testing for a literal `.git` *directory* — in a
  worktree/submodule `.git` is a FILE, so the old check silently skipped untracking
  `PROJECT/PDDA-ACTIVITY.jsonl`. Verified in a real `git worktree`.
- **Migration repointing is scoped and bounded.** Candidate files come from `git ls-files` (tracked
  only — no scanning untracked `node_modules`/`.venv`), with a pruned `find` fallback for non-git
  targets; `utils/ node_modules/ .venv/ vendor/ CHANGELOG.md *.jsonl` are skipped by path so even a
  *tracked* dependency dir is never rewritten, and only files that actually contain an old path are
  edited.
- **Verify-failure message is mode-aware** (was hardcoded to "observe mode"; now reflects light/full).

Verification: `bash -n` clean; re-tested flat-layout migration (real refs repointed, tracked
`node_modules` untouched, target's own `utils/` intact) and the git-worktree untrack path.

## 2026-06-28

### `install.sh`: auto-migrate flat layout + gitignore the activity log

Made `install.sh` a true upgrader, not just a first-time installer, so re-running it on an older or
drifted target converges to the canonical state instead of leaving duplicates and noise.

- **Auto-migration of pre-`utils/pdda/` (flat) installs.** Older targets kept the runtime flat under
  `utils/` (`utils/pdda.sh`, `utils/pdda-lib.sh`, …). A plain re-install used to *add* the new
  `utils/pdda/` subfolder beside the flat files, leaving two copies and an ambiguous source of truth.
  `install.sh` now detects the flat entry point and migrates: removes the duplicate PDDA-owned flat
  files (+ legacy `utils/pdda-phase-out/`, root `PDDA-INSTALL.md`) and repoints old-path references
  (`utils/pdda.sh` → `utils/pdda/pdda.sh`, etc.) in tracked docs. Never touches the target's own
  `utils/` files or the dated CHANGELOG; idempotent; `--no-migrate` opts out.
- **Activity log is gitignored.** `PROJECT/PDDA-ACTIVITY.jsonl` is churning runtime state, so a fresh
  install now adds it to the target's `.gitignore`, and an upgrade of a repo that already committed it
  appends the entry *and* `git rm --cached`s it. Idempotent (no duplicate lines; clean append even when
  the existing `.gitignore` lacks a trailing newline).
- **Portable in-place edits.** The doc-repointing writes its temp file beside the target (no `$TMPDIR`
  dependency, same-filesystem atomic `mv`) — fixing a `set -e` abort when the system temp dir is
  unwritable. `utils/pdda/PDDA-INSTALL.md` updated in lockstep (migration spec + gitignore step).

Verification: `bash -n install.sh` clean; migration tested against a throwaway flat-layout repo
(flat files removed, repo's own `utils/` file kept, `ROUTER.md` repointed, already-correct paths and
`CHANGELOG.md` untouched, idempotent on re-run); gitignore tested across fresh / already-tracked /
no-trailing-newline / re-run cases.

## 2026-06-27

### Runtime relocated to `utils/pdda/` subfolder

Moved the shipped runtime (`pdda.sh`, `pdda-lib.sh`, `pdda-doc-ready.sh`, `pdda-catchup.sh`) and the
install manifest into a dedicated `utils/pdda/` subfolder so it never mixes with a target repo's own
`utils/` files on install.

- **One real code fix: repo-root resolution.** `pdda-lib.sh` derived `PDDA_REPO_ROOT` as
  `$PDDA_LIB_DIR/..`, which assumed the runtime sat directly under `utils/`. With the scripts now one
  level deeper, that resolved the root to `utils/` — so every check scanned an empty `utils/PROJECT/**`
  and *vacuously passed*, and the activity log was written to `utils/PROJECT/`. Fixed to `../..`. This
  was the load-bearing change; without it the relocation silently breaks every install.
- **Inter-script sourcing needed no change** — it already resolves via `$(dirname "$0")`/`BASH_SOURCE`,
  so co-locating the files keeps `run`/`doc-ready`/`catchup` wiring intact. `shellcheck source=` hints
  were repathed.
- **All path-prefixed references repathed in lockstep** — `install.sh` (copy + chmod + messages),
  `utils/pdda/PDDA-INSTALL.md` (canonical set, create paths, chmod, verification), `ROUTER.md`,
  `AGENTS.md`, `README.md`, `PROJECT/PDDA.md`, `ROADMAP.md` banner, the active install-script working
  doc, and the `/pdda` skill (repo-local + global). Bare subcommand mentions (`pdda.sh frontmatter`)
  were left as-is — they name commands, not file paths.
- **Fixed a pre-existing lockstep gap:** `install.sh` and `PDDA-INSTALL.md` did not ship
  `pdda-catchup.sh`, so the `catchup` subcommand would have failed in target repos. It's now part of
  the copied runtime + chmod set.
- Historical CHANGELOG entries keep their original `utils/pdda.sh` paths — they are a dated record of
  what was true at the time, not live references.

Verification: `bash -n` clean on `install.sh` + all four scripts; `./utils/pdda/pdda.sh run` from the
repo root correctly re-detects `PROJECT/2-WORKING` (the dogfood `BLANK.md` findings reappeared,
confirming root resolution) and writes to the real `PROJECT/PDDA-ACTIVITY.jsonl`, with no stray
`utils/PROJECT/`. End-to-end `install.sh [--with-startup-docs]` into throwaway repos confirmed the
runtime lands in `utils/pdda/`, the `/pdda` skill ships, the target root resolves correctly (activity
log at target `PROJECT/`, no `utils/PROJECT/`), and both `pdda.sh run` and `pdda.sh catchup` work.

### `pdda.sh catchup` — LLM repo triage with ROUTER.md recommendations

New opt-in subcommand that reviews recent repo activity against `ROUTER.md` and proposes concrete
MOVE / DELETE / ADD edits to the routing guide.

- **`pdda-catchup.sh`** mirrors the existing `pdda-doc-ready.sh` pattern: sources `pdda-lib.sh`,
  skips gracefully (emits an `info` finding, exits 0) when `PDDA_LLM_BIN` is unset, and stays fully
  read-only/advisory. Gathers `ROUTER.md`, the top of `CHANGELOG.md`, recent commits, and inbox issue
  titles, then hands them to the configured model CLI.
- **Wired into `pdda.sh`** as `catchup) exec pdda-catchup.sh` plus a usage line — the thin-router
  convention (LLM subcommands live in their own `pdda-*.sh` script).
- **Fails loudly, not silently.** The model CLI's stderr flows to the terminal and a non-zero exit
  records a `warn` finding (was previously swallowed by `2>/dev/null || true`). The prompt is fed on
  stdin (portable across CLIs, immune to `ARG_MAX`), inbox context includes each issue's first
  heading, and recommendations are persisted to `PROJECT/4-MISC/pdda-catchup-<date>.md`.

Verification: `bash -n utils/pdda-catchup.sh` clean; skip, failure (`PDDA_LLM_BIN=false`), and success
(stub CLI) paths all exercised — failure surfaces a WARN, success writes the dated recommendations file.

### Agent startup: imperative AGENTS.md trigger + `/pdda` re-orient skill

Closed the gap between the auto-loaded `AGENTS.md` and the `ROUTER.md` startup sequence, and added a
thin re-orientation lever for mid-session inflection points.

- **Imperative startup directive.** `AGENTS.md` (which agent harnesses auto-load) now *instructs* the
  agent to follow the `ROUTER.md` startup sequence on first action, rather than only pointing at it.
  This makes the read-order self-executing without the user typing "read ROUTER.md", and needs no new
  surface — the harness already loads the file.
- **`/pdda` skill (`.claude/skills/pdda/SKILL.md`).** A deliberately dumb read-and-report pass for the
  one case the auto-load can't cover: explicit re-orientation on task switch, resume, post-compact, or
  context drift. It walks `ROUTER.md`, names the next canonical file, and runs `pdda.sh run` for state.
  It re-specifies no contract — points at where each fact lives.
- **Ships via `--with-startup-docs`.** Bundled with `ROUTER.md`/`AGENTS.md` (it's only useful when
  those exist in the target), so no new installer flag. `install.sh`, `utils/PDDA-INSTALL.md`, and the
  `ROUTER.md` routing hints updated in lockstep.

Verification: `bash -n install.sh` clean; `./utils/pdda.sh run` green (pre-existing BLANK.md dogfood
findings only, non-blocking in observe); end-to-end `install.sh --with-startup-docs` into a temp repo
confirmed `ROUTER.md`, `AGENTS.md`, and `.claude/skills/pdda/SKILL.md` all land in the target.

## 2026-06-26

### Triage ratings for medium-large work (effort / complexity / risk / phases)

Added four frontmatter triage fields so automation can select *which* task to pursue without
re-reading every plan: `effort`, `complexity`, `risk` (integers 1–5) and `phases` (positive integer).
Required for medium-large tasks/projects; trivial docs are exempt.

- **No stored composite score.** The combined "easiness" signal is **derived at selection time**, not
  persisted — a frozen aggregate would drift from its components (violating Principle #4, one canonical
  place per fact) and bake in a weighting that couldn't be re-tuned without rewriting docs. PDDA.md
  documents the reference rule: `risk` is a hard safety **gate** (`risk <= 2` eligible; `>= 4` ⇒
  human), `effort + complexity` is the ease axis (they correlate, so summed as one size proxy), with
  `phases` as the tiebreak.
- **Split enforcement.** `pdda.sh frontmatter` now validates the rating *values* when present (1–5
  range; phases a positive int) — unambiguous, so blocking-capable. *Presence* on a medium-large doc is
  a judgment, so it's flagged by the warn-capped LLM layer (`pdda-doc-ready.sh`), never a regex.
- Supersedes the previously-proposed single `priority` scalar; added to the GH-issue-intake minimum
  frontmatter for medium-large captures so the queue can be triaged before promotion.

Verification: `./utils/pdda.sh run` green; new validator unit-checked against good/bad rating docs via
`PDDA_WORKING_DIR` (4 range errors on bad values, clean on valid 1–5).

## 2026-06-25

### Plan contract: TOC + discovery/spike write-back

Extended the active-doc contract in `PROJECT/PDDA.md` with two governance clauses, and wired both into
the LLM readiness rubric. No change to the deterministic checks or the install surface.

- **Table of contents** is now a required contract item for *multi-phase* plans (item 4): a
  `## Table of contents` listing each phase, so a cold agent sees the full phase span and jumps to the
  live one without scrolling. Added to the readiness rubric and the automation-ready checklist.
- **Discovery & spike phases** get a new dedicated contract section: a phase tagged discovery/spike
  must write its findings (what was investigated, what was found with `file:line` pointers, what it
  changes for later phases) **back into the originating plan doc** before its QA gate can pass. Grounded
  in Principle #1 (docs are runtime state) and #4 (one canonical place per fact) — a spike whose
  findings live only in chat is the exact drift PDDA exists to prevent.
- **Enforcement is advisory (LLM layer, warn-capped).** `pdda-doc-ready.sh` now flags a multi-phase
  plan with no TOC and a discovery/spike phase whose findings were not written back. "Did the agent
  actually capture what it learned" is a judgment a regex cannot make honestly, so it stays with the
  reviewer and never blocks a build — consistent with how QA-gate readiness is already enforced.

Verification: `./utils/pdda.sh run` green in this repo (deterministic checks unaffected; the LLM layer
self-skips when no `PDDA_LLM_BIN` is configured).

## 2026-06-25

### Root `install.sh` + operator onboarding

Added a repo-root `install.sh` that installs the PDDA surface into a *foreign* repo in a clean,
ready-to-use zero state, and rewrote `README.md` to lead with operator onboarding.

- `install.sh` is the executable form of `utils/PDDA-INSTALL.md`: it copies the canonical-4 runtime
  (`utils/pdda.sh`, `utils/pdda-lib.sh`, `utils/pdda-doc-ready.sh`, `PROJECT/PDDA.md`), creates the
  `PROJECT/**` lifecycle tree, and **synthesizes blank seed** `ROADMAP.md` / `CHANGELOG.md` /
  `PROJECT/PDDA-ACTIVITY.jsonl` / `.pdda-mode` — it never copies this repo's own ledger/history into a
  target. It `chmod`s the scripts and runs `pdda.sh run` as a post-install smoke test.
- Idempotent: runtime + contract are refreshed on re-run, but existing seeds and real `PROJECT/**`
  docs are kept unless `--force`. Flags: `--force`, `--with-startup-docs`, `--mode observe|light|full`.
  Refuses to target the pdda source repo itself.
- This repo stays a **live dogfood demo**: its own `ROADMAP.md` / `CHANGELOG.md` / `PROJECT/**` are
  not zeroed; only target repos start blank. This change was itself tracked via a `PROJECT/2-WORKING`
  doc + a ROADMAP pointer (the issue-first GitHub step is deferred until `gh` auth is restored).
- Lockstep doc updates: `utils/PDDA-INSTALL.md` (new "Fastest path: install.sh" section) and
  `ROUTER.md` (canonical-files list + routing hint).

Verification: `./install.sh <throwaway-target>` → target `pdda.sh run` exits 0 (fresh + idempotent
re-run + `--force`/`--with-startup-docs`/`--mode` exercised); `./utils/pdda.sh run` green in this repo.

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
