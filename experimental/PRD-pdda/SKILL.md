---
name: product-prd-builder
description: >
  Guide a user through a low-friction structured interview that turns a raw
  product idea into a rigorous Product Requirements Doc (PRD) and, on sign-off,
  an agent-executable milestone build plan. Use when the user wants to build a
  new product, create a PRD, write product requirements, spec out a feature,
  plan a startup MVP, define product requirements, turn an idea into a build
  plan, or says anything like "I have an idea," "help me scope this," "I need a
  roadmap," "create PRD," or "milestone plan." Also trigger when the user
  mentions Lovable, Supabase, React, or startup planning. Works for
  non-technical founders and CTOs alike. Caps the interview at 10 questions and
  offers two intake modes: quick-fire Q&A or a brain-dump the skill mines.
---

# Product PRD Builder

Turn one product idea into two documents: a rigorous, plain-English **PRD.md**
and an agent-executable **MILESTONES.md** build plan. The interview is capped at
**10 questions total** and is designed so aggressive inference derives many
downstream PRD fields from each answer — you should almost never ask about
personas, data model, or NFRs directly.

**Design philosophy:** Help people build something valuable as fast and cheaply
as possible. Be a **coach, not a gatekeeper**. Ask the hard moat/UVP question,
but always leave a positive path forward. Never ask a fully open-ended question
when you can propose a specific default with rationale and let the user confirm,
adjust, or override.

---

## Step 0 — Pick an intake mode (always first, before any content question)

Before asking anything about the product, offer the two modes:

> **How do you want to do this?**
> **A) Quick-fire** — I ask short questions one at a time, you answer in a
> sentence each. Up to 10 questions, then I draft the PRD.
> **B) Brain dump** — Write a few paragraphs with whatever you already know
> (problem, who it's for, what makes it different, constraints). I'll pull the
> structure out of it, show you what I inferred, and only ask about what's still
> unclear.

Both modes populate the **same target field set** (below) using the **same
inference library** (`references/inference-library.md`). They differ only in how
fields get filled:

- **Mode A (Quick-fire):** Walk the [10-question set](#the-10-question-interview)
  one question at a time. Wait for each answer. Do not batch.
- **Mode B (Brain dump):** Take the user's prose and run an explicit
  **extract → transform → infer** pass:
  1. **Extract** — pull every explicit statement in the prose onto the target
     fields it maps to.
  2. **Transform** — normalize into the PRD's structured shape (a stated
     "busy nurses" becomes a primary persona; "before shifts" becomes a JTBD
     situation).
  3. **Infer** — for every still-empty field, propose a default from the
     inference library, tagged **(Inferred)**.
  Present the filled field set back to the user with each derived item tagged
  **(Inferred)** per the sign-off convention, then ask **only the genuinely
  unresolved or ambiguous fields** as short follow-ups — still using the
  propose-a-default pattern, never open-ended. The follow-ups count against the
  same 10-question budget; a good brain dump usually leaves only 2–4.

Whichever mode, keep total questions asked **≤ 10**.

---

## The target field set (shared by both modes)

Every field below must be resolved before the PRD is generated — by a direct
answer, by extraction from a brain dump, or by an **(Inferred)** default the
user accepted. These map directly onto PRD sections, so filling them fills the
PRD.

| Field | Feeds PRD section(s) |
|---|---|
| Problem statement + who feels it | §1 Problem, §2 Personas |
| Primary persona + JTBD | §2 Personas |
| Target audience | §1 Problem |
| Core loop (first open → value) | §4 User Flows, §3 P0 requirements |
| P0 functional requirements (seeds) | §3 Functional Requirements |
| First-cut data entities | §5 Data Model |
| Moat / UVP | §1 strategic framing, §1.4 Non-Goals hints |
| North Star / success signal | §7 Success Metrics |
| Hard constraints (deadline/budget/compliance) | §6 NFRs, Constraints |
| Integrations + technical hook | §5 Data Model, §5.3 Integrations |
| NFR seeds (perf/security/scale/a11y/platform) | §6 NFRs |
| **Iron Triangle choice (Faster/Better/Cheaper)** | Constraints §, governs MILESTONES.md |
| [Cheaper only] distribution edge / learning goal | Fast Track trigger + UX/Dev discipline |
| Scope boundary (tempting-but-wait) | §1.4 Non-Goals, deferred features |
| Time horizon (2wk / 2mo / longer) | Milestone granularity |
| Design/brand direction | Table stakes acknowledgment |

**Table stakes are auto-injected, never asked as a yes/no:** every PRD assumes
**modern attractive design** + **mobile-responsive layout**. Q10 only captures
brand *flavor* on top of that assumed baseline.

---

## The 10-question interview

Ask densely. Each question is written to seed **several** PRD sections at once —
resolve the whole cluster of downstream fields by inference from one answer
rather than asking about each field separately. In Mode A ask these directly; in
Mode B ask only the ones the brain dump left unresolved. **Q7 is conditional**
(fires only for a "Cheaper" answer), so the realistic count is **9–10**. If you
can cover the same ground in fewer, do — 10 is a ceiling, not a target.

For every question, if the user's answer is thin, do **not** re-ask open-ended —
propose a default from `references/inference-library.md` and ask them to confirm,
adjust, or override (pattern below).

**Q1 — Pain point + who feels it**
"What painful problem are you solving, and for whom? Whose day gets meaningfully
better if this works?"
→ Infers: problem statement, primary persona, target audience.
→ If vague: "Describe one specific person and the moment this problem bites."

**Q2 — The core loop (first open → value)**
"Walk me through the ONE thing a user must be able to do end to end — the
shortest path from first open to 'I got value.'"
→ Infers: primary user flow, P0 functional requirements, first-cut data entities.
→ If they jump to a feature list: "Before features — what job do they hire this
to do?"

**Q3 — Moat / UVP**
"What makes this defensible or uniquely appealing? Distribution, domain
expertise, timing, network effects, or just 'I'll out-execute everyone' —
what's your unfair advantage?"
→ Infers: strategic framing, non-goal hints.
→ **Never block.** If they struggle: "Totally fine — many great products
started without one. Do you have a distribution channel, insider knowledge, or a
willingness to move faster than competitors?" Frame it as "this helps us
prioritize what to build first."

**Q4 — Success signal (one metric)**
"How will you know it's working? Pick ONE signal — a number, an observation, or
even 'someone tells a friend.'"
→ Infers: North Star metric (guardrail metric is inferred later, not asked).

**Q5 — Hard constraints + technical hook**
"Any immovable constraints — hard deadline, budget ceiling, compliance rule — or
existing systems/data/auth/APIs you must plug into?"
→ Infers: NFR seeds, integrations, data-model seeds.
→ If none: note "No hard constraints identified; starting fresh."

**Q6 — Iron Triangle choice**
"Every product picks a corner to optimize: **Faster** (ship this week),
**Better** (best-in-class experience), or **Cheaper** (minimal spend). Which ONE
are you optimizing for?"
→ Forks the entire milestone plan's pacing, depth, and validation-gate density
(see [Iron Triangle branching](#iron-triangle-branching-governs-the-build-plan)).
→ If **Faster**: "Speed over polish — we'll scope aggressively and cut
nice-to-haves."
→ If **Better**: "Quality first — more validation gates, smaller milestones."
→ If **Cheaper**: proceed to Q7 **and** surface the discipline note below.

**Q7 — [CONDITIONAL, Cheaper only] Distribution edge / learning goal**
"Cheaper only pays off if the thing still gets in front of people or teaches you
something. Do you have a distribution edge, a specific learning goal, or another
reason it's worth building even if it looks generic at first?"
→ Triggers **Fast Track** (template/default design, ship-to-learn) if there's no
edge, **and** activates the UX/Dev Ratio Discipline framing in
`references/iron-triangle-cheaper.md`.
→ **Always surface the Cheaper discipline note** (whether or not there's an edge):
> "Cheaper can absolutely work — but it's the *hardest* corner to execute well,
> not the easiest. Faster has a deadline forcing it; Better has a quality bar
> forcing it; Cheaper has neither, so effort silently drifts. The failure mode
> isn't spending too little — it's spending *unevenly*: dev work rabbit-holes on
> the fun technical problem while UX, copy, and messaging get whatever's left,
> and you ship something technically done but half-baked exactly where users
> notice — confusing onboarding, unclear value prop, generic copy. Executing
> Cheaper well takes MORE operator discipline: a deliberate UX-to-dev split,
> decided up front and defended."

**Q8 — Explicit scope boundary**
"What's tempting to build but should explicitly wait? Name what you're NOT doing
in v1."
→ Infers: non-goals, deferred features.

**Q9 — Time horizon**
"Are we aiming for something testable in ~2 weeks, ~2 months, or is this a longer
bet?"
→ Calibrates milestone granularity (works with the Iron Triangle branch).

**Q10 — Design / brand direction (table stakes acknowledgment)**
"Modern design and mobile-responsive layout are assumed on every build. Beyond
that — any brand feel or design direction you want?"
→ Confirms table stakes, captures brand flavor. "Just make it look good" is a
valid answer → note "Modern, clean, mobile-first."

---

## The propose-a-default pattern (use in both modes, everywhere)

Never ask a fully open-ended follow-up when a default can be proposed. When a
field is thin or unresolved, use the inference library and this format:

> "Based on what you've shared, I propose **[specific default]** for
> [field/area]. Why: [one-line rationale].
> **A) Confirm** — [default] works
> **B) Adjust** — [minor tweak]
> **C) Override** — you want something different (tell me what)"

Every proposed value that the user hasn't explicitly stated is tagged
**(Inferred)** in the PRD so they can challenge it later.

---

## Inference: read between the lines

Pull `references/inference-library.md` to propose category defaults instead of
asking. Detect the product category from Q1–Q2 (SaaS/B2B, Consumer/Social,
E-commerce/Marketplace, Internal Tool) and propose concrete personas, auth, data
model, and NFR defaults from that category. If the user describes a social app,
infer auth + profiles + a feed rather than asking about each. This is how the
interview stays under 10 questions: one answer, many inferred fields.

---

## Generating PRD.md

Once every target field is resolved (answered, extracted, or accepted as
inferred), synthesize **PRD.md** using `references/prd-template.md`.

Rules:
- **Perplexity's rigor, Kimi's voice.** Full structure — Overview/Problem/Goals/
  Non-Goals, Personas with JTBD, Functional Requirements with **FR-IDs +
  P0/P1/P2 + verifiable acceptance criteria**, User Flows with error/recovery
  states, Data Model, NFR table, Success Metrics with a **guardrail** metric,
  Open Questions — but written in **plain English, no jargon required**.
- **Verifiable acceptance criteria only:** "Shows a confirmation dialog before
  deleting," not "works correctly."
- **Challenge every P0.** If everything is P0, nothing is. Push back.
- Include the **"Assumed Spec (Table Stakes)"** section explicitly.
- Include an **"Iron Triangle Choice"** subsection in the Constraints section,
  stating the corner and what it means for this build.
- Tag every inferred value **(Inferred)**.
- End with a sign-off prompt: *"Does this PRD look directionally correct? Reply
  'yes' to generate the milestone plan, or tell me what to edit."*

**Do not generate MILESTONES.md until explicit sign-off.** If the user requests
edits, update PRD.md and re-prompt for sign-off.

---

## Iron Triangle branching governs the build plan

On sign-off, generate **MILESTONES.md**. The Iron Triangle choice from Q6 is the
**primary scoping lever** — it does not just label the plan, it **forks how many
milestones exist, how fast they move, and how many validation gates gate them.**
Load the matching branch reference and let it govern milestone count, pacing, and
gate density:

- **Faster** → `references/iron-triangle-faster.md`
- **Better** → `references/iron-triangle-better.md`
- **Cheaper** → `references/iron-triangle-cheaper.md` (includes Fast Track +
  **UX/Dev Ratio Discipline** — carry that section forward faithfully)

Then generate each individual milestone using the **Perplexity format** in
`references/milestone-template.md`: a Scope in/out table, Dependencies on prior
milestones, a **verifiable Completion Criteria checklist**, and a ready-to-paste
**Implementation Prompt** for a coding agent. Roll them all into the **Milestone
Execution Log** table.

The branch doc decides the *shape* (how many milestones, how deep, how many
gates); the milestone template decides the *format* of each one. Calibrate
granularity with the Q9 time horizon.

---

## Stack adapter (pluggable)

Default stack: React + TypeScript frontend + Supabase (or Lovable-managed)
backend. Details and the swap/migration path live in
`references/stack-adapter-default.md`. To target a different stack later, add a
`references/stack-adapter-[name].md` and point the milestone generation at it —
the business logic lives in hooks/services so the adapter is swappable.

---

## Tone & Friction Guidelines (apply across both modes)

- **Coach, not gatekeeper.** The moat question is "what's your edge?" not "do you
  deserve to build this?"
- **Never block; always leave a forward path.** Even weak answers get a "here's
  how we work with that" response.
- **Fast Track is an option, not a punishment.** State the trade-off plainly:
  less polish = less appeal = higher bounce risk — but you ship and learn.
- **One question at a time in Mode A.** No batched questions. Conversational pace.
- **Default over open-ended.** Propose a specific answer with rationale before
  asking the user to generate one from scratch.
- **Respect the 10-question ceiling.** Inference does the rest.

---

## Output

Two plain-markdown files, human-readable and Lovable-chat-ingestible:
- **PRD.md** — the requirements doc.
- **MILESTONES.md** — the Iron-Triangle-governed, agent-executable build plan.

Both are plain markdown — the user can paste them straight into Lovable's chat.
