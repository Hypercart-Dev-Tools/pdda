---
name: pdda-status
description: Review the 10 most recently updated GitHub issues against this repo's PROJECT/** lifecycle state. Builds a temp matrix (issue, GH state, doc location, frontmatter status, evidence confidence 0-5), cross-references each issue's checklist against commits/PRs, and — only above a confidence threshold — proposes (never auto-applies) a frontmatter status edit + git mv + ROADMAP.md pointer move. Saves the session matrix to a dated PROJECT/4-MISC/PDDA-STATUS-<date>.md doc. Reuses utils/pdda/pdda.sh issue-doc-sync + gh-refresh for the GH-state half of the signal rather than re-deriving it. Trigger on /pdda-status, /PDDA-status, "review recent GH issues against project docs", "reconcile issue status with PROJECT folders".
---

# /pdda-status — reconcile recent GH issues against PROJECT/** state

Builds a confidence-scored status matrix over the 10 most recently updated GitHub issues, cross-checked
against this repo's `PROJECT/**` lifecycle docs. **Report-and-propose, not report-and-apply**: every
recommended frontmatter/location change is previewed as one bundle and only written on explicit
confirmation — the same posture as `/idea` and `/pdda-eod`, and the same posture `PROJECT/PDDA.md`
enforces everywhere else a script could otherwise mutate a doc or move a file (`pdda.sh stale` is
flag-only; `pdda.sh issue-doc-sync` is warn-only and "detect deterministically, act only with a yes").

**Do not re-derive GH-state detection this skill already has a check for.** The GH-state half of the
signal (issue CLOSED but doc still in `2-WORKING`; issue OPEN but doc's status reads done) is exactly
what `utils/pdda/pdda.sh issue-doc-sync` already computes, deterministically, against **live `gh` when
reachable, falling back to the cached gh-state file otherwise** (`PDDA_ISSUE_SYNC_SOURCE=auto` default —
see `PROJECT/PDDA.md` → "gh-degrade"). Call it; don't reimplement it. This skill adds three things
`issue-doc-sync` does not do: the 10-issue recency scope, the confidence score, and the
checklist-vs-commit evidence read.

**Scope limit inherited from `issue-doc-sync`:** that check only ever scans `PROJECT/2-WORKING` and
`PROJECT/3-COMPLETED` — it has no opinion on a doc in `1-INBOX`, `4-MISC`, or a missing doc. Step 4's
signal 5 below carries this same limit forward explicitly; don't let a doc outside those two buckets
silently read as "the check agrees."

**Related, not superseded.** `ROADMAP.md` already queues **GH-9** (a weekly progress counter — open
issues + closed tasks) and **GH-51** (a device-wide doc-index spike reconciling the same four claims —
folder / status / GH state / ROADMAP pointer — across every PDDA install). Both are unbuilt. This skill
covers a narrower, session-scale slice (10 issues, this repo only) and does not close or replace either;
say so in the report rather than silently duplicating them.

## Steps

### 0. Preflight

- Confirm `utils/pdda/pdda.sh` exists at the repo root. If PDDA isn't installed here, say so and stop —
  this skill has nothing to reconcile against.
- Confirm `gh` is authenticated (`gh auth status`). Retry unsandboxed once before concluding auth is
  actually broken — a sandboxed shell can give a false "invalid token" read.
- Refresh the cached GH state so `issue-doc-sync` reads current data, not a stale cache:

  ```bash
  utils/pdda/pdda.sh gh-refresh
  ```

### 1. Pull the 10 most recently updated issues

```bash
gh issue list --state all --limit 10 --search "sort:updated-desc" \
  --json number,title,state,url,updatedAt,body
```

Also pull each issue's comments — signal 2 (step 4) needs them for a stated reason behind an unchecked
box, and a plain `body` fetch above does not include them:

```bash
gh issue view <n> --json comments
```

For each issue, also pull linked/referencing activity — search **both** title and body for the PR, and
grep commit subjects (which cover title-equivalent text) for the issue reference:

```bash
gh pr list --search "<n> in:title,body" --state all --json number,title,body,state,mergedAt,url
git log --all --oneline --grep "#<n>\|GH-<n>"
```

### 2. Locate each issue's local doc

Search all four lifecycle buckets for a `GH-<n>-*.md` filename or a `gh_issue: <n>` frontmatter key
(the same two resolution paths `issue-doc-sync` uses):

```bash
grep -rl "gh_issue: *<n>\b" PROJECT/ 2>/dev/null
find PROJECT -iname "GH-<n>-*.md"
```

Record: which bucket it's in (`1-INBOX` / `2-WORKING` / `3-COMPLETED` / `4-MISC` / none found), its
frontmatter `status:` value, and whether it has a `ROADMAP.md` pointer.

### 3. Run `issue-doc-sync` for the mechanical half

```bash
utils/pdda/pdda.sh issue-doc-sync
```

Parse its warn lines for each of the 10 issue numbers — this is your ground truth for "does GH state
already disagree with the doc," computed the same way it would be for any other repo pass. Don't
re-derive this signal by hand; carry its verdict straight into the matrix.

### 4. Score evidence confidence (0-5 per issue)

Award one point per signal that holds true — this is a checklist tally, not a weighted/blended score
(`PROJECT/PDDA.md`'s triage-ratings section explicitly rejects a stored composite for the same reason: a
frozen blend drifts from the facts it came from and hides a tuning choice). Keep the five raw signals
visible in the matrix, not just the sum:

1. GH issue `state` is `CLOSED`.
2. The issue body's GFM checklist (`- [ ]`/`- [x]`) is at or near fully checked (all, or all-but-one with
   a stated reason — check the checklist in the body **and** the comments pulled in step 1).
3. At least one merged PR or `main`-branch commit references the issue number (`Fixes #<n>`, `#<n>` in a
   commit subject or PR title/body, or a `GH-<n>` mention).
4. The local doc's own `status:` **lead word** already reads as done — use `issue-doc-sync`'s own
   terminal-word list (`PDDA_TERMINAL_STATUS_WORDS` in `utils/pdda/pdda.sh`), not a hand-copied one; a
   list re-typed here would drift the moment the real one changes. Same lead-word anchor `issue-doc-sync`
   uses, so a mid-sentence "Phase 2 complete" inside an otherwise-active status never over-counts.
5. **Only when the doc is in `2-WORKING` or `3-COMPLETED`** (the two buckets `issue-doc-sync` actually
   scans — see the scope-limit note above): it reports **no drift warn** for this doc. **If the doc is in
   `1-INBOX`, `4-MISC`, or doesn't exist, this signal is `n/a`, not true** — `issue-doc-sync` never
   evaluated it, so silence there is "not checked," not "agrees." Score it as 0 toward the tally and mark
   it `n/a` in the matrix (step 5) rather than counting a pass.

**3/5 is "high confidence" — propose the action in step 6.** Below 3/5, the matrix still shows the score
and the evidence, but step 6 proposes nothing for that row beyond "insufficient evidence, no action
suggested." The threshold gates whether an action is *offered*; it never gates whether an action is
*applied* — every proposal still goes through the confirmation gate in step 6 regardless of score.

### 5. Build the temp matrix

Render as one table, newest issue first — this is a working artifact for this session, not yet the
saved doc (that's step 8):

| # | Title | GH state | Doc bucket | `status:` | Checklist | Commit/PR evidence | Confidence | Recommended action |
|---|---|---|---|---|---|---|---|---|
| 55 | ... | OPEN | none found | — | n/a | n/a | 0/5 | No doc captured yet — not this skill's job to create one (see `/idea`) |
| 45 | ... | CLOSED | `3-COMPLETED` | Complete | 4/4 checked | PR #46 merged | 5/5 | Already reconciled — no action |
| 50 | ... | OPEN (reopened) | `2-WORKING` | Active — Phase 0 complete | 6/9 checked | PR #52 merged | 2/5 | No action — issue reopened on purpose, doc correctly still active |

### 6. Preview one bundled proposal, then get ONE confirmation

For every row scoring **≥3/5 where the recommended action is a real change** (frontmatter status word
and/or lifecycle-bucket move), draft the exact diff — do not apply anything yet. **The target bucket is
not generic — pick it from the row's actual situation, not a default "promote toward completed":**

| From bucket | Situation | Target | Extra requirement |
|---|---|---|---|
| `2-WORKING` | issue CLOSED, work genuinely done | `3-COMPLETED` | **`## Lessons Learned (For Future Agents)` must be drafted and included in the diff** — `PROJECT/PDDA.md`'s active-doc contract requires it before this move, and `pdda.sh frontmatter` only scans `2-WORKING` so it will *not* catch a missing one after the move |
| `1-INBOX` | issue CLOSED, capture never actioned (no real work started) | `4-MISC` | remove its `ROADMAP.md` queue pointer entirely (per `PROJECT/PDDA.md` → "GitHub issue intake" lifecycle) — **never** promote an un-actioned capture straight to `3-COMPLETED` |
| `3-COMPLETED` | issue still OPEN | *(no bucket move)* | recommend `gh issue close <n>` instead — this is `issue-doc-sync`'s own direction-(c) finding, not a file move |

For every proposed move, draft:

- the frontmatter `status:` before → after (one line, not a full rewrite)
- for a `2-WORKING → 3-COMPLETED` move: the actual `## Lessons Learned` section text (from the doc's own
  content — don't invent claims), included as part of the same diff
- the exact `git mv PROJECT/<from-bucket>/GH-<n>-*.md PROJECT/<to-bucket>/GH-<n>-*.md`
- the matching `ROADMAP.md` edit: moving a doc out of `2-WORKING` means its ledger line must also move
  out of "In progress" into "Completed"/"Deferred"/removed (per the table above) — draft this in the
  same bundle so the move can't silently leave a stale pointer behind

Render every proposed row together as a single preview (same pattern as `/idea`'s "one preview, one
confirmation"). Apply **nothing** until the operator confirms — a batch "yes to all" or per-row picks
are both fine, but no write happens on an unconfirmed row.

### 7. Apply confirmed rows, then verify

For each confirmed row: edit the frontmatter line, run the `git mv`, edit the `ROADMAP.md` line. Then
run the deterministic re-check — do not report success without it:

```bash
utils/pdda/pdda.sh roadmap-coverage
utils/pdda/pdda.sh frontmatter
utils/pdda/pdda.sh issue-doc-sync
```

If any of these newly error, that's a signal the move was wrong (e.g. missed the `roadmap_exempt`
carve-out) — report it, don't paper over it.

### 8. Save the session matrix

Write the full matrix (including rows below the confidence threshold, and what was/wasn't applied) to:

```
PROJECT/4-MISC/PDDA-STATUS-<YYYY-MM-DD>.md
```

Same convention as `/pdda-eod`'s `PROJECT/4-MISC/EOD-<date>.md` — a dated snapshot doc, `status: Complete
(4-MISC)` from creation, minimum frontmatter (`title`, `status`, `created`, `updated`, `owner`,
`doc_type: pdda-status`). This is a point-in-time reference, not a second `CHANGELOG.md` — if any doc
actually moved or changed status, that's a substantive iteration and still earns its own `CHANGELOG.md`
entry per `AGENTS.md` #7; don't skip that because a matrix doc exists.

## Guardrails

- **Never auto-apply a lifecycle/frontmatter/ROADMAP change.** Steps 6→7 are separate for a reason:
  no doc's `status:`, no `git mv`, no `ROADMAP.md` line changes until the operator has seen the full
  bundled diff and confirmed. This is the one non-negotiable carried over from `PROJECT/PDDA.md`'s stance
  across every other check in the repo — `pdda.sh stale` flags, it doesn't move; `issue-doc-sync` warns,
  it doesn't close. (This does not extend to step 8's own matrix doc — writing a *new*, dated report file
  is the report itself, not a mutation of an existing doc; same posture as `/pdda-eod`'s EOD doc, which
  is also written directly.)
- **The confidence score is a checklist tally, not a blended metric.** Show the five raw signals in the
  matrix, not just the number — a reader should be able to see *why* something scored 3/5, not trust a
  black box.
- **Reuse, don't reimplement.** Step 3 must actually shell out to `pdda.sh issue-doc-sync`; don't
  hand-roll a parallel GH-state comparison.
- **Don't silently duplicate GH-9 or GH-51.** Name them in the report if either is still open when this
  runs — this skill is a complement, not a replacement, and closing either issue is a human call.
- **Repo-relative paths only** in anything written to the matrix doc or `ROADMAP.md`.
