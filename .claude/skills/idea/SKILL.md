---
name: idea
description: Turn a short operator idea into a PDDA-compliant intake capture — a PROJECT/1-INBOX/GH-<n>-*.md plan-doc skeleton with a synthesized Why + Key Concepts + provisional triage ratings, a filed GitHub issue, and a one-line ROADMAP.md queue park, optionally queued into today's marathon. Asks a short fixed question set, synthesizes the judgment-heavy prose a static template can't, previews everything, and writes only on one confirmation. Sibling front-door to /triage (which handles incoming external reports). Trigger on /idea <one-line idea>, "capture this idea", "turn this idea into a plan doc / issue", or "queue this idea for a marathon".
---

# /idea — raw idea → queued intake capture

Give it a one-line idea. It runs an operator-friendly intake: asks a short fixed question set,
**synthesizes** the judgment-heavy parts a bare template can't (Why, Key Concepts, starting ratings),
then produces a PDDA-compliant on-ramp — a `PROJECT/1-INBOX/GH-<n>-*.md` plan-doc **skeleton**, a filed
GitHub issue, and a ROADMAP queue park — and optionally queues it into today's marathon. It does **not**
build the idea, and it never auto-fires a marathon: a human checkpoint always remains.

This is the **net-new-idea** front-door; [`/triage`](../triage/SKILL.md) is the **incoming-report**
front-door. They are siblings — same PDDA intake format (`PROJECT/PDDA.md` → **GitHub issue intake**,
**Required contract for active docs**, **Triage ratings for medium-large work**), same capture +
ROADMAP-park + `pdda.sh` validation, same preview-first / confirm-before-outward discipline. Read those
files if a rule here is ambiguous; they are the source of truth. Origin: xyz-3-agents-swarm GH-164
(the `/idea` sketch; its `hq park` synthesis backend stays in XYZ — this skill is self-sufficient and
only *optionally* hands off to `hq park --create` where a repo ships that interface).

## Usage

```
/idea <one-line idea>            # 4-question intake → preview → capture (issue + doc + ROADMAP park)
/idea <one-line idea> --queue    # also queue the capture into today's MARATHON-PLAN as a lane
/idea                            # ask for the idea first, then the question set
```

## Steps

0. **Detect PDDA (preflight).** Check for `utils/pdda/pdda.sh` at the repo root.
   - **PDDA repo** → run the full flow (capture into `PROJECT/1-INBOX/`, park in `ROADMAP.md`,
     validate with `pdda.sh frontmatter`).
   - **Not a PDDA repo** → say so, then fall back to a **plain idea doc** at the repo root (or `docs/`
     if it exists) named `IDEA-<SHORT-SLUG>.md`. Keep the same skeleton, but skip the `ROADMAP.md`
     park, the marathon queue, and the `pdda.sh` validation — they don't apply. Intake + issue logic
     (Steps 1–4) still run.

1. **Intake — ask the fixed question set** (skip any already answered at the trigger; prefer
   `AskUserQuestion`). Four questions, no branching follow-ups:
   1. **Target repo** — default the current repo; confirm only if ambiguous.
   2. **One-line idea** — skip if already given.
   3. **Rough shape** — `quick fix` / `feature` / `spike (explore-only)` / `multi-phase build`. Maps
      to a starting ratings guess (see the table under the doc template).
   4. **Known related docs/issues** — optional free text, or "none".

2. **Synthesize (the judgment layer).** From the idea + answers, draft: a **Why** paragraph, **Key
   Concepts** bullets, `non_goals` stubs, and starting **triage ratings** (always
   `ratings_provisional: true`). Seed `related` from question 4. A rough rating is safe to ship as a
   *starting* value — `marathon-plan` parks an unrated/under-rated doc out of active waves rather than
   misfiring — so do not agonize; mark it provisional and move on.

3. **Resolve/open the GitHub issue** (issue-first SOP — net-new work above a 2–3 line fix needs one).
   This is outward-facing, so **confirm before acting**: show the issue title + body, then
   `gh issue create` on the target repo's `origin`. If the operator names an existing issue to attach
   to, reuse that number instead. Do not silently open issues.

4. **Write the capture doc** at `PROJECT/1-INBOX/GH-<n>-<SHORT-SLUG>.md` (SCREAMING-KEBAB, ~2–4 words,
   no zero-padding — mirror the issue number). Use the skeleton template below. Compute `phases:` from
   the shape (Phase 0 explore-only ⇒ `1`; multi-phase build ⇒ your best guess). **Preview the full doc
   first** and get one confirmation before writing (this is the single human checkpoint — the same gate
   `hq park --create` uses).

5. **Park a one-line ROADMAP.md queue pointer** under `### Queue / parked intake` — required at capture
   time (`ROUTER.md` canonical rules; `PROJECT/PDDA.md` → ROADMAP.md contract). Format:

   ```md
   - **GH-<n> — <short title>** (<YYYY-MM-DD>) - <one-line idea + shape>. Captured via /idea. Issue
     [#<n>](<origin-issue-url>). -> [PROJECT/1-INBOX/GH-<n>-<SLUG>.md](PROJECT/1-INBOX/GH-<n>-<SLUG>.md)
   ```

6. **(Optional) `--queue` → hand off to a marathon.** Never auto-fire. Add the capture as a lane to
   today's `PROJECT/2-WORKING/MARATHON-PLAN-<date>*.md` (collision-map row + per-lane row + `lanes:`
   entry, same shape used elsewhere in that plan), or, if the repo ships `.xyz/utils/marathon-plan.sh`,
   note the command to regenerate/rank. Confirm before editing a shared plan. Queuing ≠ firing.

7. **Report + validate**: the doc path, the issue, the ROADMAP entry, and (if `--queue`) the marathon
   lane. Then run `utils/pdda/pdda.sh frontmatter` to confirm the new doc's frontmatter validates.

## Doc template

**Rough-shape → starting ratings** (all `ratings_provisional: true`; `complexity/risk/effort`, `phases`):

| Shape | cx / risk / eff | phases |
|---|---|---|
| quick fix | 1 / 1 / 1 | 1 |
| feature | 3 / 2 / 3 | 2–4 |
| spike (explore-only) | 2 / 1 / 1 | 1 |
| multi-phase build | 4 / 3 / 4 | 3+ |

Frontmatter — PDDA minimum for a `GH-*` capture + provisional triage ratings (`PROJECT/PDDA.md`):

```yaml
---
title: <concise idea title>
status: Proposed (1-INBOX — not yet active)
created: <YYYY-MM-DD>
owner: noel
gh_issue: <n>
source: <origin issue URL>
doc_type: feature            # or: spike | bugfix — from the rough shape
complexity: <1-5>
risk: <1-5>
effort: <1-5>
phases: <n>
ratings_provisional: true
non_goals:
  - <what this deliberately will not do>
related:
  - <seeded from question 4, or omit>
goal: >
  <2–4 lines: what a marathon-ready version of this idea delivers.>
---
```

Body:

```md
# GH-<n> — <Title>

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Key concepts
- <synthesized: the core of what this idea is and how it would work>

## Idea
<the operator's one-line idea, verbatim>

## Why
<synthesized: the problem it solves / the loop it shortens. Mark any gap `TODO(operator)`.>

## Phase 0 — Explore & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Ground the idea in the real code/trace it touches (not the abstract)
- [ ] Name the concrete deliverable + its write-set (for marathon collision-safety)
- [ ] Decide the tool shape — reuse an existing command/script before new infrastructure (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires

## Non-goals
- <what this idea explicitly will not cover>
```

## Guardrails

- **Don't build here.** This skill captures + scopes an idea; it does not implement it.
- **Synthesize, don't fabricate scope.** Ratings are always `ratings_provisional: true`; a rough guess
  is safe because `marathon-plan` holds unrated/under-rated docs out of active waves. Never invent
  facts about code you didn't look at — mark gaps `TODO(operator)`.
- **Preview-first, one checkpoint.** Render the full doc + the exact `gh issue create` / ROADMAP / lane
  actions, and write only on one operator confirmation.
- **Outward-facing steps confirm first.** `gh issue create` is durable and public — never silent
  (`AGENTS.md` #2/#3 reversibility).
- **Queue ≠ fire.** Never auto-fire a marathon lane; a human always launches (GH-164 non-goal).
- **Compose, don't duplicate.** Where a repo ships `hq park --create` with the `HQ_PARK_*` synthesis
  interface (XYZ/GH-164), you MAY hand the mechanical write to it instead of writing directly — same
  capture + ROADMAP result. PDDA's vendored `hq` lacks it today, so default to the direct write above.
- **Stay contract-compliant.** 1-INBOX captures carry no `## Status` table; frontmatter is the PDDA
  minimum + provisional ratings; the ROADMAP park is required at capture. Verify with
  `utils/pdda/pdda.sh frontmatter`. Repo-relative paths only.
