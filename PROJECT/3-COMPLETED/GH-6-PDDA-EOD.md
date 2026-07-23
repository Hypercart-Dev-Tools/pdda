---
title: PDDA-EOD skill — end-of-day wrap
status: Completed (2026-06-29; delivery/PR/worktree closure hardened 2026-07-22)
created: 2026-06-29
updated: 2026-07-22
owner: noel
gh_issue: 6
goal: >
  A /pdda-eod skill that runs an end-of-day wrap on this repo: surface state via the existing
  deterministic checks, reconcile project docs + ROADMAP + CHANGELOG, commit only approved paths,
  deliver through a direct push or PR as branch policy requires, close landed 100%-done GitHub issues
  (user-verified), optionally tear down a safe linked worktree, and write a dated EOD summary.
  Deterministic work is delegated to pdda.sh; judgment + mutations are the skill's job, all
  propose-then-confirm.
branch: gh-6-pdda-eod
non_goals: >
  Not multi-repo (this repo only for v1). Not auto-mutating (nothing irreversible without confirmation).
  Not a replacement for `pdda.sh catchup` (ROUTER maintenance) or the `/pdda` re-orient skill — it reuses
  them. No new sync behavior. No automatic PR merge or branch deletion.
effort: 3
complexity: 3
risk: 2
phases: 5
---

## Status

| What was just completed | What's next |
|---|---|
| **COMPLETE; hardened 2026-07-22.** `/pdda-eod` now carries one end-to-end closure model: gather → doc/ledger reconciliation → summary → scoped commit → direct-or-PR delivery → prove the commit landed → user-verified issue closure → optional safe worktree teardown → terminal report. An open PR is explicitly pending, not shipped. | **Done.** Open follow-ups (left as enhancements, not blockers): the `pdda.sh eod-gather` helper (Q1) and `--with-startup-docs` packaging (Q3) remain optional. |

## Table of contents

- [Phase 1 — Read-only gather + EOD report](#phase-1--read-only-gather--eod-report)
- [Phase 2 — Reconcile project docs (frontmatter + lifecycle)](#phase-2--reconcile-project-docs-frontmatter--lifecycle)
- [Phase 3 — ROADMAP + CHANGELOG updates](#phase-3--roadmap--changelog-updates)
- [Phase 4 — Scoped commit + remote delivery](#phase-4--scoped-commit--remote-delivery)
- [Phase 5 — Landed issue close + summary + worktree teardown](#phase-5--landed-issue-close--summary--worktree-teardown)

## Context

The repo already enforces most end-of-day hygiene deterministically (`pdda.sh run`: frontmatter,
status-table, roadmap-coverage, stale, changelog, hardcoded-paths) and is building GH-5
`issue-doc-sync`. EOD's job is **not** to reinvent those — it is to run them, then handle the parts
that need judgment (which docs are done, what the day's CHANGELOG entry says, which issues are truly
closed) and the mutations (doc moves, ROADMAP/CHANGELOG edits, commit/push, PR creation, issue-close,
worktree removal) — each behind a confirmation, in an order that's safe to re-run.

### Operating principles this must respect

- **Deterministic where judgment isn't needed** (#3): delegate to `pdda.sh`; the skill only adds
  judgment + confirmed mutations.
- **Resumable by a cold agent** (#2): the dated EOD summary is the day's recoverable record.
- **Non-destructive by default**: dry-run/propose-then-confirm for every mutation; irreversible/outward
actions (push, PR creation, issue-close, worktree removal) always need an explicit yes. PR merge is
never automatic.
- **One canonical place per fact** (#4): EOD reconciles docs ↔ ROADMAP ↔ issues, never duplicates.

### Runtime order (the skill's own sequence — distinct from build phases)

1. Gather + run checks (read-only).
2. Reconcile project docs (frontmatter "what's done/next"; move done docs to `3-COMPLETED`) — confirm.
3. Update ROADMAP.md + draft today's CHANGELOG entry — confirm.
4. **Write the dated EOD summary** (`PROJECT/4-MISC/EOD-<date>.md`) — *before* the commit, so it rides
   in the pushed commit rather than re-dirtying the tree afterward.
5. Commit only approved paths (**including the summary**) after a staged-diff review — confirm.
6. Deliver through the evidence-backed route: direct push when already on an allowed default branch,
   otherwise update/create a PR; never duplicate or auto-merge a PR — confirm each outward action.
7. Verify the exact commit is either on the remote default branch or attached to the named open PR.
   An open PR is a pushed checkpoint, not a shipped result.
8. Close 100%-done GH issues (user-verified) only once the commit is on the remote default branch.
9. Optionally remove a clean, fully pushed linked worktree through `git worktree remove` + `prune`.
10. Print one terminal report covering local tree, upstream, delivery, docs, issues, and worktree state.

Three ordering constraints are load-bearing: (a) the summary is written **before** the final commit so
the terminal state is genuinely clean *and* the summary is on the remote for the next operator
(Principle #2); (b) pushing a feature branch is not delivery — issue-close waits until direct push or
PR merge makes the commit reachable from the remote default branch; (c) worktree teardown is last and
only after proving no unique local work remains.

## Design

### Mechanical vs judgment split

- **Delegate to `pdda.sh`:** `run` (all deterministic checks), `stale`, `roadmap-coverage`, `changelog`,
  and GH-5 `issue-doc-sync`. Open question Q1: whether to add a thin `pdda.sh eod-gather` that emits a
  single structured (JSON) read-only snapshot, or have the skill call the existing subcommands + `git`
  + `gh` directly. Lean: start with direct calls; extract a helper only if the gathering grows.
- **Skill owns:** the day's window, "is this doc/issue actually done?", drafting the CHANGELOG entry and
  EOD summary, and sequencing the confirmed mutations.

### The day's window

EOD reviews activity since a defined start. Resolution order (Q2): `--since <ref>` arg → last
`PROJECT/4-MISC/EOD-*.md` timestamp → today 00:00 local. Used to scope `git log`, merged PRs, and
closed/closable issues.

### Confirmation model

Every mutating step prints a plan and waits for an explicit yes; `--dry-run` runs the whole wrap and
writes nothing (not even the summary). Outward/irreversible actions (`git push`, `gh issue close`) are
always individually confirmed even outside dry-run. Pushes run un-sandboxed (keychain); degrade
gracefully and report if `gh` auth is unavailable rather than failing the wrap.

### Reuse, not duplication

`pdda.sh catchup` already gathers recent CHANGELOG/commits/inbox for ROUTER recommendations — EOD
reuses that gathering shape but stays distinct (catchup = ROUTER maintenance; EOD = day-wrap +
lifecycle + commit/close). The `/pdda` skill re-orients; EOD closes out.

## Phase 1 — Read-only gather + EOD report

The safe core: mutate nothing, just surface the day's state.

- Resolve the window; collect `git log`/diffstat, merged + open PRs, closed + open issues (via `gh`).
- Run `pdda.sh run` + `issue-doc-sync`; capture findings.
- Read Git delivery state: dirty files, unpushed commits, stashes, current branch/worktree, remote
  default branch, upstream, ahead/behind state, linked worktrees, and any PR for the current branch.
- Render a structured EOD report to stdout (no writes yet).

**QA gate:**
- [ ] On a repo with the day's commits + ≥1 merged/open PR, the report lists each with correct hashes/numbers and states the resolved window boundary.
- [ ] Open `pdda.sh run` + `issue-doc-sync` findings appear verbatim; the dirty / un-pushed / stash summary matches `git status` + `git stash list`.
- [ ] The run writes zero files (`git status` unchanged; no new `PROJECT/4-MISC/EOD-*.md`).
- [ ] With `gh` unavailable (simulated auth failure), it prints a clear "PR/issue data skipped" note and still completes the rest.

## Phase 2 — Reconcile project docs (frontmatter + lifecycle)

- For each `PROJECT/2-WORKING` doc, propose frontmatter updates to the "## Status" table
  (what's done / what's next) based on the day's activity.
- Detect done docs by **acceptance criteria met (QA gates checked) + explicit user move-confirmation** —
  *not* by an empty "What's next". A doc that stays in `2-WORKING` must keep a non-empty "What's next"
  (the status-table contract requires it); a doc judged done keeps a non-empty cell like
  "Ready to move to 3-COMPLETED" until the confirmed move lands, so EOD never has to violate PDDA to
  satisfy its own completion rule.
- Propose moving confirmed-done docs `2-WORKING → 3-COMPLETED`; apply only on confirmation, never move a
  doc the user hasn't OK'd.

**QA gate:**
- [ ] A 100%-done doc is proposed for frontmatter close + move and lands in `3-COMPLETED` only after an explicit yes.
- [ ] An in-progress doc is left untouched in `2-WORKING`.
- [ ] Declining the prompt leaves every doc in place (no partial move, no half-edited frontmatter).
- [ ] `pdda.sh run` stays green afterward (status-table intact; the moved doc no longer needs a 2-WORKING ROADMAP pointer).

## Phase 3 — ROADMAP + CHANGELOG updates

- Propose ROADMAP.md ledger edits (move entries between in-progress/completed; keep it a pointer, not a
  plan body) and re-verify `roadmap-coverage` after.
- Draft today's CHANGELOG entry from the day's commits/PRs; confirm before writing.

**QA gate:**
- [ ] After apply, `pdda.sh roadmap`, `roadmap-coverage`, and `changelog` all report clean.
- [ ] CHANGELOG gains exactly one new dated entry for today; a second EOD run the same day updates, not duplicates, it.
- [ ] No execution detail (phase checklists / build steps) leaks into ROADMAP — it stays a pointer/ledger.
- [ ] Declining leaves ROADMAP + CHANGELOG byte-for-byte unchanged.

## Phase 4 — Scoped commit + remote delivery

- Summarize uncommitted/untracked/stashed/un-pushed state; propose a commit grouping + message(s).
- **Each proposed commit names its exact path set + a summary diff**, and EOD stages **only the approved
  paths** (`git add <paths>`, never `git add -A`). Dirty files the user did not select are left
  untouched and explicitly reported as "tree not fully clean" — so a concurrent edit or unrelated WIP
  (possibly from another agent/window) is never swept into an EOD wrap commit.
- Run the agreed checks, stage the approved paths, show the staged diff, and ask separately before
  committing. Do not create an empty commit.
- Choose the delivery route from evidence:
  - direct push only when already on the remote default branch, direct pushes are permitted, and the
    branch is not unexpectedly behind/diverged;
  - otherwise push the feature branch and update its existing PR, or preview and confirm creation of
    one PR for the exact head/base when none exists.
- Never force-push, duplicate a PR, or auto-merge. Verify the commit on the remote: either reachable
  from the remote default branch (landed) or attached to the named open PR (review pending).

**QA gate:**
- [ ] *Happy path* (user approves all PDDA-owned dirty paths): after the wrap `git status` is clean and `git status -sb` shows `main` in sync with `origin/main`.
- [ ] *Partial-selection path* (user leaves some dirty files out): only the approved paths are committed + pushed; the unselected files remain untouched and are clearly reported as "tree not fully clean" — this is a success, not a failed phase.
- [ ] Nothing is committed or pushed without an explicit yes; `--dry-run` performs zero git writes.
- [ ] A declined/failed push leaves a coherent state (commits intact, nothing half-staged) and is reported clearly; never force-pushes; existing stashes are surfaced, never silently dropped.
- [ ] On a feature branch, an existing PR is reused; otherwise title/body/base/head are previewed before
  one PR is created. An open PR is reported as pending and is never auto-merged.
- [ ] The terminal claim distinguishes `landed on remote default` from `pushed to branch with PR open`.

## Phase 5 — Landed issue close + summary + worktree teardown

- Write `PROJECT/4-MISC/EOD-<date>.md` (what shipped, what's next, open findings carried forward)
  **before** the Phase-4 commit (runtime step 4), so the summary is committed + pushed with the rest and
  the wrap ends in a genuinely clean, fully-pushed state — not with an uncommitted summary left behind.
- Present candidate 100%-done issues (cross-checked against their docs via `issue-doc-sync`); close
  **only** the ones the user verifies, **after the commit lands on the remote default branch**. A
  feature-branch push with an open PR does not qualify. Issue-close is a remote-only action, so it
  does not re-dirty the working tree; the closing comment cites the landed commit/PR + doc.
- Optionally offer linked-worktree teardown after proving it is clean, has no untracked/unpushed work,
  and naming its validated absolute path. Removal requires confirmation and uses `git worktree remove`
  followed by `git worktree prune`; never filesystem deletion, `--force`, metadata surgery, or branch
  deletion. Worktree removal does not merge an open PR.
- Finish with a consolidated terminal report: commit/checks, clean or intentionally dirty tree,
  upstream/unpushed state, delivery route and PR state, default-branch reachability, doc/ledger state,
  issue actions/deferrals, and worktree retained/removed.
- Package as the `/pdda-eod` skill (`.claude/skills/pdda-eod/SKILL.md`); decide whether it ships via
  `install.sh --with-startup-docs` like `/pdda` (Q3). Update ROUTER.md/PDDA-INSTALL.md if so.

**QA gate:**
- [ ] The EOD summary is part of the pushed commit; after the wrap the tree is clean with **no** uncommitted `EOD-<date>.md` left behind, and the summary is on the remote.
- [ ] A user-verified 100%-done issue closes only after the commit reaches the remote default branch
  (citing commit/PR + doc); an open PR, unverified issue, or declined verification closes nothing.
- [ ] `PROJECT/4-MISC/EOD-<date>.md` reads as a faithful resumable record (what-shipped / what's-next / carried-forward findings).
- [ ] A linked worktree is offered for removal only when clean and fully pushed, targets the exact
  porcelain-reported linked path, and leaves its branch/PR intact.
- [ ] The final report never says complete while a required push, PR merge, issue reconciliation, or
  teardown decision remains pending.
- [ ] `pdda.sh run` is green and the `/pdda-eod` `SKILL.md` is discoverable (loads as a skill).

## Open questions

1. **`pdda.sh eod-gather` helper vs direct calls?** Lean: direct calls first; extract only if needed.
2. **Window default** — last EOD summary timestamp vs midnight vs last push. Lean: last EOD → midnight.
3. **Ship via `--with-startup-docs`?** Like `/pdda`, or keep EOD a source-repo-only operator skill.
4. **Summary location** — `PROJECT/4-MISC/EOD-<date>.md` (chosen) vs an append-only `PROJECT/EOD-LOG.md`.
