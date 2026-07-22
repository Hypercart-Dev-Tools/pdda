---
title: Multi-repository Cactus Sentinel deployment
status: Active — deployment specification written; Phase 0 inventory and issue capture next
created: 2026-07-21
updated: 2026-07-21
owner: noel
gh_issue: pending — open before implementation; rename to GH-<n>-MULTI-REPO-CACTUS-SENTINEL-DEPLOYMENT.md then
doc_type: project
goal: >
  Deploy Cactus Sentinel as an explicit, per-repository observer for PDDA-managed repositories. Each
  target receives isolated watching, logs, mode selection, and rollback; shared local model services
  may be reused, but no target's documents or enforcement state leak into another target. Begin with
  observe-and-log, graduate per target through light to full only with measured evidence, and keep
  all Sentinel write automation out of this deployment.
related:
  - PROJECT/2-WORKING/GH-10-SENTINEL.md
  - PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md
  - PROJECT/PDDA.md
  - utils/pdda/pdda-sync.sh
non_goals:
  - Shipping the Cactus watcher, router, or model runtime in the PDDA installer before the deployment proves portable.
  - A single daemon recursively watching an arbitrary parent directory or auto-enrolling repositories.
  - Sentinel-authored file changes, commits, pull requests, or cross-repository sync in this effort.
  - Training on raw target-repository documents without a target-level, human-approved data-sharing decision.
effort: 3
complexity: 3
risk: 3
phases: 6
context_tags: [sentinel, cactus, multi-repo, enforcement, learning-loop]
---

# Multi-repository Cactus Sentinel deployment

## Status

| What was just completed | What's next |
|---|---|
| Deployment contract authored from the existing PDDA mode ladder, the completed PDDA runtime-sync design, and the live Cactus observer/router shape. It deliberately separates repository observation from Sentinel write automation and model training. | **Phase 0:** open the implementation issue, inventory candidate repositories, and select the first two explicit opt-in targets; do not install or enable another watcher yet. |

## Quad Concepts

- One shared local model stack must not turn into one shared repository boundary → run one explicitly configured watcher per target and keep target logs/state separate.
- “Full” after a file change cannot prevent that change → pair strict enforcement with a target CI or pre-commit gate, while the watcher remains evidence and routing only.
- More observations do not automatically justify more training data → harvest only approved, provenance-tagged feedback and promote checkpoints only on held-out evaluation.

## Preflight contract

- **The bet.** A small number of explicitly enrolled PDDA repositories can share Cactus's local
  router/model services while preserving independent `PROJECT/**` state, activity logs, and mode
  decisions. The first useful outcome is dependable evidence about documentation drift, not automatic
  remediation. If an observer is noisy, costly, or cannot prove isolation, it is removed and that
  repository stays on ordinary `pdda.sh run` rails.
- **Assumptions.** A target has a working PDDA install (`utils/pdda/pdda.sh`, `PROJECT/`, and a
  repo-root `.pdda-mode`), and the local Cactus router is optional: a router outage must degrade to
  deterministic PDDA checks plus the configured review fallback, never to a skipped audit. Cactus is
  an external integration owner; this repo owns only PDDA's contract and any eventual install surface.
- **Reversibility: Easy.** Each target is one independent LaunchAgent/configuration entry. Disable or
  unload that entry and delete only its target-local generated log/dashboard; no target project files,
  commits, or model checkpoint are changed by observe/light deployment.
- **Blast radius.** At most one opted-in repository per daemon. A broken daemon, stale mode, or noisy
  model result cannot change another repository's exit status, activity log, or documents. Sharing a
  localhost router is an availability dependency, not shared control-plane state.

## What already exists—and what does not

This repository already has a completed distribution plan for the **PDDA runtime**:
[`PDDA-SYNC-TO-OTHER-REPOS.md`](../3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md) defines registration and
push-based updates for `utils/pdda/` plus the PDDA contract. It intentionally does not deploy Cactus
Sentinel, LaunchAgents, local models, or multi-target watcher configuration.

The active [GH-10 Sentinel plan](GH-10-SENTINEL.md) defines a separate PDDA-native, merge-triggered
recommend → worktree → gate → PR/trust progression. It is not the current always-on Cactus watcher
and its Phase 3 replay/evaluation harness remains the next planned step. This document therefore does
not redefine GH-10; it defines how an external Cactus observer can be safely trialed across PDDA
targets without making that observer part of the installer prematurely.

## Deployment topology

```text
target repo A/PROJECT/**/*.md ─┐      ┌─ target A activity log + dashboard
                               ├─ A watcher ─┐
target repo B/PROJECT/**/*.md ─┘             ├─ shared local router/model services
                                             │
                               ┌─ B watcher ─┘
                               └─ target B activity log + dashboard
```

### Per-target isolation contract

For each enrolled repository, create a **separate** watcher invocation with:

- an explicit repository-root argument—not discovery by parent directory, glob, or current shell cwd;
- a unique LaunchAgent label and separate stdout/stderr log paths;
- that target's own `PROJECT/PDDA-ACTIVITY.jsonl` and generated status/dashboard paths;
- that target's `.pdda-mode` as the only mode source (unless a one-off `PDDA_MODE` override is recorded
  in the invocation); and
- a target-local kill switch. Disabling one target must not disable the shared router or another
  target's watcher.

The first rollout uses the existing Cactus watcher shape: watch eligible Markdown under a single
target's `PROJECT/`, run the target's deterministic PDDA checks, then request a route/review from local
services. The shared router endpoint is advisory. Its returned mode must never override the target's
own mode; deterministic findings and the target's mode remain authoritative.

Do **not** extend one daemon to accept an unbounded repository list in Phase 1. Independent processes
make ownership, logs, disablement, and failure recovery obvious. A later supervisor is allowed only if
the first two target deployments demonstrate repeated operational pain that independent agents cannot
solve.

## Observe, light, and strict/full enforcement

Use PDDA's existing three-mode ladder; do not invent a parallel Sentinel mode vocabulary.

| Target mode | Sentinel behavior | Enforcement meaning | Promotion evidence |
|---|---|---|---|
| `observe` | Check changed eligible docs; append findings, route/review provenance, skips, and service health to the target's activity log/dashboard. | Never blocks. No file mutation, PR, or notification escalation is implied. | A representative observation window has no cross-target writes, no unrecoverable daemon failure, and findings are intelligible to the owner. |
| `light` | Same evidence collection, with visible actionable warnings/notifications for repeated or high-value findings. | Still non-blocking; warnings must not be reported as a clean pass. | Owners have resolved or deliberately held the recurring debt, and light findings have a known review/triage path. |
| `full` | Run the same checks and preserve the complete evidence trail. | `error` findings are non-zero **only where the caller can enforce them**: target CI, a pre-commit/pre-push hook, or a merge gate. The post-change watcher records and surfaces failure but cannot retroactively block an edit. | The target has an installed, owner-approved enforcement point; its backlog is understood; and a rollback to `light` has been tested. |

Every mode is read-only with respect to repository content. `full` means strict **status enforcement**,
not permission for Sentinel to edit documents. Any later write/PR capability must follow GH-10's
worktree, allowlist, deterministic-gate, and trust model—and needs its own explicit approval.

## Required run record

Every watcher event must be attributable to one target and state what actually happened. The target's
activity log record (or an adjacent daemon log record keyed to it) must include:

- target repository identifier and the changed repo-relative path;
- resolved target mode and whether it was file-derived or an explicitly logged override;
- deterministic PDDA finding counts/check identifiers, never only a gated process exit code;
- router/reviewer availability, selected route, and fallback reason when unavailable;
- start/end timestamp, duration, daemon version/config identity, and a skip reason where applicable;
- a non-sensitive content identity (commit SHA or bounded hash), rather than copying full document text
  into a shared operational log.

An aggregate dashboard may summarize these target-local records, but must remain read-only and show
per-target counts. It may not silently merge or train on raw target content.

## Cactus learning loop and its boundary

There **is** a Cactus learning-loop direction. The live router is a finetuned Needle checkpoint, and
the Cactus workspace includes disagreement harvesting plus replay/evaluation work. Its active flywheel
work has identified a material limitation: correction-only fuel is heavily biased toward out-of-
distribution errors; correct examples and per-route reliability weighting are planned improvements.

GH-10 has a complementary, but distinct, learning loop: Phase 3 replays recent history and receives
one-time human accept/reject/serious-miss labels; Phase 5 derives per-category trust from real PR
outcomes. Neither loop is complete authorization for autonomous changes.

For multi-repository deployment, the learning boundary is:

1. **Collect observations first.** Observe logs are operational telemetry, not training data.
2. **Obtain target-level consent.** A repository must explicitly opt in before any sampled route,
   reviewer result, or human correction may enter a training/evaluation set.
3. **Minimize and tag.** Store only the bounded features/labels needed for routing, tagged by source
   target and policy version. Do not centralize document bodies, secrets, issue text, or user data.
4. **Evaluate by target.** Hold out data from every opted-in target. A candidate checkpoint must not
   regress aggregate quality or any target's agreed safety-sensitive category.
5. **Promote by human decision.** Publish the evaluation, retain the prior checkpoint, and require an
   operator approval to serve a candidate. A failed evaluation is a logged non-deployment, not a reason
   to lower enforcement or change target modes.

## Phased delivery

### Phase 0 — Issue, target inventory, and preflight

- Open the implementation issue and rename this document to its `GH-<n>-` form.
- List candidate repositories and verify each has a PDDA install, a writable target-local activity log,
  an owner, and an explicit opt-in decision.
- Confirm the Cactus observer's fallback behavior when router/model services are unavailable.

**QA gate:** two named targets have signed off on observation; no LaunchAgent or target mode has changed;
the Phase 1 target and its rollback command are documented in the issue/doc status.

### Phase 1 — First target in observe-and-log

- Install one isolated watcher for the PDDA source repository or another explicitly approved pilot.
- Set the target to `observe`; record one controlled doc edit and one router-unavailable fallback.
- Verify the process reads only that target and writes only its allowed runtime logs/dashboard.

**QA gate:** the target's log shows complete run records, `pdda.sh run` findings are accurately reflected,
the target tree is unchanged except for its declared runtime output, and unloading the agent stops work.

### Phase 2 — Second target and isolation proof

- Enroll a second opt-in PDDA repository using a distinct agent, label, and log paths.
- Exercise simultaneous changes in both repositories and disable one agent while leaving the other live.

**QA gate:** no event, mode, activity record, or dashboard entry crosses target boundaries; a failure or
disablement in one target has no effect on the other.

### Phase 3 — Light-mode triage

- Promote only targets with a documented observation review to `light`.
- Define the recipient/channel for actionable warnings and an owner response SLA; retain the exact
  non-blocking semantics of PDDA light mode.

**QA gate:** warnings are visible and correctly summarized, recurring findings have a disposition, and
the target can return to observe by changing only its local mode/agent configuration.

### Phase 4 — Full enforcement at a real gate

- Add a target-owned CI or pre-commit/pre-push invocation of `pdda.sh run` for candidates that have
  cleared light mode.
- Keep the watcher read-only; use it to provide context and audit records, not as the enforcement point.

**QA gate:** a seeded deterministic error is rejected at the intended gate; an equivalent observe/light
run is accurately reported but non-blocking; rollback from full to light is rehearsed and documented.

### Phase 5 — Opt-in learning evaluation

- Propose the approved sampling schema, consent record, retention rule, and target-stratified holdout.
- Run an offline candidate evaluation against the current router; do not deploy a checkpoint in this
  phase without a separate operator approval.

**QA gate:** all samples are consented/provenance-tagged; the evaluation reports per-target and
per-route results; a regression retains the incumbent checkpoint and creates no training deployment.

## Stop conditions and next decision

Stop or roll back a target to `observe` immediately if it writes outside declared runtime outputs,
misattributes a run, leaks one target's data/logs into another, or makes the owner unable to distinguish
a warning from a clean pass. Disable the target agent if it loops or materially degrades local workflow.

After Phases 1–2, make one evidence-based decision: either continue per-target agents through light
mode, or stop the rollout because isolation/noise/ownership failed. Only repeated, measured operational
overhead may reopen the question of a central multi-target supervisor. Any Sentinel write automation
remains governed by GH-10 and is out of scope here.
