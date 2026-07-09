# Iron Triangle: Faster

## Philosophy

Ship the smallest thing that validates the core loop. Polish is deferred to
post-validation. The built-in forcing function is the **deadline** — protect it.

## Milestone shape (governs MILESTONES.md)

- **Milestone count:** Compress the reference ladder to **2–3 milestones.** Fold
  the core data layer into the flows milestone where possible. Defer or drop
  "edge cases & polish" and "advanced features" until signal appears.
- **Pacing:** 1–2 weeks per milestone.
  - **M1:** Core loop only — one path, no edge cases.
  - **M2:** Fill the obvious gap in the loop.
  - **M3 (conditional):** Polish *only* if M1–M2 show signal; otherwise pivot or
    kill.
- **Validation-gate density:** **Minimal.** One "does anyone care?" gate, usually
  at the end of M1–M2, not per milestone. If there's no signal by M2, recommend
  stop.

## "Good enough" bar

- Works end-to-end for the primary user.
- Design is clean but not custom (framework defaults).
- Mobile-responsive by framework default.
- No animations, no micro-interactions, no dark mode.
