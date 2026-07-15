# Product Requirements Document: {{PRODUCT_NAME}}

> **Status**: Draft / In Review / Locked
> **Version**: 1.0
> **Last Updated**: {{DATE}}
> **Author**: Product PRD Builder (interview-driven synthesis)

> Voice note for the generator: write this in **plain English, no jargon
> required** — a non-technical founder should follow every line. Keep the
> structure rigorous but the language human. Tag every value the user did not
> explicitly state as **(Inferred)** so they can challenge it.

---

## 1. Overview

### 1.1 What We're Building

{{1–3 plain-English sentences: what it is, the core user problem, the primary
value. From Q1–Q2 / brain-dump synthesis.}}

### 1.2 Problem Statement

- **The pain today**: {{what hurts, and in what specific moment}}
- **Who feels it most**: {{primary audience — specific, not "everyone"}}
- **Why now**: {{market shift, tech change, or personal insight}}
- **Risk of doing nothing**: {{what happens to the user and the builder if this
  isn't built}}

### 1.3 Strategic Framing (Moat / UVP)

{{The unfair advantage from Q3 — distribution, domain expertise, timing, network
effects, or speed of execution. If none is clear yet, state the path to finding
one. Never leave this as a blocker.}}

### 1.4 Goals & Objectives

| Goal | Priority | Success Metric |
|------|----------|----------------|
| {{Goal 1}} | P0 | {{Metric}} |
| {{Goal 2}} | P1 | {{Metric}} |

### 1.5 Non-Goals (Explicitly Out of Scope)

{{From Q8 — the tempting-but-wait list. 3–5 explicit non-goals + deferred
features. This is what protects the build from scope creep.}}

---

## 2. User Personas

### 2.1 Primary Persona: {{Persona Name}} {{(Inferred) if not stated}}

| Attribute | Detail |
|-----------|--------|
| **Role** | {{e.g., "Night-shift nurse at a mid-size hospital"}} |
| **Technical level** | {{Beginner / Intermediate / Advanced}} |
| **Job-to-be-done** | "When {{situation}}, I want to {{motivation}}, so I can {{outcome}}" |
| **Current workaround** | {{how they solve this today}} |
| **Pain frequency** | {{daily / weekly / monthly}} |

### 2.2 Secondary Persona: {{Persona Name}} {{(Inferred)}}

{{Same structure — only if a real second persona exists. Don't invent one.}}

---

## 3. Functional Requirements

> Every requirement has an ID, a priority with justification, the persona/story
> it serves, and **verifiable** acceptance criteria — "shows a confirmation
> dialog before deleting," never "works correctly." **Challenge every P0: if
> everything is P0, nothing is.**

### 3.1 P0 — Must Have (product is useless without it)

| ID | Requirement | User Story | Acceptance Criteria (verifiable) |
|----|-------------|------------|----------------------------------|
| FR-1 | {{one sentence}} | As a {{persona}}, I want {{action}} so that {{outcome}} | {{observable pass/fail condition}} |
| FR-2 | ... | ... | ... |

### 3.2 P1 — Should Have (significant workaround needed without it)

| ID | Requirement | User Story | Acceptance Criteria |
|----|-------------|------------|---------------------|
| FR-X | ... | ... | ... |

### 3.3 P2 — Nice to Have (valuable but deferrable)

| ID | Requirement | User Story | Acceptance Criteria |
|----|-------------|------------|---------------------|
| FR-Y | ... | ... | ... |

---

## 4. User Flows

### 4.1 {{Core Loop Name}} (Primary — first open → value)

```
{{Screen 1}} → {{Screen 2}} → {{Decision}} → [Branch A] / [Branch B]
```

**Steps:**
1. {{User action}}
2. {{System response}}
3. {{Next user action → value received}}

**Error & recovery states:**
- {{Error condition}} → {{what the user sees and how they recover}}

### 4.2 {{Secondary Flow Name}}

{{Same structure. Include error/recovery for each — a flow without an error path
isn't finished.}}

---

## 5. Data Model

### 5.1 Core Entities

```
{{EntityName}}
├── id: UUID (PK)
├── field_name: Type
├── created_at: Timestamp
└── relationship: → OtherEntity
```

### 5.2 Entity Relationships

```
{{EntityA}} --1:N--> {{EntityB}}
{{EntityB}} --N:M--> {{EntityC}}
```

### 5.3 External Integrations

| Service | Purpose | Data Flow |
|---------|---------|-----------|
| {{e.g., "Stripe"}} | {{Payments}} | {{Inbound / Outbound}} |

---

## 6. Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| **Performance** | Page load | < {{X}}s at 95th percentile |
| **Performance** | API response | < {{X}}ms at 95th percentile |
| **Security** | Authentication | {{e.g., "email + OAuth, refresh-token rotation"}} |
| **Security** | Data protection | {{at rest / in transit; compliance if any}} |
| **Scalability** | Concurrent users | {{X}} |
| **Scalability** | Data volume | {{X}} records in first {{Y}} months |
| **Accessibility** | WCAG level | {{AA / AAA}} |
| **Platform** | Browsers | {{last 2 versions of major browsers}} |
| **Platform** | Mobile | {{Responsive / PWA / Native}} |

---

## 7. Assumed Spec (Table Stakes)

Assumed on every build unless the user explicitly opts out:

- **Modern, attractive design** — a clean, current design system.
- **Mobile-responsive layout** — mobile-first, touch targets ≥ 44px.
- **Brand direction**: {{from Q10 — or "Modern, clean, mobile-first" if none
  specified}}

---

## 8. Constraints & Strategy

### 8.1 Iron Triangle Choice

**{{Faster / Better / Cheaper}}** — {{what this corner means for this specific
build: how aggressively we scope, how many validation gates, what "good enough"
looks like. This choice governs the milestone plan's pacing and depth.}}

{{If Cheaper: note the Fast Track decision and the declared UX-to-dev split — see
the companion MILESTONES.md and iron-triangle-cheaper discipline.}}

### 8.2 Hard Constraints

{{From Q5 — deadlines, budget ceilings, compliance, must-integrate systems. Or
"No hard constraints identified."}}

### 8.3 Assumptions We're Making

{{Listed explicitly so they can be tested. Every (Inferred) value is an
assumption.}}

---

## 9. Success Metrics

| Type | Metric | Target | Measurement Method |
|------|--------|--------|-------------------|
| **North Star** | {{from Q4}} | {{target}} | {{how measured}} |
| **Secondary** | {{metric}} | {{target}} | {{how measured}} |
| **Guardrail** | {{metric we must NOT harm}} {{(Inferred)}} | {{threshold}} | {{how measured}} |

> The guardrail metric is inferred, not asked — it's the thing we must not break
> while chasing the North Star (e.g. "don't tank load time," "don't spike
> churn").

---

## 10. Open Questions

| # | Question | Owner | Target Resolution |
|---|----------|-------|-------------------|
| 1 | {{}} | {{}} | {{date}} |

---

## 11. Milestone Summary

{{High-level overview — full plan lives in the companion MILESTONES.md, whose
count and pacing are set by the Iron Triangle choice above.}}

| Milestone | Focus | Key Deliverables |
|-----------|-------|-----------------|
| M1 | {{}} | {{}} |
| M2 | {{}} | {{}} |
| M3 | {{}} | {{}} |

---

*Generated by Product PRD Builder — interview-driven requirements synthesis.*
