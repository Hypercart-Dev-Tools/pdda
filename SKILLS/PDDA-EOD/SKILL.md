---
name: pdda-eod
description: Run a PDDA iteration wrap for this repo. Use at the end of any unit of work — a task, a phase, a project doc, a marathon, or a day — and especially when `pdda.sh issue-doc-sync` reports reconciliation drift (a doc in 3-COMPLETED whose issue is still open, or a doc that declares itself ready to close). Also use when the operator wants a read-only status report, help reconciling PROJECT docs with ROADMAP.md and CHANGELOG.md, a scoped commit delivered to the remote directly or through a PR, user-verified closing of 100%-done GitHub issues, or safe linked-worktree teardown. Delegate deterministic checks to utils/pdda/pdda.sh, keep every mutation propose-then-confirm, and degrade cleanly when gh/auth is unavailable.
---

# /pdda-eod — the iteration wrap for this repo

Use this skill to close out a **unit of work** in the PDDA source-of-truth repo. It is a sequenced
operator workflow, not a free-form brainstorm.

## When this fires

The name says "EOD", but the trigger is **completion, not the clock**. `PROJECT/PDDA.md` already names
the unit: `CHANGELOG.md` is updated *"at the end of each iteration."* An iteration ends when a task, a
phase, a project doc, or a marathon finishes — which is the only moment the question *"should this issue
be closed?"* is actually answerable. Waiting for the end of the day just means asking it late.

Run this when any of these is true:

- The `Stop` hook reported doc/issue reconciliation drift and pointed you here.
- `utils/pdda/pdda.sh issue-doc-sync` warns that a doc is in `PROJECT/3-COMPLETED/` while its issue is
  still OPEN, or that a doc's status declares it is ready to close.
- A phase, milestone, or marathon lane just finished its last gate.
- The operator asks for an end-of-day wrap.

A deterministic script can *detect* that a unit of work has finished. It must never close the issue —
that is a human judgment, and PDDA's house style is **recommend, never act**. This skill is the layer
that asks.

The source of truth for the design is the GH-6 plan doc — `PROJECT/2-WORKING/GH-6-PDDA-EOD.md` while
in flight, or `PROJECT/3-COMPLETED/GH-6-PDDA-EOD.md` once shipped. Keep this skill lean; do not turn it
into a second plan doc.

## Guardrails

- Start by following `ROUTER.md` if repo context may have drifted.
- Delegate deterministic hygiene to `utils/pdda/pdda.sh`; do not re-lint those rules in prose.
- Every mutation is propose-then-confirm. Nothing irreversible or outward-facing happens without an
  explicit yes.
- Never force-push. Never close a GitHub issue just because a doc looks done; require user
  verification.
- Never create a duplicate PR, auto-merge, or call a pushed feature branch "shipped." A unit is
  delivered only when its commit is on the remote default branch; an open PR is a pending checkpoint.
- Never remove or move a Git worktree with `rm -rf` or `mv`, or hand-edit `.git/worktrees/` metadata.
  Treat `--force` on a worktree command as a stop-and-investigate signal, not a cleanup shortcut.
- If `gh` is unavailable or unauthenticated, continue the local wrap and report what GitHub data was
  skipped.
- If `utils/pdda/pdda.sh` is absent, PDDA is not installed here; say so and stop.

## Runtime order

1. **Gather state read-only.**

   Resolve the day window first: `--since <ref>` arg → timestamp of the latest
   `PROJECT/4-MISC/EOD-*.md` → today 00:00 local. Scope all git/PR/issue gathering below to it.

   Run the deterministic surface first:

   ```bash
   utils/pdda/pdda.sh run
   ```

   If available, also run:

   ```bash
   utils/pdda/pdda.sh issue-doc-sync
   ```

   Then gather the complete delivery state: current branch and worktree, remote default branch,
   upstream, `git status --short`, `git status -sb`, unpushed commits, recent commits, stashes, and
   `git worktree list --porcelain`. If `gh` works, gather open/closed issues and any existing PR for
   the current branch as well as relevant PR activity for the day window.

2. **Print the EOD report before editing anything.**

   Report:

   - resolved day window
   - deterministic findings verbatim
   - issue/doc sync findings if available
   - dirty files, untracked files, stashes, worktrees, current branch, upstream, and ahead/behind state
   - relevant PR/issue activity if `gh` succeeded
   - the recommended delivery route: direct-to-default, update an existing PR, create a PR, or stop
     because remote/auth/divergence state is unresolved
   - the concrete next decisions needed from the operator

3. **Reconcile active project docs.**

   For `PROJECT/2-WORKING/*.md`, propose only the minimal status/frontmatter/lifecycle edits supported
   by the day's evidence. A doc moves to `PROJECT/3-COMPLETED/` only after explicit confirmation. A doc
   that stays active must keep a non-empty `What's next`.

4. **Reconcile `ROADMAP.md` and `CHANGELOG.md`.**

   Propose pointer-only `ROADMAP.md` edits and a dated `CHANGELOG.md` entry for the iteration. Keep
   `ROADMAP.md` as a ledger, not a plan body. Apply only after confirmation, then re-run the narrow
   checks that prove the edits:

   ```bash
   utils/pdda/pdda.sh roadmap
   utils/pdda/pdda.sh roadmap-coverage
   utils/pdda/pdda.sh changelog
   ```

5. **Write the dated EOD summary before any final commit.**

   The summary path is:

   ```text
   PROJECT/4-MISC/EOD-YYYY-MM-DD.md
   ```

   It should capture what shipped, what is next, open findings carried forward, and the expected
   delivery state (direct push or PR). Write it before the final commit so the repo can end clean and
   the summary lands on the remote with the rest of the wrap.

6. **Prepare and commit only the approved Git tree.**

   Propose the exact path set, summary diff, checks, and commit message. Stage only approved paths with
   explicit path arguments; never use a broad sweep such as `git add -A`. After confirmation, run the
   checks, stage those paths, show the staged diff, and ask separately before committing. If no paths
   were approved or nothing is staged, do not create an empty commit. Leave unrelated changes untouched
   and classify the tree as intentionally dirty rather than silently absorbing them.

7. **Deliver the commit through the correct remote route.**

   Choose one route from the gathered evidence:

   - **Direct route:** only when the current branch is the remote default branch, repository policy
     permits direct pushes, and it is not behind or unexpectedly diverged. Show the exact push and ask.
   - **PR route:** use this when on a non-default branch, the default branch is protected, review is
     required, or the operator requests it. Push the branch only after confirmation. Reuse and update an
     existing PR for the same head/base; if none exists, preview the title, body, base, and head, then
     ask before creating one. Never auto-merge.

   Verify the result instead of inferring it: the committed paths are clean (or remaining dirt is
   explicitly out of scope), the branch has no unpushed commits, and the exact commit is either
   reachable from the remote default branch or attached to the named open/merged PR. An open PR means
   **pushed, review pending**, not shipped; record the PR as `What's next` and stop closure actions that
   require the work to have landed.

8. **Close GitHub issues only after delivery has landed and the user verifies them.**

   Once the exact commit is reachable from the remote default branch (direct push or merged PR),
   present candidate issues that appear 100% done. Close only the ones the user explicitly verifies.
   Cite the landed commit/PR and the owning doc in the closing comment.

   **Take the candidates from `issue-doc-sync`, do not re-derive them.** The check already answers this
   deterministically, in both directions:

   | Finding | Meaning | Proposal |
   |---|---|---|
   | `doc is in 3-COMPLETED but issue #N is still OPEN` | the operator already asserted the work is done, by moving the file | close #N |
   | `doc status declares it is ready to close but issue #N is still OPEN` | the doc says done, the bucket says active | `git mv` to `3-COMPLETED`, then close #N |
   | `issue #N is CLOSED but the doc is still in 2-WORKING` | GitHub says done, the tree does not | `git mv` to `3-COMPLETED` |
   | `issue #N state unavailable … sync NOT evaluated` | **the check could not run** | run `utils/pdda/pdda.sh gh-refresh`, then re-check. Do not treat this as "nothing to do." |

   That last row matters. An unevaluated check is not a passing check. If `gh` is unavailable, say which
   issues went unreconciled rather than reporting a clean wrap.

   Never close an issue because a doc *looks* done. Cite the evidence, name the finding, ask.

9. **Offer safe teardown of a completed linked worktree.**

   This is optional and separate from delivery. Offer it only when the linked worktree has no unique
   local work: approved changes are committed, the branch is fully pushed, and status/untracked checks
   are clean. An open PR may remain, but say plainly that removing a local worktree neither merges the
   PR nor deletes its branch. Require explicit confirmation naming the exact worktree. Identify it with
   `git worktree list --porcelain` (never guess a path or target the primary worktree) and re-check its
   branch, `git status --short`, untracked files, and unpushed commits. Stashes are shared across
   worktrees, so never pop or discard one as cleanup.

   On confirmation, run `git worktree remove <validated-absolute-path>`; do **not** add `--force` to
   bypass dirty-worktree protection. Then run `git worktree prune` to reconcile stale metadata. Never
   use filesystem deletion or manual `.git/worktrees/` surgery; if a worktree was already moved or is
   missing, stop and use Git's `repair` or `prune` recovery commands as the evidence dictates. Do not
   delete the branch as part of worktree teardown.

10. **Print and verify the terminal state.**

    End with one consolidated report naming: committed paths and commit hash; checks run; local
    clean/intentionally-dirty state; upstream and unpushed count; direct-push or PR URL/state; whether
    the commit is on the remote default branch; doc/ROADMAP/CHANGELOG disposition; issue actions or
    deferrals; and worktree retained/removed. Never call the wrap complete when push, PR merge, issue
    reconciliation, or another required action is still pending.

## Operating stance

- Prefer one consolidated report over a stream of scattered findings.
- Prefer narrow re-checks after each confirmed mutation instead of re-running the entire wrap blindly.
- If a step is declined, leave the tree coherent and continue with the remaining read-only/reporting
  work when that still makes sense.
- If the user asks for a dry run, write nothing and perform no git or GitHub mutations.
