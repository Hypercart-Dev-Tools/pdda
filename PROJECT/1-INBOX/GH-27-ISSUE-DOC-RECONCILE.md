---
gh_issue: 27
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/27
title: "issue-doc-sync misses both completion leaks: the check stops watching a doc at the moment it completes"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-09
updated: 2026-07-09
owner: noel
doc_type: bugfix
effort: 2
complexity: 2
risk: 1
phases: 2
context_tags: [governance, issue-doc-sync, doc-lifecycle, staleness]
related: [utils/pdda/pdda.sh, PROJECT/PDDA.md, GH-14-GOVERNANCE-FD-EXHAUSTION.md, GH-23-AGENT-ONRAMP.md]
goal: >
  Close the doc/issue reconciliation loop where it actually leaks: extend issue-doc-sync to watch a doc
  after it lands in 3-COMPLETED, stop scoring an unevaluated check as a passing one, persist the gh state
  it already fetches, and make untracked plan docs declare themselves. Warn-only, no new subsystem.
---

# GH-27 — issue-doc-sync stops watching a doc at the moment it completes

Capture of GitHub issue [#27](https://github.com/Hypercart-Dev-Tools/pdda/issues/27).
Full write-up lives on the issue; this is the in-repo back-reference.

## Status

| What was just completed | What's next |
|---|---|
| Diagnosed the staleness complaint. **PDDA is not missing a loop** — `pdda.sh issue-doc-sync` already checks both directions, is warn-only, prints exact remediation, and degrades offline. It reports `warns=0` on two live leaks in this repo. Root cause identified and two leaks verified against live GitHub state. | Promote to `2-WORKING` and build P1 (scope + honesty) then P2 (cache + untracked docs). Both warn-only. |

## The finding

The complaint was "stale plans and issues that are done but not closed." The intuitive read is *the loop is
missing*. It is not. `check_issue_doc_sync` (`utils/pdda/pdda.sh:548`) is well built: two directions,
warn-level, exact `git mv` / status-correction recommendations, graceful `gh`-absent degradation.

It fails at the one moment it matters — **completion** — and it fails four ways.

## Two leaks, verified against live GitHub state (2026-07-09)

### Leak 1 — following the check's own advice blinds it

`PROJECT/3-COMPLETED/GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md` sits in `3-COMPLETED`. Issue **#15 is
OPEN**. `pdda.sh issue-doc-sync` says `warns=0`.

The loop iterates `pdda_list_working_docs` — `PROJECT/2-WORKING` only. Direction (a) tells the operator
`recommend: git mv … PROJECT/3-COMPLETED/`. The instant they comply, the doc leaves scope and the open
issue is never mentioned again.

**The remediation the check recommends is what blinds it.** This is the single highest-value fix.

### Leak 2 — the status prose lies and the heuristic believes it

`PROJECT/2-WORKING/GH-12-QUAD-CONCEPTS-MODE.md`:

```
status: Active — Phases 1–4 complete + final consult passed (no blockers; polish applied);
        42/42 + 6/6. Ready to close to 3-COMPLETED.
```

Issue **#12 is OPEN**. Direction (b) fires only when `_pdda_status_leadword` returns a terminal word. The
lead word is `Active`. Every human reading that line knows the work is finished; the parser reads the
first token and moves on.

## Two more failure modes, same root

**Silent degradation.** With no `gh` and no cache the check emits `info … sync not evaluated` and
continues. *A check that could not run is scored as a check that passed.* In `observe` mode `pdda.sh run`
then prints "all checks passed." This is BUG-001b (GH-14 Phase 2) wearing a different hat — the third
instance of that shape this week.

**The cache is never written.** `.pdda-gh-state.tsv` does not exist in this repo. `pdda.sh run` uses
`auto` (live `gh`) and then **throws away what it fetched**. `gh-refresh` is a separate manual command
nobody runs, so every offline run is permanently blind. The consumer already holds the data the producer
is supposed to cache.

**Untracked plan docs never enter the loop.** `[ -n "$num" ] || continue` skips any doc without
`gh_issue:`, and `gh_issue` is not in `REQUIRED_KEYS`. `PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md` and
`MARATHON-PLAN-2026-07-07.md` are invisible to reconciliation. That is precisely the "stale project plans"
class.

## The insight

> **The lifecycle bucket is a deterministic signal. The status prose is not.**

Direction (b) tries to infer doneness by parsing English from a `status:` field. Meanwhile `3-COMPLETED/`
**is** the assertion "this is done" — made by an operator, recorded in a path, verifiable with `test -f`.
Key off the bucket and the fragile heuristic becomes unnecessary rather than merely improved.

## Phases

- **P1 — Scope and honesty.** Scan `3-COMPLETED/`: a doc there whose issue is `OPEN` warns with
  `recommend: gh issue close <n>`. Promote `state unavailable` from `info` to `warn`. Both are small,
  local changes to `check_issue_doc_sync`. P1 alone catches both live leaks.
  *Tests first:* land cases 1, 3, 6 red against today's code, then green. Plus negative controls 2, 4, 11.
- **P2 — Persistence and coverage.** Write `.pdda-gh-state.tsv` on every successful live lookup so an
  offline run evaluates against last-known state. Warn when a `2-WORKING` doc has neither `gh_issue:` nor
  an explicit `issue_exempt: true`, mirroring the existing `roadmap_exempt` opt-out.
  *Tests:* cases 5, 7, 8, 9, 10.

Each phase lands green on `utils/pdda/pdda.sh run` **and** on `bash test/pdda-issue-doc-sync.sh`.

## Acceptance criteria

- [ ] `issue-doc-sync` warns that GH-15's doc is in `3-COMPLETED` while issue #15 is OPEN.
- [ ] It warns on GH-12 regardless of the `Active —` lead word.
- [ ] With `gh` unavailable and no cache, unevaluated docs produce **warns**, not `info`.
- [ ] After one online `pdda.sh run`, `.pdda-gh-state.tsv` exists; a later offline run evaluates rather than skipping.
- [ ] `AGENTS-BUILDER-SKILL.md` and `MARATHON-PLAN-2026-07-07.md` are flagged as untracked, or opt out explicitly.
- [ ] **Negative control:** a doc in `3-COMPLETED` whose issue is genuinely CLOSED produces no finding.
- [ ] Still warn-only. Still never blocks. Still fails open when `gh` is absent.
- [ ] **Every criterion above is pinned by a test in `test/pdda-issue-doc-sync.sh`** (see below).

## Regression tests — `test/pdda-issue-doc-sync.sh`

The suite already exists (14 passing) and **passed throughout both leaks**. That is the second-order
bug: the tests encoded the check's behavior, not its purpose. Extending the suite is not optional
polish here — it is the only thing that stops this regressing, and the only evidence the fix works.

The suite builds sandbox repos and stubs `gh` via the cached-state file, so every case below is
offline, hermetic, and needs no network.

| # | Case | Fixture | Expect |
|---|---|---|---|
| 1 | Doc in `3-COMPLETED`, issue OPEN | `3-COMPLETED/GH-901-X.md`, cache `901 OPEN` | **warn**, `recommend: gh issue close 901` |
| 2 | **Negative control.** Doc in `3-COMPLETED`, issue CLOSED | cache `902 CLOSED` | **no finding** |
| 3 | Leak 2 verbatim. Doc in `2-WORKING`, issue OPEN, `status: Active — … Ready to close` | cache `903 OPEN` | warn — must not depend on the lead word |
| 4 | **Negative control.** Doc in `2-WORKING`, issue OPEN, genuinely in progress | cache `904 OPEN` | **no finding** — the whole point is not to nag live work |
| 5 | Existing direction (a): doc in `2-WORKING`, issue CLOSED | cache `905 CLOSED` | warn, `recommend: git mv …` (must still pass) |
| 6 | No `gh`, no cache | unset cache, `PATH` without `gh` | **warn** (`sync not evaluated`), not `info` |
| 7 | Cache written on live lookup | stub `gh` on `PATH`, run once | `.pdda-gh-state.tsv` exists and holds the fetched rows |
| 8 | Offline run after (7) | remove `gh`, keep cache | evaluates from cache; **zero** `sync not evaluated` findings |
| 9 | `2-WORKING` doc with no `gh_issue:` | `MARATHON-PLAN-like.md` | warn — untracked doc |
| 10 | Same doc with `issue_exempt: true` | | **no finding** |
| 11 | **Guardrail.** Any of the above | any | `pdda.sh issue-doc-sync` exits `0` — warn-only, never blocks |

Cases **2, 4, 10, and 11 are the negative controls** and matter more than the positives. Without them a
"fix" that warns on every doc, or one that starts blocking builds, passes every other test. Case 4 in
particular guards the failure mode that would get this check disabled by an irritated operator.

Two cases should be **written first and watched to fail** against the current implementation, proving
they reproduce the live leaks rather than merely asserting the new code agrees with itself:

- Case 1 reproduces GH-15 (doc completed, issue orphaned)
- Case 3 reproduces GH-12 (`Active —` lead word defeats the heuristic)

Also add a `pdda.sh run` roll-up assertion to the existing suite: the `SUMMARY` line for
`pdda-check-issue-doc-sync` must report a non-zero `warns` count when a leak is present. The leaks were
invisible partly because the aggregate summary read clean.

## Out of scope — where this becomes over-engineered

- **Auto-closing issues.** Closing an issue is a human judgment about whether the work is *actually* done.
  PDDA's house style is *recommend, never act* (`stale` prints `recommend: git mv …`). Keep it.
- **Auto-`git mv` of completed docs.** Same reason.
- **A webhook, cron, bot, or daemon.** The check already runs on every `pdda.sh run`. The problem is not
  cadence; it is scope and honesty.
- **An LLM judging doc completeness.** `doc-ready` exists for fuzzy review. This is a deterministic
  comparison of two facts: which folder the doc is in, and what GitHub says.
- **Adding `gh_issue` to `REQUIRED_KEYS`.** It would break every non-issue doc in every installed target.
  Warn-only (P2) buys the visibility without the blast radius.

## Lessons Learned (For Future Agents)

- **Look for the loop before building one.** The instinct on hearing "docs go stale" is to add a
  reconciler. One existed, was well designed, and reported `warns=0` on two real leaks. The bug was in
  *when it stops looking*, not in whether it looks.
- **A check that cannot run must not report success.** Three separate defects this week reduce to that
  sentence: BUG-001b (`observe` mode exits 0), GH-23 (the dead-ref scan only sees `.md`), and this one
  (`gh` absent → `info`). Whenever a check can't evaluate, it must say so at a severity someone reads.
- **Prefer the signal an operator already committed to.** A file's path in the lifecycle tree is a
  deliberate, deterministic act. A `status:` string is prose. Reconcile against the path.
