---
name: triage
description: Turn an incoming long/large-format feedback or bug report (pointed to by URL) into a PDDA-compliant remediation project doc built from checklists. Fetches the report, does a light first-pass validation of the problem, resolves or opens the tracking GitHub issue, writes a new PROJECT/1-INBOX/GH-<n>-*.md capture with checklist phases (including a dedicated deeper-exploration phase), and parks a one-line ROADMAP.md queue pointer. Trigger on /triage <url>, "triage this report/feedback/bug", or when handed a URL to a wall-of-text issue that needs to become actionable remediation work.
---

# /triage — incoming report → remediation checklist doc

Point this at a URL for a long-format feedback thread or bug report. It transforms that report
into a **remediation project doc** in this repo: PDDA-compliant frontmatter, a distilled problem
summary, a **light first-pass validation** of the claims, and a **checklist-driven phase plan** with
an explicit deeper-exploration phase. It does **not** attempt the fixes — it produces the doc that
scopes them.

This is the **incoming-report** front-door; [`/idea`](../idea/SKILL.md) is the **net-new-idea**
front-door. They are siblings — same PDDA intake format, same capture + ROADMAP-park + verification,
same preview-first / confirm-before-outward discipline — differing only in their input (an external
report here; an operator idea there).

This skill produces artifacts, so it follows the canonical PDDA intake format
(`PROJECT/PDDA.md` → **GitHub issue intake**, **Required contract for active docs**,
**Triage ratings for medium-large work**). Read those if a rule here is ambiguous; the files are the
source of truth.

## Usage

```
/triage <report-url>                 # resolve/open a tracking issue, then capture into 1-INBOX
/triage <report-url> --issue <n>     # append to an existing origin issue #<n> (don't open a new one)
/triage <report-url> --working       # skip 1-INBOX; write straight to 2-WORKING as active work
```

## Steps

0. **Detect PDDA + tools (preflight).**
   - **PDDA repo?** Check for `utils/pdda/pdda.sh` at the repo root. If absent → say so and fall back
     to a **plain doc** at the repo root (or `docs/`): named `GH-<n>-<SLUG>.md` if an issue exists,
     else `TRIAGE-<SLUG>.md`. Keep the frontmatter + checklist template, but skip the `ROADMAP.md`
     park and the `pdda.sh` verification — they don't apply. Steps 1–4 still run.
   - **Tools?** This flow needs `gh` (auth'd) for GitHub URLs and a fetch tool for others. If a GitHub
     `gh` call fails, first retry **unsandboxed** (the sandbox blocks the keyring — a false "auth
     broken"); if it still fails, capture what you can from the URL by hand and note the gap in the
     doc rather than dead-ending.

1. **Fetch the report.**
   - GitHub URL (issue/PR/comment): use `gh issue view <url> --comments` (or `gh pr view`). Capture
     title, author, created date, body, and comment substance.
   - Non-GitHub URL: fetch it (WebFetch, or `ctx_fetch_and_index` per this repo's context guidance);
     keep the raw text in the scratchpad, not in the doc. If no fetch tool is available, ask the
     operator to paste the content.

2. **Triage the content (first pass, light).** Read the whole thing once, then:
   - **Distill** the actual defects/asks — separate signal from noise, dedupe, drop meta-chatter.
   - **Light-validate each claim** with *cheap* checks only (does the named file/path/symbol exist?
     is the described behavior plausible at a glance? does a quick grep/`codebase-memory` lookup back
     it up?). Classify each: **Confirmed / Plausible / Unclear / Not-yet-verified**. Do **not** do full
     reproduction here — that is Phase 2 in the doc.
   - **Rate the work** with the four triage fields (`effort`, `complexity`, `risk`, `phases`), integers
     `1`–`5` (`phases` positive). `risk` tracks the `Easy / Costly / One-way door` scale.
   - **Pick `doc_type`**: `bugfix` for a defect report, `feedback` for broader feedback/enhancement.

3. **Resolve the tracking GitHub issue** (issue-first SOP — remediation beyond a 2–3 line fix needs one):
   - If `--issue <n>` was given → use that origin issue number; **skip creation**. First check for an
     **existing** `GH-<n>-*.md` in `PROJECT/{1-INBOX,2-WORKING,3-COMPLETED}`; if one exists, update it
     rather than writing a second doc for the same issue.
   - Else decide origin-vs-foreign by **normalizing** both URLs before comparing — reduce
     `git remote get-url origin` and the report URL to `host/owner/repo` (strip a `.git` suffix;
     treat SSH `git@host:owner/repo` and HTTPS `https://host/owner/repo` as equal). If the report is
     an issue on **origin** → reuse its number.
   - Else (foreign-repo issue or non-issue URL) → outward-facing, so **confirm before acting**: offer
     to `gh issue create` a tracking issue on origin (title = remediation title, body links the report
     URL), or ask for an existing issue number. Do not silently open issues. If the operator declines
     and gives no number, name the doc `GH-LOCAL-<SLUG>.md` and set `gh_issue: local` (park it anyway).

4. **Write the capture doc.**
   - **Default (1-INBOX):** `PROJECT/1-INBOX/GH-<n>-<SHORT-SLUG>.md` (SCREAMING-KEBAB, ~2–4 words, no
     zero-padding). Use the **capture** template below — no `## Status` table.
   - **`--working` (2-WORKING):** use the **active-doc** template — it MUST additionally carry
     `updated` + `goal` frontmatter and a populated `## Status` table, plus (if multi-phase) a
     `## Table of contents` and per-phase QA gates. Compute `phases:` from the sections you emit.

5. **Park the ROADMAP.md pointer** — required at capture time (`ROUTER.md` canonical rules;
   `PROJECT/PDDA.md` → ROADMAP.md contract). Put it in the **right section**:
   - **1-INBOX capture →** under `### Queue / parked intake`:
     ```md
     - **GH-<n> — <short title>** (<YYYY-MM-DD>) - <one-line what+why>. Triaged from <report source>. Issue
       [#<n>](<origin-issue-url>). -> [PROJECT/1-INBOX/GH-<n>-<SLUG>.md](PROJECT/1-INBOX/GH-<n>-<SLUG>.md)
     ```
   - **`--working` active doc →** under the active-work ledger (e.g. `### In progress`), not the queue
     section (the queue is the parking slot for un-promoted intake).

6. **(Optional, confirm first)** Post a back-link comment on the tracking issue
   (`gh issue comment <n>`) noting the remediation doc path. Outward-facing — only with the user's OK.

7. **Report + verify with the check that actually covers the path you wrote:**
   - **1-INBOX capture →** `utils/pdda/pdda.sh roadmap-coverage` (confirms the capture is parked).
     `pdda.sh frontmatter` scans `2-WORKING` only, so it does **not** validate a 1-INBOX doc — don't
     claim it did.
   - **`--working` active doc →** `utils/pdda/pdda.sh frontmatter` **and** `status-table` **and**
     `roadmap-coverage`.
   - If `.pdda-quad` is on, also run `pdda.sh quad-concepts` (1-INBOX/GH-* is in quad scope).
   Then report the doc path, the tracking issue, the ROADMAP entry, and the count of Confirmed vs
   Not-yet-verified claims deferred to Phase 2.

## Doc template

Frontmatter — the PDDA minimum for a `GH-*` capture plus triage ratings (`PROJECT/PDDA.md`).
`--working` adds `updated`, `goal`, and the `## Status` table (see Step 4):

```yaml
---
title: <concise remediation title>
status: Proposed (1-INBOX — not yet active)   # --working: an active status
created: <YYYY-MM-DD>
# updated: <YYYY-MM-DD>                        # --working only
owner: <git config user.name, else noel>
# goal: >                                      # --working only
#   <2–4 lines: what the remediation delivers>
gh_issue: <n>
source: <origin tracking-issue URL>            # the issue gh_issue points to
report_url: <original incoming report URL>     # what /triage was pointed at (== source if URL is the origin issue)
doc_type: bugfix                               # or: feedback
effort: <1-5>
complexity: <1-5>
risk: <1-5>
phases: <n>
non_goals:
  - <what this remediation explicitly will not cover>
---
```

Body:

```md
# GH-<n> — <Title>

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).
<!-- --working: replace the note above with a populated ## Status table:
## Status
| What was just completed | What's next |
|---|---|
| Triaged #<n> into this doc + light validation | Phase 2 reproduction spike |
-->
<!-- If .pdda-quad is on, add after Status:
## Quad Concepts
- <pain this remediation addresses> → <how it addresses it>   (1–4 bullets)
-->

## Source report
- **Report:** <report_url>
- **Tracking issue:** #<n> — <origin-issue-url>
- **Reported by / date:** <author> — <date>
- **Scale:** <lines / comments> triaged (not transcribed whole)

## Problem summary
<2–5 sentences: the real defects/asks, signal separated from noise.>

## Validation — first pass (light)
Cheap checks only; full reproduction is Phase 2.

| # | Claim from report | First-pass read | Evidence |
|---|---|---|---|
| 1 | <claim> | Confirmed / Plausible / Unclear / Not-yet-verified | <path:line or note> |

## Remediation checklist

### Phase 1 — Triage & confirm scope  (this pass)
- [x] Distill report into discrete defects/asks (Problem summary)
- [x] Light validation pass (table above)
- [ ] Confirm severity + triage ratings with operator

### Phase 2 — Deeper exploration / reproduction  (spike)
> Discovery phase: its findings must be written **back into this doc** (fill the Validation table +
> notes below) before this phase's gate can pass (`PROJECT/PDDA.md` → Discovery & spike phases).
- [ ] Reproduce each **Plausible / Not-yet-verified** claim
- [ ] Trace each confirmed defect to root cause (`codebase-memory` / grep / read)
- [ ] Update the Validation table with Confirmed/Rejected + concrete evidence
- [ ] Capture any newly discovered adjacent issues here

### Phase 3 — Fix
<one checklist item per confirmed defect; fill the approach in AFTER the Phase 2 spike, not now>
- [ ] <defect A>
- [ ] <defect B>

### Phase 4 — Verify
- [ ] <verification step per fix>
- [ ] `utils/pdda/pdda.sh run` (or the narrower relevant check) is clean
- [ ] Link the fix commit(s) back to #<n>
```

## Guardrails

- **Don't fix here.** This skill scopes the remediation; it does not implement it.
- **Light first pass only.** Full reproduction and root-cause tracing belong to Phase 2, whose findings
  get written back into the doc — don't front-load them, and don't pre-write Phase 3 fix approaches.
- **Outward-facing steps confirm first.** Creating a GitHub issue or commenting on one is durable and
  public — never do it silently (`AGENTS.md` #2/#3 reversibility).
- **Verify with the check that covers the path you wrote** (Step 7): `frontmatter` only sees
  `2-WORKING`; a 1-INBOX capture is verified by `roadmap-coverage` (+ `quad-concepts` when enabled).
  Don't report a validation you didn't actually run against the new file.
- **One doc per issue.** Before writing, check for an existing `GH-<n>-*.md` and update it instead.
- **Repo-relative paths only** in the doc — no absolute local paths.
