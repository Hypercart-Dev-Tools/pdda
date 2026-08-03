---
title: Align PDDA principles/tenets wording with HiQS (Attested · Ranked · Fresh · Structured)
status: Proposed (1-INBOX — not yet active). Step 1 (README front-door mention) landed 2026-08-03.
created: 2026-08-03
owner: noel
gh_issue: 60
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/60
doc_type: project
related:
  - GUIDING-PRINCIPLES.md
  - README.md
context_tags: [messaging, positioning, hiqs, principles, governance]
effort: 2
complexity: 3
risk: 2
phases: 4
---

## Ask

Bring PDDA's principles/tenets **wording** into alignment with the HiQS tenets —
**Attested · Ranked · Fresh · Structured** — over time, so messaging stays consistent across the
product family. HiQS repo: <https://github.com/HiQS-Suite/HiQS>.

This is a **messaging/positioning** alignment, not an import of HiQS governance machinery. That
distinction is the entire scope boundary of this doc.

## Why this is honest rather than cross-pollination theater

Three of the four tenets already describe load-bearing PDDA behavior under PDDA's own names. The
alignment renames nothing — it puts a shared label on mechanisms that already exist, and names the
two places where PDDA does *not* yet earn the label.

| HiQS tenet | PDDA today | Mechanism |
|---|---|---|
| **STRUCTURED** | strongest | frontmatter contract, exact `## Status` headers, triage ratings validated `1–5`, `PROJECT/PDDA-ACTIVITY.jsonl` findings with stable `check` ids, explicit `roadmap_exempt` / `pdda_hold` / `quad_exempt` opt-outs |
| **FRESH** | strong | `pdda.sh stale`, `changelog`, `issue-doc-sync`, `governance` (dead refs, env-var drift) |
| **ATTESTED** | **partial** | incidents and outcomes are well attested (`CHANGELOG.md`, `## Lessons Learned`, memory injection); **decision** attribution is not — nothing records *who* concluded what, on what date, on what evidence, beyond a single `owner:` |
| **RANKED** | **specified, not implemented** | `PROJECT/PDDA.md` ["How to combine them — derive, don't store"](../PDDA.md) already specifies the selection rule (`risk` as a gate not an addend, `ease = effort + complexity`, `ratings_provisional` as an eligibility gate) — but nothing computes it: no `pdda.sh` subcommand, no enforcement of `ratings_provisional`, and `ROADMAP.md` renders a list, not an order |

Shared vocabulary over mechanisms that already exist is positioning. Shared vocabulary over
mechanisms that don't exist is a slogan. The two weak rows are stated deliberately so the alignment
never ships as a 4/4 clean sweep it hasn't earned.

## Prior art — the audit already exists, from the HiQS side

`HIQS-PROJECT.md` §18 ("Tenets & self/meta compliance — dogfooding") audits the four tenets in
**both** directions: against the product HiQS ships, *and* against the plan-and-process that builds
it. That process side **is PDDA**. Its verdicts:

- **RANKED** — *"the weak tenet on both sides. Product now measured; process still unranked."*
- **ATTESTED** — the process attests to *what happened* but not to *who concluded what*: "a partial
  failure, not the total one the product had."
- **FRESH** — *"aligned."* Shared blind spot named: a fresh timestamp over stale content.
- **STRUCTURED** — *"aligned and strongest."* `PROJECT/PDDA-ACTIVITY.jsonl` is called out there as
  "an events table for docs — the same architecture, applied to the work."

So the connection is not being invented here; it is being reciprocated. The rule to inherit is §18.4:
**a tenet is a field, a gate, and a detector — never a slogan.** Any tenet PDDA claims must point at
an existing check, or be published as unmet.

`HIQS-PROJECT.md` §18.3 is worth carrying too: four tenets are not the whole safety surface. Passing
all four says nothing about portability, resource discipline, silent no-ops, or scope accretion. A
scorecard is a lens, not a proof of soundness.

## Phases

### Phase 1 — front-door mention (done 2026-08-03)

A short "Part of HiQS" section in `README.md` carrying the scorecard above, each row pointing at the
mechanism that backs it. No contract change.

**QA gate:** section exists; every tenet row links to a real check or names its gap; `pdda.sh run`
clean; `GUIDING-PRINCIPLES.md` and `PROJECT/PDDA.md` unmodified.

### Phase 2 — ATTESTED: decision attribution

Close the gap §18 names on the process side. Candidates (pick one, don't stack them):

- a lightweight convention for recording who decided / when / on what evidence in
  `PROJECT/decisions/`; and/or
- a `risk_rationale` frontmatter field, warn-only, required when `risk >= 4`.

**Watch for duplication:** `utils/pdda/pdda-doc-ready.sh` already warns when a high-risk (`risk: 4`/`5`)
plan links no `decisions/` record. Phase 2 must extend that signal, not add a second one beside it.

**QA gate:** exactly one warn fires for an unattested high-risk decision (not two); `pdda.sh run`
clean; the check is deterministic or lives in the LLM layer by explicit choice, not by accident.

### Phase 3 — RANKED: implement the rule that already exists, or publish it unmet

**Corrected 2026-08-03.** This phase was first written as "decide whether PDDA claims RANKED,"
which assumed no ranking design existed. It does. `PROJECT/PDDA.md`'s *"How to combine them — derive,
don't store"* section already specifies the whole selection rule, with its reasoning:

```text
eligible = risk <= 2 AND not ratings_provisional   # risk >= 4 => route to a human
ease     = effort + complexity                     # 2..10, lower = easier
pick     = among eligible, lowest ease, then fewest phases as the tiebreak
```

...plus the decision *not* to store a composite score (it would drift from its inputs, violating
Principle #4), `risk` as a **gate rather than an addend** so a trivial-but-risky task can't slip
through mid-ranked, and `ratings_provisional` as an eligibility gate rather than metadata. The
resolved `priority`-field note under "Proposed extensions not yet locked" records the same decision.

So the design is done and deliberate. **What is missing is the detector.** No `pdda.sh` subcommand
computes the rule, nothing enforces `ratings_provisional` as an eligibility gate, and `ROADMAP.md`
renders no order. Under HiQS §18.4 that is precisely the failure mode the rule names: a tenet with a
field but no gate and no detector is prose.

Two acceptable outcomes, one unacceptable one:

- **Implement it** — a `pdda.sh pick` (or `rank`) subcommand that reads the existing frontmatter
  ratings across the working set and emits the eligible-and-easiest doc. The logic is already written;
  this is transcription plus a gate, not design. Smallest honest version of the tenet.
- **Publish it as unmet** — state plainly that PDDA specifies a selection rule but does not compute
  one, and that ordering is a human call, until a detector exists.
- **Not acceptable:** claiming RANKED in messaging on the strength of a rule nothing runs.

This mirrors §7.1's posture in HiQS: a failing tenet changes the claim's wording, not just the
backlog.

**QA gate:** the README scorecard's RANKED row matches what the repo actually does, verified against
`pdda.sh roadmap-coverage` output.

### Phase 4 — vocabulary pass

Once Phases 2–3 settle, reconcile `GUIDING-PRINCIPLES.md` wording with the tenets *where they already
agree* — without adding a second normative framework. Most likely a few word choices, not a new
section.

**QA gate:** no principle is restated under a tenet heading; the diff adds no new rule.

## Anti-goals

- **No tenets banner in `PROJECT/PDDA.md` or `GUIDING-PRINCIPLES.md`.** The contract and the north
  star stay single-source. The tenets are a descriptive lens on the front-door surface. The moment
  they issue a rule, PDDA has two frameworks to reconcile — violating Principle #4 (one canonical
  place per fact) and recreating the exact drift class HiQS was rebuilt to avoid (its L1: two
  synthesis surfaces sharing no code).
- **No renaming** of existing checks, fields, or subcommands to tenet names.
- **No new enforcement layer.** If a tenet ever needs enforcing, the enforcement lives where it
  already lives (`pdda.sh`), not in a parallel manifesto.
- **No claim of a 4/4 pass** while ATTESTED is partial and RANKED is weak.

## Acceptance criteria

- Every tenet PDDA names in public docs links to the existing mechanism that backs it, or is
  published as unmet with the gap stated.
- `GUIDING-PRINCIPLES.md` and `PROJECT/PDDA.md` remain the single normative sources; no rule is
  restated under a tenet heading.
- `pdda.sh run` clean after each phase.

## Open questions

1. Phase 2: `PROJECT/decisions/` convention, `risk_rationale` field, or both? (Recommend: whichever
   extends the existing high-risk warn rather than sitting beside it.)
2. Phase 3: implement the already-specified selection rule as a `pdda.sh` subcommand, or publish
   RANKED as unmet? (The design question is settled; only the build-or-declare call is open.)
3. Does the selection rule belong in `ROADMAP.md` output, a new subcommand, or both? A rendered
   order in `ROADMAP.md` risks re-storing a derived value — the exact thing "derive, don't store"
   forbids — so a subcommand that computes it live is the Principle-#4-safe shape.
