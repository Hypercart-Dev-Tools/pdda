# Interview Phase Guidance

Detailed patterns for conducting each interview phase effectively.

## Inference Patterns

When the user provides minimal input, infer the following defaults based on product category:

### SaaS / B2B Tool
- Personas: Admin, End User, Read-Only Viewer
- Auth: Email/password + OAuth (Google, Microsoft)
- Data model: Tenant isolation (organization_id on all entities)
- NFRs: RBAC, audit logging, data export

### Consumer App / Social
- Personas: Content Creator, Consumer, Moderator
- Auth: Phone OTP + Social OAuth
- Data model: User profiles, content graph, engagement metrics
- NFRs: Feed algorithms, content moderation, push notifications

### E-commerce / Marketplace
- Personas: Buyer, Seller, Admin
- Auth: Email/password + Guest checkout
- Data model: Products, orders, payments, inventory
- NFRs: Cart abandonment recovery, payment PCI compliance, search/filter

### Internal Tool / Dashboard
- Personas: Analyst, Manager, Executive
- Auth: SSO (SAML/OIDC) via corporate identity
- Data model: Metrics, reports, data sources
- NFRs: CSV/PDF export, scheduled reports, role-based views

## Question Patterns

Use multiple-choice proposals to minimize user effort. Format:

> "Based on what you've shared, I propose **[specific default]** for [area]. Here's why: [rationale].
>
> A) Confirm — [default] works
> B) Adjust — [minor tweak]
> C) Override — you want something different (tell me what)"

## Lock Confirmation Script

Before advancing each phase, use:

> "**Phase [N] locked**: [summary of what was decided]
>
> Moving to Phase [N+1]: [name]. Ready?"

If the user tries to jump back to a locked phase, either:
- Allow the edit if it does not cascade to later phases
- Warn and ask for explicit confirmation if it invalidates later decisions

## Synthesis Quality Checklist

Before presenting inferred requirements, verify:
- [ ] Every requirement traces back to a stated user need or obvious inference
- [ ] No contradictions between phases (e.g., non-goal contradicts a requirement)
- [ ] P0 list is genuinely minimal (can the product launch without any P1?)
- [ ] Every user flow has a clear start, end, and error path
- [ ] Data model supports all functional requirements
- [ ] Milestone sequencing respects logical dependencies
