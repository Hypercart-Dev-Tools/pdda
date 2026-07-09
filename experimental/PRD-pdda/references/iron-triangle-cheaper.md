# Iron Triangle: Cheaper

## Philosophy

Minimum spend, maximum learning. Reuse everything. Buy over build.

**Cheaper is not the "easy" corner.** Faster has a built-in forcing function
(the deadline) and Better has a built-in forcing function (the quality bar).
Cheaper has neither — nothing stops effort from silently reallocating itself. The
risk isn't underspending, it's *unevenly* spending: dev time rabbit-holes on the
fun/technical problem (one more integration, one more refactor, "let me just get
this working right") while UX, copy, and messaging get whatever's left, which is
often nothing. The result is a product that took real effort but still reads as
half-baked, because the effort went to the wrong half. **Executing Cheaper well
requires *more* operator discipline than the other two branches, not less:** a
deliberate UX-to-dev time/budget ratio, decided up front, and defended against
scope creep on either side.

## Milestone shape (governs MILESTONES.md)

- **Milestone count:** Compress to **2–3 milestones**, favoring no-code/low-code
  first and migrating to code only once signal appears.
  - **M1:** Core loop using no-code/low-code where possible. ~1 week.
  - **M2:** Migrate to code *only if* M1 shows signal. 2–4 weeks.
  - **M3:** Add differentiation *only if* the core loop is sticky.
- **Pacing:** Signal-gated, not calendar-gated — each milestone must earn the
  next.
- **Validation-gate density:** Cost-per-experiment tracked explicitly; an "is
  this worth building properly?" decision by M2; **and a UX/dev-split check at
  every gate** (below).
- **Messaging/UX is a first-class deliverable in every milestone** — never parked
  in a final "polish" phase. A half-baked value prop kills a cheap build faster
  than a rough UI does.

## Fast Track Option

If the user has no clear distribution edge or learning goal and still chooses
Cheaper:

- Offer **Fast Track**: skip custom design, use template/framework defaults.
- Trade-off, stated plainly: less polish = less appeal = higher bounce risk.
- Still ship, but set expectations: "This validates the idea, not the product."
- Fast Track is an **option, not a punishment** — it buys a real answer cheaply.

## UX/Dev Ratio Discipline

- **Declare the split up front.** Before M1 starts, name an explicit ratio (e.g.
  "80% dev / 20% UX+messaging" or vice versa) and write it into the plan — an
  undeclared ratio always drifts toward whichever side is more interesting to the
  builder.
- **Time-box dev rabbit holes as a gold-plating checkpoint.** If a technical task
  exceeds its estimate, that's a checkpoint to ask "does this serve the core
  loop, or is this gold-plating?" — not a reason to quietly keep going.
- **Treat messaging/copy and onboarding clarity as first-class deliverables in
  every milestone,** not a final-phase afterthought — a half-baked value prop
  kills a cheap build faster than a rough UI does.
- **Surface a broken ratio instead of absorbing it.** If dev overran and UX got
  skipped, say so explicitly rather than letting the plan silently swallow it —
  "we spent 95% of this milestone on the backend, UX got 5%, is that still the
  plan?"

## "Good enough" bar

- Functional > beautiful.
- Framework defaults acceptable.
- One breakpoint for mobile (no tablet optimization).
- No custom illustrations, no custom icons.
- **But:** onboarding and value-prop copy are never "good enough by default" —
  they're the deliverable most likely to decide whether a cheap build lands.
