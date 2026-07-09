---
title: Audit & fix registry-to-git-pulse-sync projection drift
status: Active — Phases 0-2 complete (code + tests + docs landed); one non-code follow-up remains (operator's stalled git-pulse checkout)
created: 2026-07-09
updated: 2026-07-09
owner: noel
gh_issue: 28
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/28
branch: gh-28-registry-projection-drift
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 2
ratings_provisional: false
context_tags: [governance, install.sh, git-pulse, multi-device, observability]
non_goals:
  - A continuous/live sync daemon or filesystem watcher for the registry
  - Changing git-pulse's own sync/push mechanics — only PDDA's write into its pdda/ directory is in scope
  - Reworking the registry's TSV format/schema
  - Fixing or automating the operator's stalled ~/.config/git-pulse/repo checkout itself — that's the
    operator's own tooling to unstick, not a PDDA code change
related:
  - GH-23-AGENT-ONRAMP.md
goal: >
  publish_registry_projection() already writes an accurate, full mirror of the local registry into the
  git-pulse checkout on every install. Phase 0 found the real gap is silent: it never reports when that
  checkout isn't actually reaching origin (dirty or behind). Make it say so, best-effort, without
  touching git-pulse's own sync/push mechanics.
---

# GH-28 — Audit & fix registry-to-git-pulse-sync projection drift

## Status

| What was just completed | What's next |
|---|---|
| All three phases landed in one pass: Phase 0 found the real bug wasn't `install.sh` (its write logic was already correct) but a silent gap — the git-pulse checkout it targets can be dirty/behind and it never says so. Phase 1 added `warn_stale_projection_destination()` + 4 new test cases in the existing `test/pdda-publish-projection.sh` (21/21 passing). Phase 2 documented it in `PDDA-INSTALL.md` and `install.sh --help`. `utils/pdda/pdda.sh run` is clean. | The one item this repo can't fix: `~/.config/git-pulse/repo` on the reporting operator's machine needs a manual commit + push to actually deliver its 5 pending rows, and whatever job last touched it (2026-07-02) needs checking — that's the operator's own git-pulse tooling, tracked as a follow-up, not a blocker on closing this issue. |

## Table of contents
- [Phase 0 — Explore & scope](#phase-0--explore--scope) — complete
- [Phase 1 — Warn on stale/dirty projection destination](#phase-1--warn-on-staledirty-projection-destination)
- [Phase 2 — Docs + operator remediation](#phase-2--docs--operator-remediation)

## Key concepts
- `publish_registry_projection()` (install.sh) only fires from inside `register_install()`, itself only
  reachable via an `install.sh` run — there's no standalone/periodic trigger, so any registry write
  outside that flow won't refresh the mirror. This part works as designed.
- The projection is deliberately fail-open/best-effort (silently skipped if no git-pulse checkout is
  detected) — but "detected and written" and "actually reaches origin" are two different things, and
  only the first is checked. That's the real gap (see Phase 0 findings).
- Resolved: `~/.config/git-pulse/repo/pdda/registry-noels-mbp-16-m1-pro.tsv` (the checkout PDDA
  actually targets) is fully accurate. A second, unrelated clone at `~/git-pulse-sync` — which is
  *not* what PDDA writes to — is what looked stale when first inspected; that was mine to correct, not
  a PDDA defect.

## Idea
Audit how PDDA publishes its per-device registry projection to Git Pulse Sync. Original problem
statement: the git-pulse-sync/pdda/registry-<device>.tsv projection is supposed to be a full rewrite
mirror of the local ~/.config/pdda/registry.tsv on every install, but appeared stale — missing rows
that existed locally. Phase 0 found the premise needed correcting (see findings): the write logic is
fine; the destination checkout's own commit/push pipeline is what's stalled, silently.

## Why
The local registry is the source of truth for "which repos have PDDA installed on this device," but
it's machine-local by design and never committed. The git-pulse projection is the *only* mechanism that
carries that state across the operator's three devices. If PDDA writes an accurate file but the
checkout holding it never reaches origin, every cross-device decision built on the projection (e.g. "is
repo X governed on device Y?") is silently wrong — and nothing today tells the operator that's
happening. TODO(operator): confirm whether the other two devices have their own git-pulse checkout
split the same way, or if this is specific to this machine.

## Phase 0 — Explore & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Findings (2026-07-09)

**The premise was wrong. `install.sh`'s write-side logic is not the bug.** Tracing
`publish_registry_projection()` (install.sh) against this machine's real git-pulse setup surfaced a
different, more interesting root cause:

- This machine has **two separate clones of the same git-pulse remote**
  (`Hypercart-Dev-Tools/rebalance-git-pulse.git`):
  - `~/.config/git-pulse/repo` — the checkout `~/.config/git-pulse/config.sh`'s `sync_repo_dir` actually
    names, and the same path `~/bin/git-pulse` (the real automation, driven by
    `~/Library/LaunchAgents/com.user.git-pulse.plist`) resolves to by its own default
    (`sync_repo_dir:=$CONFIG_DIR/repo`). This is the canonical one.
  - `~/git-pulse-sync` — an independent second clone of the same remote, current with `origin/main`,
    with unrelated fresh commits (device metadata, daily pulse updates). This is the path I originally
    (and wrongly) inspected when I reported the projection as "stale."
- `install.sh`'s auto-detect (`publish_registry_projection`, install.sh ~L400) checks git-pulse's own
  `sync_repo_dir` **first**, falling back to `$HOME/git-pulse-sync` only if that's absent. Since
  `~/.config/git-pulse/repo` exists and has a `.git`, detection always resolves there — correctly, per
  git-pulse's own config — and never reaches the fallback candidate.
- **The projection at `~/.config/git-pulse/repo/pdda/registry-noels-mbp-16-m1-pro.tsv` is fully
  accurate** — it has every row the local `~/.config/pdda/registry.tsv` ever had, written in full on
  every install exactly as designed. `install.sh`'s write-side logic has no bug.
- The actual problem: `~/.config/git-pulse/repo` is **650 commits behind `origin/main`**, and the 5
  rows PDDA correctly wrote (`install-smoke`, `KISS-woo-fast-search`, `frontdoor-target`,
  `frontdoor-target2`, `test-repo`) sit as an **uncommitted, unpushed local diff** — confirmed via
  `git diff --stat pdda/` (5 insertions) against the last real commit there, `f438183`
  (2026-06-30 15:00:22, the same moment the 2-row baseline was captured). Whatever job is supposed to
  commit-and-push git-pulse's own sync repo has not run against this checkout since **2026-07-02**
  (its `last-run` timestamp), 8 days before this audit.
- Net effect: PDDA writes an accurate file to disk on every install. It never reaches GitHub, and
  therefore never reaches the other two devices, because **git-pulse's own commit/push pipeline is
  stalled on the checkout PDDA correctly targets** — a problem entirely outside `install.sh`'s write
  path.

**Reframed scope.** This is not an `install.sh` correctness bug; it's a silent-failure/observability
gap. `publish_registry_projection()` writes the file and returns success — it has no way to know (or
say) that the destination checkout isn't actually being synced to origin. Per the house lesson from
GH-27: *a check that cannot verify its effect must not report success.* The fix belongs on the
"say something" side, not the "do more" side — and should NOT extend into fixing or automating
git-pulse's own commit/push flow (still a non-goal below; that's the operator's tooling, not PDDA's).

### Checklist
- [x] Ground the idea in the real code/trace it touches (not the abstract) — traced end-to-end against
  live state on this device; root cause confirmed, not hypothesized.
- [x] Name the concrete deliverable + its write-set — `install.sh` only:
  `publish_registry_projection()` gains a post-write check (`git -C "$gp" status --short -- pdda/` and
  an ahead/behind check against `origin/main`, best-effort/fail-open) that prints a `say` warning when
  the projection file is dirty or the checkout is stale, so drift like this surfaces on the very next
  install instead of sitting invisible for over a week.
- [x] Decide the tool shape — extend the existing `publish_registry_projection()` function; no new
  script, subcommand, or daemon.
- [x] Set/correct the triage ratings — lowered: this is now a small, well-understood diagnostic addition
  to one existing function, not an open-ended audit. `ratings_provisional` cleared below.

### QA checklist — Phase 0
- [x] The scope is grounded in real code/history, not a hypothetical
- [x] Composes with existing commands rather than adding a parallel path
- [x] A human checkpoint remains before anything fires

## Phase 1 — Warn on stale/dirty projection destination
- [x] Added `warn_stale_projection_destination()` (install.sh), called from `publish_registry_projection()`
  right after `write_registry_projection` succeeds. Best-effort, never fetches (no network call on every
  install — "behind" is only as fresh as the checkout's own last fetch/pull): warns when `$gp` has
  uncommitted changes under `pdda/`, and separately warns when `$gp` is behind its configured upstream.
  Never fails the install (same fail-open posture as the rest of the function).
- [x] Extended the existing `test/pdda-publish-projection.sh` (found it already owns this area — reused
  it rather than adding a parallel test file) with cases 5-8: dirty destination warns, clean-after-commit
  is silent (negative control, checked via the function directly to avoid the confound of a second
  `install.sh` run re-registering with a fresh timestamp and genuinely re-dirtying the file), behind
  destination warns, and install still completes regardless. 21/21 passing, no regressions in the other
  17 pre-existing cases.

### QA checklist — Phase 1
- [x] Negative control included (clean checkout → silent, matching today's behavior)
- [x] Never blocks the install — warning only, install still exits per its own mode logic
- [x] Doesn't touch git-pulse's own config, commit, or push behavior

## Phase 2 — Docs + operator remediation
- [x] Documented the two-checkout hazard and the new warning in `utils/pdda/PDDA-INSTALL.md` (step 4c)
  and `install.sh --help`, alongside the existing projection documentation.
- [ ] Flag to the operator (outside this repo) that `~/.config/git-pulse/repo` needs a manual
  commit + push to actually deliver the 5 pending rows, and that whatever job last ran there on
  2026-07-02 needs checking — tracked as a follow-up, not part of this PDDA fix. **Not done as a file
  edit** — that checkout belongs to the operator's own git-pulse tooling, not this repo; surfaced
  directly to the operator instead (see PR description).

### QA checklist — Phase 2
- [x] CHANGELOG.md updated per `PROJECT/PDDA.md`
- [x] `utils/pdda/pdda.sh run` clean
