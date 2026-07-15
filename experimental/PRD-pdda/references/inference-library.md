# Inference Library

The engine that keeps the interview under 10 questions. Detect the product
category from Q1–Q2 (or the brain dump), then **propose concrete defaults**
instead of asking about personas, auth, data model, and NFRs directly. Both
intake modes route through this same library — Mode A to fill fields the user
hasn't reached yet, Mode B to fill fields the prose didn't cover.

Every proposed value the user did not explicitly state is tagged **(Inferred)**
in the PRD so they can challenge it.

---

## Category-based defaults

Match the idea to the closest category and propose these as a starting point.

### SaaS / B2B Tool
- **Personas:** Admin, End User, Read-Only Viewer
- **Auth:** Email/password + OAuth (Google, Microsoft)
- **Data model:** Tenant isolation (`organization_id` on all entities)
- **NFRs:** RBAC, audit logging, data export

### Consumer App / Social
- **Personas:** Content Creator, Consumer, Moderator
- **Auth:** Phone OTP + social OAuth
- **Data model:** User profiles, content graph, engagement metrics
- **NFRs:** Feed algorithm, content moderation, push notifications

### E-commerce / Marketplace
- **Personas:** Buyer, Seller, Admin
- **Auth:** Email/password + guest checkout
- **Data model:** Products, orders, payments, inventory
- **NFRs:** Cart-abandonment recovery, payment PCI compliance, search/filter

### Internal Tool / Dashboard
- **Personas:** Analyst, Manager, Executive
- **Auth:** SSO (SAML/OIDC) via corporate identity
- **Data model:** Metrics, reports, data sources
- **NFRs:** CSV/PDF export, scheduled reports, role-based views

> If the idea straddles two categories, pick the dominant one for defaults and
> note the overlap in Open Questions rather than asking a whole extra question.

---

## The propose-a-default pattern (never ask open-ended)

Whenever a field is thin or unresolved — in either mode:

> "Based on what you've shared, I propose **[specific default]** for [area].
> Why: [one-line rationale].
> **A) Confirm** — [default] works
> **B) Adjust** — [minor tweak]
> **C) Override** — you want something different (tell me what)"

This is the default behavior, not a fallback. A fully open-ended question is a
last resort.

---

## Brain-dump extract → transform → infer (Mode B)

Given a free-written paragraph:

1. **Extract** — map every explicit statement onto the target field(s) it
   satisfies. Quote-anchor where useful.
2. **Transform** — normalize into the PRD's structured shape (a stated audience →
   a primary persona; a stated "so they can..." → a JTBD outcome).
3. **Infer** — for every still-empty field, propose a category default (above),
   tagged **(Inferred)**.
4. **Present + confirm** — show the filled field set with (Inferred) tags, then
   ask only the still-ambiguous fields as short follow-ups using the
   propose-a-default pattern. These follow-ups count against the same 10-question
   budget; a good brain dump usually leaves only 2–4.

---

## Synthesis quality checklist

Before presenting inferred requirements or generating the PRD, verify:

- [ ] Every requirement traces back to a stated user need or an obvious inference
- [ ] No contradictions between fields (a non-goal doesn't contradict a P0)
- [ ] The P0 list is genuinely minimal — can it launch without any P1?
- [ ] Every user flow has a clear start, end, and error/recovery path
- [ ] The data model supports every functional requirement
- [ ] Milestone sequencing respects logical dependencies
- [ ] The guardrail metric is present (inferred, not asked)
- [ ] Table stakes (modern design + mobile-responsive) are assumed, not asked
