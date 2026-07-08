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
front-door. They are siblings — same PDDA intake format, same capture + ROADMAP-park + `pdda.sh`
validation, same preview-first / confirm-before-outward discipline — differing only in their input
(an external report here; an operator idea there).

This skill produces artifacts, so it follows the canonical PDDA intake format
(`PROJECT/PDDA.md` → **GitHub issue intake**, **Required contract for active docs**,
**Triage ratings for medium-large work**). Read those if a rule here is ambiguous; the files are the
source of truth.

## Usage

```
/triage <report-url>                 # resolve/open a tracking issue, then capture
/triage <report-url> --issue <n>     # append to an existing origin issue #<n> (don't open a new one)
/triage <report-url> --working       # skip 1-INBOX; write straight to 2-WORKING as active work
```

## Steps

0. **Detect PDDA (preflight).** Check for `utils/pdda/pdda.sh` at the repo root.
   - **PDDA repo** → run the full flow below (capture into `PROJECT/1-INBOX/`, park in `ROADMAP.md`,
     validate with `pdda.sh frontmatter`).
   - **Not a PDDA repo** → say so, then fall back to a **plain remediation doc** at the repo root (or
     `docs/` if it exists) named `TRIAGE-<SHORT-SLUG>.md`. Keep the same frontmatter and checklist
     template, but skip the `ROADMAP.md` park and the `pdda.sh` validation (Steps 5 and 7's check) —
     they don't apply. The tracking-issue and light-validation logic (Steps 1–4) still run.

1. **Fetch the report.**
   - GitHub URL (issue/PR/comment): use `gh issue view <url> --comments` (or `gh pr view`) — it is
     cheap and structured. Capture the title, author, created date, body, and comment substance.
   - Non-GitHub URL: fetch it (WebFetch, or `ctx_fetch_and_index` per this repo's context guidance) and
     keep the raw text in the scratchpad, not in the doc.

2. **Triage the content (first pass, light).** Read the whole thing once, then:
   - **Distill** the actual defects/asks — separate signal from noise, dedupe, drop meta-chatter.
   - **Light-validate each claim** with *cheap* checks only (does the named file/path/symbol exist?
     is the described behavior plausible at a glance? does a quick grep/`codebase-memory` lookup back
     it up?). Classify each: **Confirmed / Plausible / Unclear / Can't-reproduce**. Do **not** do full
     reproduction here — that is Phase 2 in the doc.
   - **Rate the work** with the four triage fields (`effort`, `complexity`, `risk`, `phases`), integers
     `1`–`5` (`phases` positive). `risk` tracks the `Easy / Costly / One-way door` scale.
   - **Pick `doc_type`**: `bugfix` for a defect report, `feedback` for broader feedback/enhancement.

3. **Resolve the tracking GitHub issue** (issue-first SOP — remediation beyond a 2–3 line fix needs one):
   - If `--issue <n>` was given → use that origin issue number; skip creation.
   - Else if the report URL is itself an issue on **origin** (`git remote get-url origin`) → reuse its
     number.
   - Else (foreign-repo issue or non-issue URL) → this is outward-facing, so **confirm before acting**:
     offer to `gh issue create` a tracking issue on origin (title = remediation title, body links the
     report URL), or ask the user for an existing issue number to append to. Do not silently open issues.
   - `<n>` resolves against origin; a foreign source is disambiguated by the `source:`/`report_url:` URL.

4. **Write the capture doc.** Default path `PROJECT/1-INBOX/GH-<n>-<SHORT-SLUG>.md` (SCREAMING-KEBAB,
   ~2–4 words, no zero-padding). With `--working`, write to `PROJECT/2-WORKING/` and add the full
   active-doc contract (Status table + per-phase QA gates). Use the template below. Compute `phases:`
   from the sections you actually emit.

5. **Park a one-line ROADMAP.md queue pointer** under `### Queue / parked intake` — required at capture
   time (`ROUTER.md` canonical rules; `PROJECT/PDDA.md` → ROADMAP.md contract). Format:

   ```md
   - **GH-<n> — <short title>** (<YYYY-MM-DD>) - <one-line what+why>. Triaged from <report source>. Issue
     [#<n>](<origin-issue-url>). -> [PROJECT/1-INBOX/GH-<n>-<SLUG>.md](PROJECT/1-INBOX/GH-<n>-<SLUG>.md)
   ```

6. **(Optional, confirm first)** Post a back-link comment on the tracking issue
   (`gh issue comment <n>`) noting the remediation doc path. Outward-facing — only with the user's OK.

7. **Report**: the doc path, the tracking issue, the ROADMAP entry, and the count of Confirmed vs
   Unclear claims deferred to Phase 2. Then run `utils/pdda/pdda.sh frontmatter` to confirm the new
   doc's frontmatter validates.

## Doc template

Frontmatter — the PDDA minimum for a `GH-*` capture plus triage ratings (`PROJECT/PDDA.md`):

```yaml
---
title: <concise remediation title>
status: Proposed (1-INBOX — not yet active)   # with --working: an active status + a ## Status table
created: <YYYY-MM-DD>
owner: noel
gh_issue: <n>
source: <origin tracking-issue URL>            # the issue gh_issue points to
report_url: <original incoming report URL>     # what /triage was pointed at (== source if URL is the origin issue)
doc_type: bugfix                               # or: feedback
effort: <1-5>
complexity: <1-5>
risk: <1-5>
phases: <n>
---
```

Body:

```md
# GH-<n> — <Title>

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

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
| 1 | <claim> | Confirmed / Plausible / Unclear / Can't-reproduce | <path:line or note> |

## Remediation checklist

### Phase 1 — Triage & confirm scope  (this pass)
- [x] Distill report into discrete defects/asks (Problem summary)
- [x] Light validation pass (table above)
- [ ] Confirm severity + triage ratings with operator

### Phase 2 — Deeper exploration / reproduction  (spike)
> Discovery phase: its findings must be written **back into this doc** (fill the Validation table +
> notes below) before this phase's gate can pass (`PROJECT/PDDA.md` → Discovery & spike phases).
- [ ] Reproduce each **Plausible / Unclear** claim
- [ ] Trace each confirmed defect to root cause (`codebase-memory` / grep / read)
- [ ] Update the Validation table with Confirmed/Rejected + concrete evidence
- [ ] Capture any newly discovered adjacent issues here

### Phase 3 — Fix
<one checklist item per confirmed defect; add the fix approach>
- [ ] <defect A> — <approach>
- [ ] <defect B> — <approach>

### Phase 4 — Verify
- [ ] <verification step per fix>
- [ ] `utils/pdda/pdda.sh run` (or the narrower relevant check) is clean
- [ ] Link the fix commit(s) back to #<n>

## Non-goals
- <what this remediation explicitly will not cover>
```

## Guardrails

- **Don't fix here.** This skill scopes the remediation; it does not implement it.
- **Light first pass only.** Full reproduction and root-cause tracing belong to Phase 2, whose findings
  get written back into the doc — don't front-load them into the capture.
- **Outward-facing steps confirm first.** Creating a GitHub issue or commenting on one is durable and
  public — never do it silently (`AGENTS.md` #2/#3 reversibility).
- **Stay contract-compliant.** 1-INBOX captures carry no `## Status` table; frontmatter is the PDDA
  minimum + triage ratings; the ROADMAP park is required at capture. Verify with
  `utils/pdda/pdda.sh frontmatter` before reporting done.
- **Repo-relative paths only** in the doc — no absolute local paths.
