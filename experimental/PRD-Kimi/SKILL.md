
---

## Final Design Decisions Locked

| Decision | Implementation |
|---|---|
| **Fast Track** | If "Cheaper" → offer Fast Track with explicit trade-offs: less polish, less UX refinement, higher risk of user disengagement |
| **Cheaper ≠ doomed** | "Cheaper" succeeding is possible but not free — it demands more operator discipline, not less. The skill should surface this explicitly rather than let "cheaper" quietly become "sloppy" |
| **MVP vs. Iron Triangle fork** | Yes — the Iron Triangle choice becomes the **primary scoping lever**. It doesn't just weight inference; it forks the entire Phase 2 structure |
| **Table stakes** | Auto-injected: "Modern attractive design" + "Mobile responsive layout" as assumed spec in every PRD |
| **Moat/UVP** | One dedicated question, framed as "what's your unfair advantage?" not "prove you're special" |
| **Output** | Two clean markdown files, human-readable, 4-headline sections, Lovable-chat-ingestible |

---

## The Skill: `product-prd-builder`

### Directory Structure

```
.claude/skills/product-prd-builder/
├── SKILL.md                              # Main skill file
├── references/
│   ├── prd-template.md                 # PRD output template
│   ├── spec-roadmap-template.md          # Spec + Roadmap output template
│   ├── iron-triangle-faster.md           # Phase 2 branch: Faster
│   ├── iron-triangle-better.md           # Phase 2 branch: Better
│   ├── iron-triangle-cheaper.md          # Phase 2 branch: Cheaper (incl. Fast Track)
│   └── stack-adapter-default.md          # JS/TS React + Supabase/Lovable baseline
└── examples/
    ├── prd-example.md
    └── spec-roadmap-example.md
```

---

### `SKILL.md`

```yaml
---
name: product-prd-builder
description: >
  Guide users through a structured product interview to produce a Product
  Requirements Doc (PRD) and, upon sign-off, a Spec + Roadmap doc. Use
  when the user wants to build a new product, create a PRD, write a product
  spec, plan a startup MVP, define product requirements, or says anything
  like "I have an idea," "help me scope this," "I need a roadmap," or
  "build a product with me." Also trigger when user mentions Lovable,
  Supabase, React, or startup planning. This skill works for non-technical
  founders and CTOs alike.
---

# Product PRD Builder

## Overview

This skill conducts a two-phase interview to produce two markdown documents:
1. **PRD.md** — Essential product requirements (human-readable, Lovable-compatible)
2. **SPEC-ROADMAP.md** — Inferred phases, features, experiments, and stack guidance

**Design philosophy:** Help people build something valuable as quickly and cheaply as possible. Be a coach, not a gatekeeper. Ask hard questions about moat/UVP, but always leave a positive path forward.

## Phase 1: The Essential Interview

Conduct a conversational interview. Ask ONE question at a time. Wait for the user's response before proceeding. Do not batch questions.

### Question Sequence

**Q1. The Pain Point**
"What painful problem are you solving, and for whom? Be specific — whose life gets meaningfully better if this works?"

→ If vague, gently probe: "Can you describe a specific person and a specific moment this problem hurts?"

**Q2. The User Archetype**
"Who is the *primary* user? Not everyone — the one person who, if you win them, the product wins. What do they currently do instead of using your solution?"

→ Accept 1-2 personas max. If they list more, ask them to pick the one that would pay first or use it most.

**Q3. The Core Loop**
"Walk me through the ONE thing a user must be able to do end-to-end. What's the shortest happy path from 'first open' to 'I got value'?"

→ If they jump to features, redirect: "Before features — what's the job they hire this product to do?"

**Q4. Unique Value Proposition / Moat**
"What makes this defensible or uniquely appealing? It could be distribution, domain expertise, timing, network effects, or even just 'I will out-execute everyone.' What's your unfair advantage?"

→ **If they struggle:** "That's okay — many great products started without a clear moat. Do you have a distribution channel, insider knowledge, or a willingness to move faster than competitors?"

→ **Never block.** Frame this as: "Knowing this helps us prioritize what to build first."

**Q5. Success Signal**
"How will you know this is working? Pick ONE signal — a metric, a qualitative observation, or even 'someone tells a friend.'"

**Q6. Hard Constraints**
"Any immovable constraints? Hard deadline, budget ceiling, compliance requirement, or a system you MUST integrate with?"

→ If none, note "No hard constraints identified."

**Q7. Iron Triangle Choice**
"Every product chooses two of three: Faster (ship this week), Better (best-in-class experience), or Cheaper (minimal spend). Which ONE are you optimizing for?"

→ **If Faster:** "Got it — speed over polish. We'll scope aggressively and cut nice-to-haves."
→ **If Better:** "Quality-first. We'll plan more validation gates and smaller phases."
→ **If Cheaper:** "Minimal spend. Before we proceed — if this looks generic to users, do you have a distribution edge, a learning goal, or another reason it's still worth building?"

→ **If Cheaper + no clear edge:** Offer Fast Track: "We can do a Fast Track version — less polish, less UX refinement, higher risk that users bounce. The trade-off is you ship faster and cheaper, but it may not 'pop.' Still worth it?"

→ **Cheaper discipline note (always surface, not just no-edge case):** "Cheaper can absolutely work — but it's the hardest path to execute well, not the easiest. It only works if you stay disciplined about *where* the budget/time goes: a deliberate UX-to-dev ratio, not 'whatever's left after building.' The failure mode isn't spending too little — it's spending unevenly. Dev work quietly balloons into a rabbit hole (one more integration, one more refactor) while UX and messaging get whatever's left over, and you end up with a product that's technically done but half-baked in the ways users actually notice: confusing onboarding, unclear value prop, generic copy. If you're optimizing for Cheaper, the discipline is knowing your UX/dev time split up front and protecting it — not eliminating polish, but *right-sizing* it so nothing ships half-finished."

**Q8. Table Stakes Acknowledgment**
"Two things are assumed for every build: modern attractive design and mobile-responsive layout. Any specific design direction or brand feel you want?"

→ If they say "just make it look good," that's fine. Note "Modern, clean, mobile-first."

### Phase 1 Output: PRD.md

After Q8, synthesize the interview into PRD.md using the template at [references/prd-template.md](references/prd-template.md).

**Rules for PRD generation:**
- Every major section has exactly **4 headlines** (H2 or H3)
- Write in plain English — no jargon required
- Include the table stakes explicitly under "Assumed Spec"
- End with an "Open Questions" section for Phase 2
- Add a sign-off prompt: "Does this PRD look directionally correct? Reply 'yes' to proceed to Spec + Roadmap, or tell me what to edit."

**Do not proceed to Phase 2 until explicit sign-off.**

---

## Phase 2: Spec + Roadmap (Post Sign-Off)

Upon "yes" or equivalent confirmation, proceed. If they request edits, update PRD.md first, then re-prompt for sign-off.

### The 3-4 Grounding Questions

Ask these BEFORE inference to anchor the LLM's expansion:

**GQ1. MVP Boundary Check**
"You said [core loop from PRD]. Should the first version include [obvious adjacent feature] or is that explicitly later?"

→ This tests boundary assumptions without adding scope.

**GQ2. Technical Hook**
"Any existing data, auth system, or API we must plug into? Or are we starting fresh?"

**GQ3. Riskiest Unknown**
"What's the scariest assumption — that users will behave as expected, that you can build it, or that the market timing is right?"

→ Shapes experiment design.

**GQ4. Time Horizon Calibration**
"Are we aiming for something testable in 2 weeks, 2 months, or is this a longer bet?"

→ Calibrates phase granularity.

### Iron Triangle Branching

Load the appropriate reference file based on the Iron Triangle choice from Phase 1:

- **Faster** → [references/iron-triangle-faster.md](references/iron-triangle-faster.md)
- **Better** → [references/iron-triangle-better.md](references/iron-triangle-better.md)
- **Cheaper** → [references/iron-triangle-cheaper.md](references/iron-triangle-cheaper.md) (includes Fast Track logic)

These files define how phases are structured, how many validation gates exist, and what "good enough" means for each branch.

### Phase 2 Output: SPEC-ROADMAP.md

Generate using [references/spec-roadmap-template.md](references/spec-roadmap-template.md).

**Inference rules:**
- Derive phases from core loop complexity + time horizon + Iron Triangle branch
- Label every inferred item as **(Inferred)** — user can challenge or accept
- Include stack guidance from [references/stack-adapter-default.md](references/stack-adapter-default.md)
- Every section has exactly **4 headlines**

---

## Stack Adapter (Pluggable)

Default stack: JS/TS React frontend + Supabase backend (or Lovable-managed).

The stack adapter is a config-driven module. To swap:
1. Create a new file in `references/stack-adapter-[name].md`
2. Update the `stack` reference in the Spec generation step
3. Future: support `stack: python-reflex` or `stack: next-app-router`

Current adapter notes:
- Frontend: React + TypeScript
- Backend/Data: Supabase (Postgres + Auth + Realtime)
- Table stakes: Modern design system, mobile-responsive framework
- Migration notes: "This stack is chosen for speed. To swap later, replace Supabase client calls with your new backend adapter."

---

## Tone & Friction Guidelines

- **Be encouraging, not gatekeeping.** The moat question is "what's your edge?" not "do you deserve to build this?"
- **Fast Track is an option, not a punishment.** Present trade-offs clearly: less polish = less appeal = higher bounce risk.
- **One question at a time.** No batched questions. Conversational pace.
- **Always leave a forward path.** Even weak answers get a "here's how we work with that" response.
```

---

### `references/prd-template.md`

```markdown
# Product Requirements Document: [Product Name]

## 1. Problem & Opportunity

### The Pain Point
[One paragraph: what hurts, for whom, and why it matters now]

### Who Feels It Most
[Primary user archetype — 1-2 sentences, specific]

### Why Now
[Timing driver: market shift, technology change, personal insight]

### Risk of Doing Nothing
[What happens if this isn't built — for the user, for the builder]

## 2. User & Value

### Primary User Archetype
[Name, role, current workaround, motivation]

### Core Job-to-be-Done
[The one thing they hire this product to do]

### Unique Value Proposition / Moat
[Why this wins — or the path to finding out]

### Why They'll Switch or Start
[Switching cost vs. value proposition]

## 3. Solution Boundary

### The Core Loop
[End-to-end happy path: first open → value received]

### Assumed Spec (Table Stakes)
- Modern attractive design
- Mobile responsive layout

### Explicitly Out of Scope
[What we're NOT building in this version]

### Success Signal
[The one metric or observation that tells us this works]

## 4. Constraints & Strategy

### Iron Triangle Choice
**[Faster / Better / Cheaper]** — and what that means for this build

### Hard Constraints
[Deadlines, budgets, compliance, must-integrate systems]

### Assumptions We're Making
[Listed explicitly so they can be tested]

### Open Questions (for Spec Phase)
[What we need to resolve to build the roadmap]
```

---

### `references/spec-roadmap-template.md`

```markdown
# Spec & Roadmap: [Product Name]

## 1. PRD Summary

### Problem Recap
[One-line restatement]

### User Recap
[Primary archetype and job-to-be-done]

### UVP Recap
[Core differentiator]

### Iron Triangle & Implications
[How Faster/Better/Cheaper shapes this roadmap]

## 2. Build Phases

### Phase 1: [Name] — [Goal]
[What we ship, what we learn, exit criteria]

### Phase 2: [Name] — [Goal]
[What we ship, what we learn, exit criteria]

### Phase 3: [Name] — [Goal]
[What we ship, what we learn, exit criteria]

### Phase 4+: Future Considerations
[What we know we'll need but aren't committing to yet]

## 3. Features by Phase

### Phase 1 Features (Smallest Testable Slice)
- [Feature] (Inferred/Confirmed)
- [Feature] (Inferred/Confirmed)

### Phase 2 Features (Core Loop Completion)
- [Feature] (Inferred/Confirmed)
- [Feature] (Inferred/Confirmed)

### Phase 3 Features (Polish & Edge Cases)
- [Feature] (Inferred/Confirmed)
- [Feature] (Inferred/Confirmed)

### Deferred / Future Features
- [Feature] — Deferred to Phase 4+

## 4. Experiments & Validation

### Riskiest Assumption to Test
[From GQ3 — the scariest unknown]

### Phase 1 Experiment
[How we validate before building Phase 2]

### Phase 2 Experiment
[Engagement/retention signal test]

### Go/No-Go Criteria per Phase
[What we measure to decide whether to proceed]

## 5. Stack & Architecture

### Frontend
React + TypeScript

### Backend & Data
Supabase (Postgres, Auth, Realtime) — or Lovable-managed equivalent

### Table Stakes Implementation
Modern design system, mobile-responsive framework

### Stack Migration Notes
[How to swap this stack later — adapter pattern guidance]
```

---

### `references/iron-triangle-faster.md`

```markdown
# Iron Triangle: Faster

## Philosophy
Ship the smallest thing that validates the core loop. Polish is deferred to post-validation.

## Phase Structure
- **Phase 1:** Core loop only. One path, no edge cases. 1-2 weeks.
- **Phase 2:** Fill gaps in the loop. Add the obvious missing step. 1-2 weeks.
- **Phase 3:** Polish only if Phase 1-2 show signal. Otherwise, pivot or kill.

## Validation Gates
- Minimal. One "does anyone care?" test per phase.
- If no signal by Phase 2, recommend stop.

## "Good Enough" Definition
- Works end-to-end for the primary user
- Design is clean but not custom
- Mobile responsive by framework default
- No animations, no micro-interactions, no dark mode
```

---

### `references/iron-triangle-better.md`

```markdown
# Iron Triangle: Better

## Philosophy
Best-in-class experience from first interaction. Smaller phases, more validation gates.

## Phase Structure
- **Phase 1:** Core loop + one "delight moment." 2-3 weeks.
- **Phase 2:** Complete loop + polish pass. 2-3 weeks.
- **Phase 3:** Edge cases + performance + refinement. 2-3 weeks.
- **Phase 4:** Scale & advanced features.

## Validation Gates
- One per phase: usability, engagement, retention
- "Would you pay for this?" test by Phase 2

## "Good Enough" Definition
- Every screen feels considered
- Animations and transitions are intentional
- Accessibility baseline met
- Performance budget defined and tracked
```

---

### `references/iron-triangle-cheaper.md`

```markdown
# Iron Triangle: Cheaper

## Philosophy
Minimum spend, maximum learning. Reuse everything. Buy over build.

**Cheaper is not the "easy" corner.** Faster has a built-in forcing function (deadline) and Better has a built-in forcing function (quality bar). Cheaper has neither — nothing stops effort from silently reallocating itself. The risk isn't underspending, it's *unevenly* spending: dev time rabbit-holes on the fun/technical problem (one more integration, one more refactor, "let me just get this working right") while UX, copy, and messaging get whatever's left, which is often nothing. The result is a product that took real effort but still reads as half-baked, because the effort went to the wrong half. Executing Cheaper well requires *more* operator discipline than the other two branches, not less: a deliberate UX-to-dev time/budget ratio, decided up front, and defended against scope creep on either side.

## Phase Structure
- **Phase 1:** Core loop using no-code/low-code where possible. 1 week.
- **Phase 2:** Migrate to code only if Phase 1 shows signal. 2-4 weeks.
- **Phase 3:** Add differentiation only if core loop is sticky.

## Fast Track Option
If user has no clear moat and chooses Cheaper:
- Offer Fast Track: skip custom design, use template/framework defaults
- Trade-off: less polish = less appeal = higher bounce risk
- Still ship, but set expectations: "This validates the idea, not the product"

## UX/Dev Ratio Discipline
- Before Phase 1 starts, name an explicit split (e.g. "80% dev / 20% UX+messaging" or vice versa) and write it into the roadmap — an undeclared ratio always drifts toward whichever side is more interesting to the builder
- Time-box dev rabbit holes explicitly: if a technical task exceeds its estimate, that's a checkpoint to ask "does this serve the core loop, or is this gold-plating?" — not a reason to quietly keep going
- Treat messaging/copy and onboarding clarity as first-class deliverables in every phase, not a Phase 3 afterthought — a half-baked value prop kills a cheap build faster than a rough UI does
- If the ratio is broken mid-build (dev overran, UX got skipped), surface it explicitly rather than letting the roadmap silently absorb it — "we spent 95% of this phase on the backend, UX got 5%, is that still the plan?"

## Validation Gates
- Cost per experiment tracked explicitly
- "Is this worth building properly?" decision by Phase 2

## "Good Enough" Definition
- Functional > beautiful
- Framework defaults acceptable
- One breakpoint for mobile (no tablet optimization)
- No custom illustrations, no custom icons
```

---

### `references/stack-adapter-default.md`

```markdown
# Stack Adapter: JS/TS React + Supabase (Default)

## Frontend
- **Framework:** React 18+ with TypeScript
- **Styling:** Tailwind CSS (assumed for speed, swappable)
- **Components:** shadcn/ui or equivalent accessible component library
- **State:** React hooks + Zustand or Context (keep simple)

## Backend / Data
- **Platform:** Supabase
- **Database:** PostgreSQL (managed)
- **Auth:** Supabase Auth (email, OAuth, magic link)
- **Realtime:** Supabase Realtime (where needed)
- **Storage:** Supabase Storage (files/images)

## Alternative: Lovable-Managed
If using Lovable:
- Stack is abstracted — Lovable handles backend
- Still output React + TS structure for transparency
- Note: "Lovable will manage deployment and backend. This spec assumes Lovable's conventions."

## Table Stakes Implementation
- **Modern attractive design:** Use a clean design system (shadcn, Radix, or equivalent)
- **Mobile responsive:** Tailwind breakpoints, mobile-first CSS, touch targets ≥ 44px

## Migration Path
To swap this stack later:
1. Replace Supabase client with your new backend adapter
2. Keep React components — business logic is in hooks/services
3. Database schema can be ported to any Postgres-compatible system
4. Auth migration: export users, re-import with new provider
```

---

## How It Works in Practice

**User:** "I want to build a habit tracker for people with ADHD."

**Skill (Q1):** "What painful problem are you solving, and for whom?"

*[User answers]*

**Skill (Q2-Q8):** *[One at a time, conversational]*

**Skill:** "Here's your PRD.md. Does this look directionally correct? Reply 'yes' to proceed."

**User:** "Yes, but can you add that it needs to handle medication reminders?"

**Skill:** *[Updates PRD.md]* "Updated. Does this look correct now?"

**User:** "Yes."

**Skill (GQ1-GQ4):** *[Grounding questions]*

**Skill:** "You chose Faster. Here's your SPEC-ROADMAP.md with 3 phases, inferred features, and experiments."

**User:** "Can I upload these to Lovable?"

**Skill:** "Yes — both files are plain markdown. Paste them into Lovable's chat. The structure is human-readable and Lovable can parse the sections."

---

Does this structure feel right? I can now produce the actual files as downloadable content, or we can iterate on any section first.