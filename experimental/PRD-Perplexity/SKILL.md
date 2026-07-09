---
name: prd-creator
description: Structured interview-driven PRD generator that transforms raw product ideas into comprehensive, locked Product Requirements Documents and phased, spec-driven project plans. Use when the user wants to create a PRD, write product requirements, plan a feature, spec out a project, define product specifications, create a product roadmap, turn an idea into a build plan, or when asked to interview-to-discover requirements. Triggers on phrases like "create PRD", "write requirements", "product spec", "feature plan", "spec-driven development", "milestone plan", or when the user describes an app/feature idea and needs structured documentation. Also use when the user wants to break a PRD into implementation phases or milestones.
---

# PRD Creator

Generate comprehensive Product Requirements Documents through a structured, phased interview process that infers and synthesizes requirements, then produces a locked PRD plus a phased, spec-driven project plan.

## Core Workflow

Run the **eight-phase structured interview** sequentially. At each phase, **infer unstated requirements** from the user's responses, **propose sensible defaults** with clear rationale, and **lock the phase** before advancing. Never skip phases or jump ahead.

After all eight phases are locked:
1. Generate the final PRD using `references/prd-template.md`
2. Generate the phased project plan using `references/milestone-template.md`
3. Present both documents to the user for approval
4. On approval, save files to the designated output directory

## Phase 1: Brain Dump & Core Purpose

Prompt the user to describe their idea freely — what it is, what problem it solves, who it is for. Accept raw, unstructured input.

**Synthesis action:** Distill their input into a 1-3 sentence "What We're Building" statement. Identify the core user problem, the target audience, and the primary value proposition. Propose this synthesis to the user and ask for confirmation or edits. Lock before proceeding.

## Phase 2: User Personas & Jobs-to-be-Done

Based on Phase 1, infer the primary and secondary user personas. For each:
- Propose a persona name, role, and core goal
- Identify the "job" they hire this product to do (JTBD format: "When [situation], I want to [motivation], so I can [outcome]")
- Estimate technical proficiency level

Present 2-3 persona proposals. Ask the user to confirm, edit, or add personas. Lock before proceeding.

## Phase 3: Functional Requirements

Derive functional requirements from the core purpose and personas. Organize into:

| Priority | Label | Criteria |
|----------|-------|----------|
| P0 | Must Have | Core feature; product is useless without it |
| P1 | Should Have | Important feature; significant workaround needed without it |
| P2 | Nice to Have | Valuable but deferrable; workarounds acceptable |

**For each requirement**, propose:
- Requirement ID (e.g., FR-1, FR-2)
- One-sentence description
- Priority level with justification
- User story mapping (which persona needs this)

Present as a numbered list. Ask for confirmation, reprioritization, or additions. Challenge every P0 — if everything is P0, nothing is P0. Lock before proceeding.

## Phase 4: User Flows & Key Screens

Map the critical user flows based on locked requirements. For each primary flow:
- Name the flow (e.g., "Onboarding Flow", "Core Action Flow")
- List the sequence of screens/steps
- Identify decision points and branches
- Note error states and recovery paths

Propose 3-5 key flows. Ask for confirmation or edits. Lock before proceeding.

## Phase 5: Data Model & Integrations

Infer the core data entities and their relationships from functional requirements and user flows:
- List primary entities (e.g., User, Project, Task)
- Describe key fields per entity
- Identify relationships (one-to-many, many-to-many)
- Flag external integrations (auth, payments, APIs, storage)

Propose a simplified data model. Ask for confirmation or additions. Lock before proceeding.

## Phase 6: Non-Functional Requirements

Propose based on product type and user expectations:
- **Performance**: Response time targets, concurrent user estimates
- **Security**: Auth model, data protection level, compliance needs
- **Scalability**: Expected data volume, growth trajectory
- **Accessibility**: Target WCAG level
- **Platform**: Web/mobile/both, browser support

Lock before proceeding.

## Phase 7: Success Metrics & Validation

Define how to measure success:
- Primary metric (North Star)
- 2-3 secondary metrics
- Counter-metrics to guard against
- Validation method (beta users, A/B test, etc.)

Lock before proceeding.

## Phase 8: Scope Boundaries & Non-Goals

Explicitly define what is **out of scope** for this PRD. This is critical for preventing scope creep.
- List 3-5 explicit non-goals
- Identify future-phase features
- Note deferred platform support

Lock before proceeding.

## Output Generation

After all phases are locked:

1. **Read `references/prd-template.md`** and populate with all locked content
2. **Read `references/milestone-template.md`** and generate phased milestones
3. Present both documents to the user
4. On user approval, save to the user's specified directory (default: `_build_plan/`)

### Milestone Generation Rules

When breaking the PRD into milestones:
- **Milestone 1**: Foundation — database schema, auth, project scaffolding, CI/CD
- **Milestone 2**: Core data layer — API endpoints, CRUD operations, data validation
- **Milestone 3**: Primary user flows — the main screens and interactions
- **Milestone 4**: Edge cases, error handling, polish
- **Milestone 5+**: Advanced features, integrations, performance optimization

Each milestone must include:
- Clear scope boundary (what is in/out)
- Dependencies on previous milestones
- Verifiable completion criteria
- A prompt-ready description for agent execution

## Key Principles

- **Always propose defaults**: Never ask open-ended questions. Propose a specific answer with rationale and ask for confirmation or edits.
- **Infer aggressively**: Read between the lines. If the user describes a social app, infer they need auth, profiles, and a feed.
- **Lock before proceeding**: Each phase must be explicitly confirmed before moving to the next. This prevents drift.
- **Write for implementers**: Use language clear enough for junior developers and AI agents. No vague requirements.
- **Acceptance criteria must be verifiable**: "Button shows confirmation dialog before deleting" not "Works correctly."
