---
gh_issue: 23
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/23
title: "Agent on-ramp is wrong, expensive, and unenforced: targets inherit the canonical repo's ROUTER.md verbatim"
status: Active — promoted to 2-WORKING 2026-07-09; P1 not yet started
created: 2026-07-09
updated: 2026-07-09
owner: noel
doc_type: bugfix
effort: 3
complexity: 3
risk: 2
phases: 4
context_tags: [installer, governance, hooks, router, agent-onboarding]
related: [install.sh, ROUTER.md, utils/pdda/pdda.sh, SKILLS/PDDA-hook/SKILL.md, PROJECT/1-INBOX/GH-21-PDDA-HOOK-SKILL.md]
goal: >
  Make the agent on-ramp into a PDDA target correct, cheap, and enforced: stop shipping the canonical repo's ROUTER.md
  into targets (it names install.sh and pdda-sync.sh, neither of which exists there), catch that class of
  drift at install time and in pdda-check-governance, and replace the one SessionStart directive that is
  both expensive and unverifiable with a single cheap action.
---

# GH-23 — Agent on-ramp: wrong, expensive, unenforced

Capture of GitHub issue [#23](https://github.com/Hypercart-Dev-Tools/pdda/issues/23).
Full write-up lives on the issue; this is the in-repo back-reference.

## Status

| What was just completed | What's next |
|---|---|
| Promoted `1-INBOX → 2-WORKING`; branch `gh-23-agent-onramp` rebased onto `main`. All four cited code claims independently re-verified. **Target-side symptom reproduced end-to-end against the live `LTVera-Pandas` install**, captured as a regression fixture at `test/fixtures/gh-23/LTVera-Pandas-ROUTER.md`. One mechanism correction found — see "Reproduction". | **P1** — stop shipping the canonical repo's router into targets, then make `install.sh --help` stop claiming "adapted". Every phase lands green on `utils/pdda/pdda.sh run`. |

## Verification of the brief

Every claim in the intake was re-checked against the working tree before any code was written. All four
hold exactly as stated:

| Claim | Verified |
|---|---|
| `install.sh:65` advertises an "adapted" `ROUTER.md` | Yes — `--with-startup-docs    Also install adapted ROUTER.md + AGENTS.md + …` |
| `install.sh:456-461` calls `copy_runtime` for it | Yes — four `copy_runtime` calls, `ROUTER.md` first |
| `install.sh:244` documents `copy_runtime` as verbatim | Yes — `# Copy a runtime file verbatim, always`; the body is a bare `cp "$src" "$dst"` |
| `pdda.sh:631-645` matches `.md` refs only | Yes — both `grep -oE` patterns hard-require `\.md`, and the function's own comment states the limit |

## Reproduction (2026-07-09, `LTVera-Pandas`)

Read-only, against the live target at `~/Documents/GitHub-Repos/LTVera-Pandas`. `pdda.sh` was **not**
executed there (it appends to that repo's `PROJECT/PDDA-ACTIVITY.jsonl`); instead the canonical repo's own
`_pdda_gov_scannable_lines` and `_pdda_gov_extract_refs` were exercised directly against the target's
`ROUTER.md`, which is the exact code path `pdda-check-governance` would take.

**The copy is verbatim, and provably so.** The target's `ROUTER.md` is byte-identical (`md5
3c1722da…`) to the canonical repo's `ROUTER.md` at commit `5e2205b` ("Add Project Memory Layer docs", 2026-07-06). Not
adapted, not stripped — `cp`.

**Dead refs in the target:**

| Ref | In target | Seen by the check |
|---|---|---|
| `install.sh` (L15) | **absent** | no — not `.md` |
| `utils/pdda/pdda-sync.sh` (L72, L73, L74, L82) | **absent** | no — not `.md` |
| `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md` (L83) | **absent** | yes — the one warn |
| `utils/pdda/pdda.sh` | present | n/a — live, must stay unflagged (negative control) |

The extractor returns **35 refs, all `.md`, zero `.sh`.** Target `.pdda-mode` is `observe`, so the run
exits 0 regardless; combined with the single warn, the operator sees "all checks passed" over a router
that names two scripts the repo does not contain.

### Mechanism correction: the fence is not the reason

The intake says the `pdda-sync.sh` invocations at `ROUTER.md:72-74` "sit inside a ``` fence and match
neither existing regex, so they are invisible twice over." **The fence half is wrong.**
`_pdda_gov_scannable_lines` (`pdda.sh:614`) exempts only ` ```console `, ` ```text `, and
` ```transcript ` fences. Lines 72-74 sit in a ` ```bash ` fence, and were confirmed present in the
scanner's output. They are scanned; they are simply never matched.

So the invisibility has **one** cause, not two — but that cause has two independent parts, and P3 must
fix both:

1. **The `.md` suffix requirement.** Widening to `.sh` alone would catch L15 (`` `install.sh` ``) and
   L82 (`` `utils/pdda/pdda-sync.sh` ``), which are backtick-wrapped.
2. **The ref *shape*.** L72-74 are bare command invocations — no backticks, no markdown link. They
   match neither existing pattern regardless of suffix. Catching them needs a third pattern for
   command-position paths inside a scanned fence, which is also where the false-positive risk lives
   (`pdda.sh run` must not be read as a path).

This makes the P3 negative control load-bearing rather than a formality: the same widening that catches
`pdda-sync.sh` at L72 is the one that could misread `pdda.sh run` at L48.

### Regression fixture

Today's target `ROUTER.md` captured verbatim at
[test/fixtures/gh-23/LTVera-Pandas-ROUTER.md](../../test/fixtures/gh-23/LTVera-Pandas-ROUTER.md)
(87 lines, `md5 3c1722da561073073a1313afa5c1123d`). Satisfies the acceptance criterion. `test/` is the
repo's existing convention — `test/pdda-governance-check.sh` is the suite P3 extends.

One immaterial correction: the `copy_runtime` comment sits at **`install.sh:245`**, not `:244` — line 244
is the closing brace of the preceding function. The finding is unaffected.

## Phase ledger

| Phase | State | Gate |
|---|---|---|
| P1 — template the target router; make `--help` true | Not started | `pdda.sh run` green |
| P2 — post-install self-check on `*.sh` refs | Not started | `pdda.sh run` green |
| P3 — widen `_pdda_gov_extract_refs` to `.sh` + fenced blocks | Not started | `pdda.sh run` green + negative control |
| P4 — cheap directive 1; opt-in default-off `PreToolUse` gate | Not started | `pdda.sh run` green |

## Problem

An agent arriving in a PDDA **target** repo is pointed at a `ROUTER.md` that describes the **canonical repo**,
then asked to read ~66KB across three files before touching anything, and nothing verifies it
did. Wrong, expensive, unenforced — in that order.

Found 2026-07-09 by dogfooding in the `LTVera-Pandas` target. The `SKILLS/PDDA-hook`
`SessionStart` reminder (#21) fired correctly and auto-scoped correctly. The agent then followed
directives 2/3/5 (cheap, checkable), silently skipped directive 1 (expensive, unverifiable), and
`pdda.sh run` reported **0 errors** anyway.

## Three verified findings

1. **`--with-startup-docs` does not adapt anything.** `install.sh:65` advertises an "adapted
   ROUTER.md + AGENTS.md + GUIDING-PRINCIPLES.md". `install.sh:456-461` calls `copy_runtime`,
   documented at `install.sh:244` as *"Copy a runtime file verbatim, always."* It is `cp`.

2. **So targets get the canonical repo's router.** `LTVera-Pandas`'s `ROUTER.md` tells agents to run `install.sh`
   and `utils/pdda/pdda-sync.sh` — neither exists there — and carries a "distribute this runtime
   from this clone (the canonical repo)" command-rails block plus install/sync routing hints. Verified absent in
   target, present in the canonical repo.

3. **The deterministic surface cannot see it — by design.** `_pdda_gov_extract_refs`
   (`utils/pdda/pdda.sh:631-645`) matches only refs ending in `.md`; its own comment says so.
   The dead `.sh` refs were never in scope. `pdda-check-governance` flagged the one dead `.md`
   link and stayed silent on the rest.

   Not a defect in the check. But a doc telling an agent to run a missing script is the same
   class of harm as a dead doc link, and it ships undetected today.

## Why directive 1 is the one that gets dropped

Directives 3 (`run pdda.sh run`) and 5 (`update CHANGELOG.md`) are cheap and checkable, so they
get followed. Directive 1 — read ROUTER.md + a **60.4KB** AGENTS.md + the project doc — is
neither, so under context pressure an agent reconstructs conventions by pattern-matching a
sibling doc instead. That is exactly the "governed by memory, not deterministically" failure
PDDA exists to prevent.

`ROUTER.md:87` already names the cheap action for mid-session use (`invoke the /pdda skill …
instead of re-reading by hand`). If that is right mid-session, it is right at session start.

## Phases

- **P1 — Stop shipping the canonical repo's router into targets.** Split `ROUTER.md` into a canonical router plus a
  `templates/ROUTER.target.md` the installer writes, or strip canonical-only sections on copy. Make the
  `--help` text true.
- **P2 — Post-install self-check.** After `--with-startup-docs`, assert no `` `*.sh` `` ref in the
  target's `ROUTER.md` points at a file absent from the target. Catches this at install time.
- **P3 — Widen dead-ref scanning to executable refs.** Extend `_pdda_gov_extract_refs` past `.md`
  to `.sh`; consider fenced-block command lines (the `pdda-sync.sh` invocations at `ROUTER.md:72-74`
  are inside a fence and match neither regex — invisible twice over). Keep the bare-filename
  repo-wide fallback. Warn-only first, per house style.
- **P4 — Cheap, then verifiable.** Reminder directive 1 leads with `/pdda`. Add an **opt-in,
  default-off** `PreToolUse` gate on `Write|Edit` scoped to `PROJECT/**`, `ROADMAP.md`,
  `CHANGELOG.md` that fires when ROUTER.md was never read this session.

## Acceptance criteria

- [ ] A `--with-startup-docs` install yields a `ROUTER.md` with zero refs to files absent from that repo.
- [ ] `install.sh --help` describes what the flag actually does.
- [ ] `pdda-check-governance` flags a dead `.sh` ref; negative control confirms no over-flagging of
      live refs (`utils/pdda/pdda.sh`) or non-path code spans (`` `pdda.sh run` ``).
- [ ] Today's `LTVera-Pandas` `ROUTER.md` becomes a regression fixture that reports the dead refs.
- [ ] The `SessionStart` reminder's first directive names a single cheap action.
- [ ] Any `PreToolUse` gate ships default-off and is documented; `SKILLS/PDDA-hook/SKILL.md`'s
      *"does not touch `PreToolUse`"* line is amended rather than left contradicted.

## Out of scope

- Shrinking `AGENTS.md`. Its size is a symptom; the fix is to stop making a 60KB read a
  precondition for a two-line doc edit.
- `SKILLS/PDDA-hook`'s guardrails around committed `.claude/settings.json`. Those are correct.
- Retroactively repairing installed targets — `pdda-sync.sh push` handles that once P1/P2 land.

## Lessons Learned (For Future Agents)

The hook was not the failure. It fired, scoped, and injected exactly as #21 designed. The failure
was that **compliance with an injected reminder is still voluntary**, and an agent will drop
whichever directive is most expensive and least checkable. If a governance step matters, it needs
to be either cheap enough that skipping it saves nothing, or gated by something that notices.

Secondary lesson: `pdda.sh run` returning "all checks passed" is evidence about the checks, not
about the reader. It passed here on a router that was actively misdirecting agents.
