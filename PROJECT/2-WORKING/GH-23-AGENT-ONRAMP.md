---
gh_issue: 23
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/23
title: "Agent on-ramp is wrong, expensive, and unenforced: targets inherit the canonical repo's ROUTER.md verbatim"
status: Active — P1, P2, P3 shipped; P4 in progress
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
| **P3 shipped**, carrying GH-14 Phase 2 (BUG-001b) with it — the two are one defect. The dead-reference scan now reads `.sh`, including command-position paths that carry arguments; `pdda.sh run` can no longer print *all checks passed* over real errors. Canonical `ROUTER.md` and `GUIDING-PRINCIPLES.md` had their own dead refs removed, the installer's self-check widened past the router, and the shipped-doc exemption manifest grew to hold a fresh install at 0 warns (46 before). Suites: governance 14 → 31, install 33 → 38, new `pdda-run-mode-reporting.sh` 23. | **P4** — (a) SessionStart directive 1 leads with `/pdda`; (b) opt-in, default-off `PreToolUse` gate, amending the PDDA-hook skill's "does not touch PreToolUse" promise in the same commit. |

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
| P1 — template the target router; make `--help` true | **Shipped** — also fixes #25 | `pdda.sh run` green; 16/16 new tests |
| P2 — post-install self-check on `*.sh` refs | **Shipped** | `pdda.sh run` green; suite 16 → 33 |
| P3 — widen `_pdda_gov_extract_refs` to `.sh`; + GH-14 Phase 2 | **Shipped** | `pdda.sh run` green; 7 negative controls; suites 14→31, 33→38, +23 new |
| P4 — cheap directive 1; opt-in default-off `PreToolUse` gate | In progress | `pdda.sh run` green |

## P1 — shipped 2026-07-09

`--with-startup-docs` copied four files through one function. It now routes each by **who owns the file
after the install**, which is the distinction `copy_runtime` was conflating:

| Semantics | Files | Behavior |
|---|---|---|
| **Templated** | `ROUTER.md` | written from `templates/ROUTER.target.md`; the canonical `ROUTER.md` is never copied |
| **Scaffold** | `AGENTS.md`, `GUIDING-PRINCIPLES.md` | create-only; `--force` to overwrite |
| **Runtime** | `.claude/skills/pdda/SKILL.md` | PDDA owns it; refreshed verbatim |

Result: a fresh target's `ROUTER.md` carries **0 canonical-only refs, down from 9**, and reports
`errors=0 warns=0` under its own `pdda.sh run`.

### Scope grew, deliberately

P1 was specified as "stop shipping the canonical router." Checking the *other three* files
`--with-startup-docs` copies surfaced a worse defect in the same four lines: `copy_runtime` has no
create-only guard, so the flag **silently destroyed a repo-authored `AGENTS.md`** — no `--force`, no
prompt, no backup. Verified by smoke test. Filed as
[#25](https://github.com/Hypercart-Dev-Tools/pdda/issues/25) and fixed here, because leaving a data-loss
bug inside the function P1 was already rewriting could not be justified.

`PDDA-INSTALL.md:27` had disclosed the overwrite in prose. `install.sh --help` had not.

### Corrections to the intake

- **The 60.4KB `AGENTS.md` is `LTVera-Pandas`'s own file, not PDDA's.** PDDA ships a 2,289-byte
  `AGENTS.md`. So "do not shrink `AGENTS.md`" concerns the target's file, and `--with-startup-docs`
  would have replaced 60KB of that repo's convention with a 2KB stub.
- **`pdda-sync.sh push` cannot repair installed targets.** The brief says P1/P2 landing is enough. It
  is not: the sync manifest ships only `utils/pdda/` and `PROJECT/PDDA.md`, and `PDDA-INSTALL.md:260`
  states outright that startup docs "are never touched." A stale target router is repaired only by an
  explicit `install.sh <target> --with-startup-docs --force`. Documented in `PDDA-INSTALL.md`.
- **`.xyz/` is gitignored and absent from the canonical repo**, yet `ROUTER.md:89-94` references
  `.xyz/utils/marathon-plan.sh` and `.xyz/utils/hq/`. The canonical router carries the same class of
  dead reference it was spreading. Stripped from the template; still present (and still invisible)
  in the canonical router until P3.

### What the smoke test caught

The first draft of `templates/ROUTER.target.md` told targets a local runtime edit "is overwritten on the
next `pdda-sync.sh push`" — naming a script targets do not have. **The template reintroduced the exact
bug it exists to fix**, and the install-time assertion caught it before commit. That is the argument for
P2 in one line: the check has to run on the file the installer *wrote*, not on the file it read.

### Tests
&nbsp;

## P2 — shipped 2026-07-09

`install.sh` now validates its own output. When `--with-startup-docs` **writes** `ROUTER.md`, it asserts
that every `*.sh` path that router names resolves to a file present in the target. A dead reference prints
each offending name and exits non-zero.

Verified against the original bug: with the GH-23 refs re-injected into the template, the install prints

```
ERROR  ROUTER.md names "install.sh" but no such file exists in <target>
ERROR  ROUTER.md names "utils/pdda/pdda-sync.sh" but no such file exists in <target>
2 dead script reference(s) in the ROUTER.md this installer just wrote.
```

and exits `1`. The same scenario against `main`'s pre-P2 `install.sh` exits `0` and ships the router
silently. **That is the whole phase in one comparison.**

### Two boundaries, both learned rather than designed

**Only validate a router the installer wrote.** If `--with-startup-docs` kept the operator's existing
`ROUTER.md`, that file is theirs. Failing their install over their own scripts would be indefensible and
would make this the first check anyone disables. `seed_from_source` now reports whether it wrote or kept
(`SEEDED_LAST`), and the assertion is skipped for a kept file — with a line saying so.

**Run it against the written artifact, not the source template.** P1's own smoke test is the proof: the
first draft of `templates/ROUTER.target.md` told targets that a local edit "is overwritten on the next
`pdda-sync.sh push`" — naming a script targets do not have. Checking the *input* would have passed.

### Severity: hard error, mode-independent

Unlike the doc-hygiene `pdda.sh run` at the end of an install (warn-only in `observe`/`light`), this exits
non-zero regardless of mode. The distinction is *whose artifact is wrong*: the hygiene run inspects the
target's own docs, where warn-only is correct calibration. The self-check inspects **PDDA's own output**.
A dead ref there is a PDDA template bug, and the non-zero exit is what stops `pdda-sync.sh register` from
propagating a broken router any further.

The install still completes. Aborting midway would leave a half-provisioned tree — strictly worse than a
usable repo with a misleading router and a loud error. Two tests pin that.

### Tests — `test/pdda-install-startup-docs.sh`, 16 → 33

The negative controls are the ones that matter, because they are what keep this check enabled:

| Case | Guards against |
|---|---|
| operator's own `ROUTER.md` with a dead `my-private-deploy.sh` → **self-check never asserts, exit 0** | the check policing files it does not own |
| bare `pdda-lib.sh` resolving via the repo-wide fallback → **no finding** | tightening the matcher to paths-only, which looks correct |
| no `--with-startup-docs` → **self-check never runs** | scope creep into plain installs |
| poisoned template → **install still completes**, contract still lands | a mid-install abort leaving a half-provisioned tree |

The poisoned-template case builds a throwaway copy of this repo with `.git` excluded, which also exercises
`pdda_manifest_expand`'s non-git `find` fallback for free.

`test/pdda-install-startup-docs.sh` — 16 assertions. Includes the negative control that matters: a test
proving `--force` *does* overwrite, so the create-only guard cannot pass by being an unconditional skip.

---

## P3 — shipped 2026-07-09 (with GH-14 Phase 2)

P3 in one line: **the dead-reference scan could not see the references that matter most — the commands.**

### Two parts, one cause

The brief predicted the fence was hiding the `pdda-sync.sh` invocations. It is not: `_pdda_gov_scannable_lines`
exempts only `console`/`text`/`transcript` fences, so a ` ```bash ` fence *is* scanned. The single cause is
the extractor, and it fails in two independent ways:

1. **The suffix.** Both patterns hard-required `.md`. Widening to `.sh` catches the backticked whole-span refs.
2. **The shape.** A command invocation is neither a markdown link nor a closed backtick span — it carries
   arguments. `` `.xyz/utils/marathon-plan.sh --help` `` and a bare `utils/pdda/pdda-sync.sh push` match
   *no* suffix-widened pattern, because neither closes right after the suffix. They need a third pattern
   keyed on **command position**: the token that opens a code span or a scanned fence line.

Part 2 is where the risk lives, and it is why the negative controls were written first. The same rule that
extracts `pdda-sync.sh` from `pdda-sync.sh push` would extract `pdda.sh` from `` `pdda.sh run` `` — correct,
as it happens, since the bare name resolves through the repo-wide fallback — but it must never extract `run`,
never fire on a glob like `` `utils/pdda-*.sh` ``, and never read a script name sitting mid-sentence as a path.

### The scan indicted its own repo, then its own author

Turning it on produced findings before it produced confidence:

- **Canonical `ROUTER.md:91`** named `.xyz/utils/marathon-plan.sh`. `.xyz/` is gitignored and absent. The
  router that spread dead references into targets was carrying its own. Removed, per the operator's call.
- **Canonical `GUIDING-PRINCIPLES.md:24`** named `install.sh` as a path — and that doc is *scaffolded into
  every target*, where no installer exists. P1 fixed the router and walked past this. Reworded to prose.
- **`utils/pdda/PDDA-INSTALL.md:67,84`** named `templates/ROUTER.target.md`. **P1 introduced those lines**,
  dead in every target. The check built in P3 found the debt created in P1.
- **`PROJECT/PDDA.md`**, after P3 was written, tripped on the illustrative placeholders in P3's *own
  documentation* of P3. Reworded to describe the patterns rather than exhibit them.

### The exemption manifest had to grow, or the check would have been turned off

A fresh `install.sh <scratch> --with-startup-docs` emitted **46 dead-ref warns** with the widening and the
old manifest — GH-15's self-inflicted-noise failure, replayed exactly. `.sh` refs are the ones that differ
most between the canonical repo and a target. The manifest was rebuilt from that real scan (46 → 0), in
three groups: canonical-only tools (installer, sync engine, `templates/`, `test/`); the legacy flat-layout
paths `PDDA-INSTALL.md` names *because they must not exist*; and `config.sh`, which belongs to git-pulse.

**Accepted false positive:** a doc naming a script that lives only on the operator's `PATH` warns once.
Distinguishing it would require consulting the machine's `PATH`, making a deterministic check machine-dependent.
Warn-only makes the cost one ignorable line.

### The self-check was scoped to the wrong noun

P2 asserted over `ROUTER.md`. The router was never special — `GUIDING-PRINCIPLES.md` carried the same defect.
`assert_written_router_refs` became `assert_written_doc_refs`, applied to **every startup doc the installer
actually wrote**, decided per file so a kept doc is still never policed. Against `main`, a poisoned
`GUIDING-PRINCIPLES.md` exits `0` and ships the dead ref into the target; here it exits non-zero and names it.

### GH-14 Phase 2 (BUG-001b) rode along, because it is the same bug

`pdda_gated_exit` forces every check's exit code to `0` outside `full` mode. Correct — `observe` and `light`
must never fail a build. But `cmd_run` inferred *all checks passed* from that same zero. **The mode gate is
meant to stop the run from blocking, not from reporting.** A new adopter, who starts in `observe` by design,
saw a green line over real errors.

Fixed with run-level totals that survive `pdda_reset_counts` and ignore the gate, giving three outcomes
instead of two: passed / found-but-not-blocking / failed. Warnings still never move a run out of "passed" —
a `warn` is the advisory, and collapsing that distinction would make every recommendation read as a failure.
The LLM readiness review is now gated on findings rather than the gated exit code, so an error-laden repo in
`observe` no longer spends an LLM call it was never supposed to spend.

This is the last member of the family. GH-23: a check that could not *see*. GH-27: a check that could not
*reach* `gh`. BUG-001b: a check that could not *block*. All three reported success.

### Tests — red first, in both directions

| Suite | Before | After |
|---|---|---|
| `test/pdda-governance-check.sh` | 14 | 31 |
| `test/pdda-install-startup-docs.sh` | 33 | 38 |
| `test/pdda-run-mode-reporting.sh` | — | 23 (new) |

Every positive was run against `main`'s pre-P3 code and **fails there**; every negative control **passes
there**. Against `main`: 7 governance positives red, 7 negatives green; 5 run-mode positives red, 18 negatives
green — including `observe: still exits 0`, which proves the mode gate was not broken in the fixing of it.

The negative controls, which are the whole argument for the widening being safe:

| Case | Guards against |
|---|---|
| `` `pdda.sh run` `` → no finding, and `run` never extracted | reading a subcommand as a path |
| `utils/pdda/pdda.sh` present → no finding | over-flagging live refs |
| `` `utils/pdda-*.sh` `` → no finding | treating a glob as a path claim |
| `setup.sh` mid-sentence → no finding | command position degrading into "any `.sh` word" |
| `./install.sh` in a fence → resolves at repo root | inventing dead refs in nested docs |
| same ref twice on a line → exactly 1 finding | duplicate warns from the pattern union |
| shipped doc names `install.sh` → exempt; **non-shipped doc names it → still flagged** | the exemption leaking past the docs it was scoped to |
| clean run in every mode → still says *all checks passed* | "never claim success" being satisfied by never saying it |
| warn-only run → still says *all checks passed*, exit 0 | advisories collapsing into failures |

`test/fixtures/gh-23/LTVera-Pandas-ROUTER.md` — the byte-identical router that shipped into that repo — is
now a regression fixture. It must never scan clean again.

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
