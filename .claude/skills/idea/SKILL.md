---
name: idea
description: Turn a short operator idea into a PDDA-compliant intake capture — a PROJECT/1-INBOX/GH-<n>-*.md plan-doc skeleton with a synthesized Why + Key Concepts + provisional triage ratings, a filed GitHub issue, and a one-line ROADMAP.md queue park. Asks a short fixed question set, synthesizes the judgment-heavy prose a static template can't, previews everything, and writes only on one confirmation. Sibling front-door to /triage (which handles incoming external reports). Trigger on /idea <one-line idea>, "capture this idea", or "turn this idea into a plan doc / issue".
---

# /idea — raw idea → parked intake capture

Give it a one-line idea. It runs an operator-friendly intake: asks a short fixed question set,
**synthesizes** the judgment-heavy parts a bare template can't (Why, Key Concepts, starting ratings),
then produces a PDDA-compliant on-ramp — a `PROJECT/1-INBOX/GH-<n>-*.md` plan-doc **skeleton**, a filed
GitHub issue, and a ROADMAP queue park. It does **not** build the idea. It stops at a **parked
1-INBOX capture**: making it a runnable marathon lane is a separate, post-promotion step (see the end
of Steps), because a capture has no write-set and hasn't been promoted yet.

This is the **net-new-idea** front-door; [`/triage`](../triage/SKILL.md) is the **incoming-report**
front-door. They are siblings — same PDDA intake format (`PROJECT/PDDA.md` → **GitHub issue intake**,
**Required contract for active docs**, **Triage ratings for medium-large work**), same capture +
ROADMAP-park + verification, same preview-first / confirm-before-outward discipline. Read those files
if a rule here is ambiguous; they are the source of truth. Origin: xyz-3-agents-swarm GH-164 (the
`/idea` sketch; its `hq park` synthesis backend stays in XYZ — this skill is self-sufficient and only
*optionally* hands off to `hq park --create` where a repo ships that interface).

## Usage

```
/idea <one-line idea>    # 4-question intake → single preview → capture (issue + doc + ROADMAP park)
/idea                    # ask for the idea first, then the question set
```

## Steps

0. **Detect PDDA + tools (preflight).**
   - **PDDA repo?** Check for `utils/pdda/pdda.sh` at the repo root. If absent → say so and fall back
     to a **plain doc** at the repo root (or `docs/`): named `GH-<n>-<SLUG>.md` if an issue was made
     (keep the provenance prefix), else `IDEA-<SLUG>.md`. Skip the `ROADMAP.md` park and the `pdda.sh`
     verification — they don't apply. Intake + issue logic still run.
   - **Tools?** `gh` (auth'd) is needed to file the issue. If a `gh` call fails, retry **unsandboxed**
     first (the sandbox blocks the keyring — a false "auth broken") before concluding it's broken.

1. **Intake — ask the fixed question set** (skip any already answered at the trigger; prefer
   `AskUserQuestion`). Four questions, no branching follow-ups:
   1. **Target repo** — default the current repo; confirm only if ambiguous.
   2. **One-line idea** — skip if already given.
   3. **Rough shape** — `quick fix` / `feature` / `spike (explore-only)` / `multi-phase build`. Maps
      to a starting ratings guess **and** `doc_type` (see the table under the doc template).
   4. **Known related docs/issues** — optional free text, or "none".

2. **Synthesize (the judgment layer).** From the idea + answers, draft: a **Why** paragraph, **Key
   Concepts** bullets, `non_goals` stubs, and starting **triage ratings** (always
   `ratings_provisional: true`). Seed `related` from question 4. A rough rating is safe to ship as a
   *starting* value **because PDDA's selection rule excludes `ratings_provisional: true` docs from
   auto-eligibility** (`PROJECT/PDDA.md` → Triage ratings) — so a wrong guess parks itself out of
   auto-selection rather than misfiring. Don't agonize; mark it provisional and move on. Never invent
   facts about code you didn't read — mark gaps `TODO(operator)`.

3. **Preview the whole capture as one bundle, then get ONE confirmation.** Render, together: the
   `gh issue create` title + body, the full synthesized doc (using a `GH-<new>` placeholder for the
   number), and the ROADMAP queue line. This single preview **is** the human checkpoint. Nothing is
   written or filed before the operator confirms.

4. **On confirm, execute in order** (issue-first SOP — net-new work above a 2–3 line fix needs an issue):
   - `gh issue create` on the target repo's `origin` → capture the returned number `<n>`. (If the
     operator named an existing issue to attach to, reuse that number and skip creation; first check
     for an existing `GH-<n>-*.md` and update it rather than writing a second doc.)
   - Write the capture doc at `PROJECT/1-INBOX/GH-<n>-<SHORT-SLUG>.md` (SCREAMING-KEBAB, ~2–4 words,
     no zero-padding), substituting the real `<n>`. Use the skeleton template below.

5. **Park a one-line ROADMAP.md queue pointer** under `### Queue / parked intake` — required at capture
   time (`ROUTER.md` canonical rules; `PROJECT/PDDA.md` → ROADMAP.md contract). Format:

   ```md
   - **GH-<n> — <short title>** (<YYYY-MM-DD>) - <one-line idea + shape>. Captured via /idea. Issue
     [#<n>](<origin-issue-url>). -> [PROJECT/1-INBOX/GH-<n>-<SLUG>.md](PROJECT/1-INBOX/GH-<n>-<SLUG>.md)
   ```

6. **Report + verify** with `utils/pdda/pdda.sh roadmap-coverage` (confirms the capture is parked).
   Note: `pdda.sh frontmatter` scans `2-WORKING` only, so it does **not** validate a 1-INBOX capture —
   don't claim it did. If `.pdda-quad` is on, also run `pdda.sh quad-concepts` (1-INBOX/GH-* is in
   quad scope). Report the doc path, the issue, and the ROADMAP entry.

**After capture — making it a marathon lane (separate, not part of /idea).** The capture is parked in
`1-INBOX` with `status: Proposed` and unchecked Phase 0 boxes; it is **not** marathon-fireable yet.
To queue it: a human **promotes** it `1-INBOX → 2-WORKING` (add the `## Status` table + per-phase QA
gates, name the concrete write-set), *then* adds it to a `MARATHON-PLAN-*.md` — and, if this repo runs
marathons from executable YAML + per-lane briefs (`marathon/*.yaml`), the matching YAML/brief too.
Queuing is never auto-firing.

## Doc template

**Rough-shape → starting ratings + doc_type** (all `ratings_provisional: true`; `complexity/risk/effort`, `phases`):

| Shape | `doc_type` | cx / risk / eff | phases |
|---|---|---|---|
| quick fix | `bugfix` | 1 / 1 / 1 | 1 |
| feature | `feature` | 3 / 2 / 3 | 2–4 |
| spike (explore-only) | `spike` | 2 / 1 / 1 | 1 |
| multi-phase build | `project` | 4 / 3 / 4 | 3+ |

Frontmatter — PDDA minimum for a `GH-*` capture + provisional triage ratings (`PROJECT/PDDA.md`).
`non_goals` lives **only** here (single source — do not repeat it as a body section):

```yaml
---
title: <concise idea title>
status: Proposed (1-INBOX — not yet active)
created: <YYYY-MM-DD>
owner: <git config user.name, else noel>
gh_issue: <n>
source: <origin issue URL>
doc_type: feature            # from the rough-shape table above
complexity: <1-5>
risk: <1-5>
effort: <1-5>
phases: <n>
ratings_provisional: true
non_goals:
  - <what this deliberately will not do>
related:
  - <seeded from question 4, or omit the key>
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
<!-- If .pdda-quad is on, add a Quad Concepts section (1–4 `pain → fix` bullets):
## Quad Concepts
- <pain this idea addresses> → <how it addresses it>
-->

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
- [ ] Name the concrete deliverable + its write-set (needed before it can be a marathon lane)
- [ ] Decide the tool shape — reuse an existing command/script before new infrastructure (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires
```

## Guardrails

- **Don't build here.** This skill captures + scopes an idea; it does not implement it, and it stops
  at a parked 1-INBOX capture (no marathon queue — that's a post-promotion step).
- **Synthesize, don't fabricate scope.** Ratings are always `ratings_provisional: true` (PDDA's
  selection rule excludes provisional docs from auto-eligibility). Never invent facts about code you
  didn't look at — mark gaps `TODO(operator)`.
- **One preview, one confirmation.** Render the issue + doc + ROADMAP line together and write/file
  nothing until the operator confirms once; then create the issue, write the doc, park the pointer.
- **Outward-facing steps confirm first.** `gh issue create` is durable and public (`AGENTS.md` #2/#3).
- **One doc per issue.** Before writing, check for an existing `GH-<n>-*.md` and update it instead.
- **Verify with the check that covers the path.** A 1-INBOX capture is verified by `roadmap-coverage`
  (+ `quad-concepts` when enabled), not `frontmatter` (which scans `2-WORKING` only).
- **Repo-relative paths only** in the doc — no absolute local paths.
