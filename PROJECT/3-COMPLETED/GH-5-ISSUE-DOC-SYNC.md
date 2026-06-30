---
title: Deterministic issue↔doc sync check + two-tier doc-health hooks
status: Complete — all 4 build phases shipped, tested, committed + pushed; issue #5 closed, doc archived to 3-COMPLETED
created: 2026-06-29
updated: 2026-06-29
owner: noel
gh_issue: 5
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/5
doc_type: project
goal: >
  Close a proven, deterministic doc-governance gap — a 2-WORKING/GH-*.md doc whose gh_issue
  has drifted from its actual GitHub state + folder + status emoji — with a new warn-only,
  flag-only `pdda.sh issue-doc-sync` check, plus a lightweight two-tier (PostToolUse + Stop)
  doc-health review. Deterministic-first, no new deps, ships to installs via install.sh.
related:
  - PROJECT/PDDA.md
  - utils/pdda/pdda.sh
  - utils/pdda/PDDA-INSTALL.md
non_goals:
  - No auto-fixing or auto-moving of docs (flag only — a human runs the git mv).
  - No per-edit network calls; no blocking gates.
  - Not the swarm-preflight readiness contract (xyz #51).
effort: 3
complexity: 3
risk: 2
phases: 5
---

# Deterministic issue↔doc sync check + two-tier doc-health hooks

> GitHub issue: [#5](https://github.com/Hypercart-Dev-Tools/pdda/issues/5). This doc is the
> in-repo source of truth for the effort; the issue is the discussion surface.

## Status

| What was just completed | What's next |
|---|---|
| **Complete.** All 4 build phases shipped, tested, committed + pushed (`53ab555`, `4d49764`, `561f38c`, `e110fa1`): the `issue-doc-sync` check (warn-only, gh-degrade, 13 tests), the `gh-refresh` cache producer, and the two-tier PostToolUse + Stop doc-health hooks (18 tests). Issue #5 closed; doc archived here, ROADMAP pointer moved to Completed. | Done. (One repo-level follow-up outside GH-5: a concurrent GH-6 edit left `CHANGELOG.md` mid-flight — deleting ~156 lines of history — for the operator to reconcile; the GH-5 changelog entry rides with that fix.) |

## Table of contents

- [Swarm Preflight Contract](#swarm-preflight-contract)
- [Problem](#problem)
- [Reconciliation: brief paths → this repo](#reconciliation-brief-paths--this-repo)
- [Phase 0 — Issue, doc, park, contract](#phase-0--issue-doc-park-contract)
- [Phase 1 — Deliverable A: deterministic issue↔doc sync check](#phase-1--deliverable-a-deterministic-issuedoc-sync-check)
- [Phase 2 — Cached gh-state refresh job](#phase-2--cached-gh-state-refresh-job)
- [Phase 3 — PostToolUse fast local lint hook](#phase-3--posttooluse-fast-local-lint-hook)
- [Phase 4 — Stop full-scan hook + consolidated report](#phase-4--stop-full-scan-hook--consolidated-report)

## Swarm Preflight Contract

Per `AGENTS.md` #2/#3 — state the bet, the reversibility, and the blast radius **before** code.

- **The bet.** Every drift class here (closed-issue-still-in-WORKING; shipped-prose-but-issue-OPEN)
  is mechanical, so a deterministic check catches it with zero false-judgment risk. Adding it as a
  warn-only check costs almost nothing and removes a manual reconciliation pass.
- **Assumptions.** (1) `GH-*.md` docs carry a `gh_issue` frontmatter key (guaranteed by the
  `GH-<number>-` filename convention, `PROJECT/PDDA.md` → GitHub issue intake). (2) `gh` is often
  absent/offline in CI and hooks, so the check must degrade to a cached state file. (3) The status
  emoji / "fixed|shipped|complete" prose is a stable, greppable signal.
- **Failure mode.** A false flag is an ignorable warn line (never blocks, never moves a file); a
  missed flag leaves today's status quo (manual reconciliation). Both are cheap — this is why
  warn-only + flag-only is the right calibration.
- **Reversibility:** **Easy.** New subcommand + new hooks + new test file + a new `.claude/settings.json`.
  Nothing mutates existing checks' behavior; revert = delete the additions and the `cmd_run()` line.
- **Blast radius:** governance tooling only. **No** containment/relay/marathon path exists in this
  repo and none is touched. The only existing-file edits are *additive*: a `case` arm + a `cmd_run()`
  line + `pdda_usage()` text in `pdda.sh`, and lockstep entries in `PROJECT/PDDA.md` /
  `utils/pdda/PDDA-INSTALL.md` / `ROUTER.md`.
- **Containment > coordination correctness > signal quality > speed** (GUIDING-PRINCIPLES order):
  honored — nothing here can block a build or an edit, so it cannot threaten containment; it only
  adds signal.

## Problem

A 2026-06-29 reconciliation pass had to **manually** cross-reference git / CHANGELOG / issue state to
find docs whose recorded status drifted from reality. Each case was deterministic:

- An issue is **CLOSED** but its `2-WORKING/GH-*.md` still says "in progress" and never moved to
  `3-COMPLETED`.
- A doc/ledger entry says **shipped/fixed/complete** (🟢, prose "fixed") while the issue is **OPEN**.

No existing check catches this: `pdda.sh roadmap`/`roadmap-coverage` watch the **ledger**;
`pdda.sh stale` watches **mtime**. Neither compares a doc's `gh_issue` against the issue's actual
GitHub state + folder location + status emoji. (Evidence: xyz-3-agents-swarm issues #16, #13/#14/#43,
#37. This source-of-truth repo builds the check; installs receive it via `install.sh`.)

## Reconciliation: brief paths → this repo

The originating brief targets the **xyz-3-agents-swarm** install (flat layout). Mapped onto this
source-of-truth repo (runtime consolidated under `utils/pdda/`, PR #4):

| Brief (xyz layout) | This repo (canonical) |
|---|---|
| `utils/pdda-check-issue-doc-sync.sh` | new `check_issue_doc_sync()` + `issue-doc-sync)` case in `utils/pdda/pdda.sh` |
| gate: `bash validate.sh` | `utils/pdda/pdda.sh run` (`cmd_run()`) |
| wire into `utils/pdda-run.sh` | add to the `cmd_run()` sequence |
| mirror `pdda-check-ratings.sh` warn shape | mirror `pdda.sh changelog` (warn-only, never errors even in `full`) |
| gh-degrade from `queue-plan.sh` | no in-repo `gh` user — build minimal `command -v gh` + cached-state fallback per that pattern |
| ROADMAP parser from `roadmap-dashboard.sh` | lift from `check_roadmap` / `check_roadmap_coverage` in `pdda.sh` |
| `pdda-stale-working-docs.sh` | `pdda.sh stale` |
| `.claude/settings.json` + `relay-xyz-guard.sh` | create `.claude/settings.json` (none exists); standard hook schema via the update-config skill |
| `test/pdda-issue-doc-sync.sh` | establishes the repo's first `test/` dir |

## Phase 0 — Issue, doc, park, contract

Scaffolding (this phase).

- Filed GitHub issue [#5](https://github.com/Hypercart-Dev-Tools/pdda/issues/5).
- Wrote this doc to `PROJECT/2-WORKING/` with the full active-doc contract.
- Parked a one-line pointer in `ROADMAP.md`.
- Recorded the [Swarm Preflight Contract](#swarm-preflight-contract).

**QA gate:** `utils/pdda/pdda.sh run` green (frontmatter + status-table + roadmap-coverage pass for
this new doc); issue #5 exists and is linked both ways.

## Phase 1 — Deliverable A: deterministic issue↔doc sync check

Build `check_issue_doc_sync()` in `utils/pdda/pdda.sh`, flagging **both** directions:

- **(a)** a `2-WORKING/GH-*.md` whose `gh_issue` is **CLOSED** → `warn`, action = `git mv` to
  `3-COMPLETED`.
- **(b)** a doc/ledger entry reading shipped/fixed/complete while its issue is **OPEN** → `warn`.

Properties: deterministic, **flag-only (never auto-moves)**, **warn-level** (mirror
`check_changelog`'s `pdda_gated_exit` shape so it never blocks, even in `full`), **gh-degrade**
(`command -v gh` guard → fall back to cached state file → emit `info`/skip when neither is available),
standard finding output (`severity/check/file/line/message/action`) + activity-log append.

- Add the `issue-doc-sync)` dispatch arm and `pdda_usage()` line.
- Add it to the `cmd_run()` sequence.
- **Lockstep (AGENTS.md #5):** update `PROJECT/PDDA.md` (Automation layers → new check),
  `utils/pdda/PDDA-INSTALL.md` (manifest), and the `ROUTER.md` command rails.
- Add `test/pdda-issue-doc-sync.sh` with fixtures for **(a)**, **(b)**, and the **gh-absent** degrade
  path.

**QA gate:** new test passes; `pdda.sh run` green; running `pdda.sh issue-doc-sync` on the current
tree flags any real live drift (or cleanly reports none); lockstep docs updated in the same change.
Shippable alone.

## Phase 2 — Cached gh-state refresh job

A small script (bash, no deps) that calls `gh issue list --json number,state` and writes a cached
gh-issue-state file (location TBD in build; gitignored). Document the cadence (e.g. hourly cron /
launchd, alongside the existing PDDA hourly schedule). The Stop scan and the check read this cache so
they stay fast and offline-tolerant.

**QA gate:** refresh script produces a valid cache file; `issue-doc-sync` consumes it when `gh` is
absent; cadence documented in `PROJECT/PDDA.md`; `pdda.sh run` green.

## Phase 3 — PostToolUse fast local lint hook

A `PostToolUse` hook on `Edit|Write|MultiEdit` that reads `tool_input.file_path`, **exits 0 instantly**
for non-`PROJECT/**/*.md` / non-`ROADMAP.md` files, and otherwise runs a fast **local single-file**
lint (frontmatter, status-table, hardcoded-paths, roadmap-coverage). **No network. Warn-only,
fail-open — cannot block the edit.** Wired in `.claude/settings.json` via the update-config skill's
hook schema.

**QA gate:** editing a non-doc file is instant/no-op; editing a malformed doc prints a warn but the
edit still succeeds; no network call; hook proven unable to block.

## Phase 4 — Stop full-scan hook + consolidated report

A `Stop` hook that runs **one** system-wide doc-health scan per turn — the deterministic checks **plus
Deliverable A's issue↔doc sync against the cached gh-state file** — and prints **one consolidated
report**. **Never blocks.**

**QA gate:** Stop scan emits a single consolidated report; includes issue↔doc sync from cache; proven
unable to block a Stop; `pdda.sh run` green; `CHANGELOG.md` updated for the iteration.
