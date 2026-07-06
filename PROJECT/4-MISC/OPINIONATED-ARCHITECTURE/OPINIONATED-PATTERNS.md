---
title: Opinionated architectural philosophy — the major camps
status: Active (operational — governs agent behavior; source for AGENTS.md extraction)
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: guiding-principles
goal: >
  Capture the major opinionated camps in software architecture as a reference/decision framework —
  what each camp optimizes for, its core opinion, its buzzwords, and its critique — plus an inline
  GUIDING-PRINCIPLES directive per camp for extraction into a project's AGENTS.md. These are axes
  engineers compose from, not a strict partition; the Precedence stack resolves conflicts.
---

# Opinionated architectural philosophy — the major camps

Six major segments of opinionated architectural philosophy in software engineering, plus honorable
mentions. These camps often clash because they prioritize fundamentally different system qualities
(e.g., maintainability vs. performance vs. time-to-market vs. correctness). Each camp carries an
inline **Use this as your GUIDING-PRINCIPLES** block — the directive to extract into a project's
AGENTS.md.

## Precedence — resolve conflicts in this order

Taxonomy order below is *not* precedence order. When two extracted directives pull in opposite
directions, resolve top-down:

1. **Correctness** — a required check or an unrepresentable-illegal-state design wins.
2. **Functional (single write path)** — one door per piece of state, even if a shortcut is shorter.
3. **Structure (boundaries)** — but only at a seam that has earned an abstraction.
4. **Pragmatism (default)** — the simplest thing that satisfies the requirement governs everything not claimed above.
5. **Reactive / Data-Oriented** — earned by measurement or a proven independent-scaling need, never by default.

Simplicity is the default and governs unless a principle higher in this stack has a specific reason to
override it. This stack is the only precedence; extract it alongside whichever camps you pull.

## Table of contents

1. [The Structuralists (SOLID / Clean Architecture)](#1-the-structuralists-the-solid--clean-architecture-camp)
2. [The Functional Purists (Data Transformation)](#2-the-functional-purists-the-data-transformation-camp)
3. [The Data-Oriented Designers (Hardware First)](#3-the-data-oriented-designers-the-hardware-first-camp)
4. [The Reactive Decouplers (Async Messaging)](#4-the-reactive-decouplers-the-async-messaging-camp)
5. [The Radical Pragmatists (Worse is Better / KISS)](#5-the-radical-pragmatists-the-worse-is-better--kiss-camp)
6. [The Correctness Zealots (Make Illegal States Unrepresentable)](#6-the-correctness-zealots-the-make-illegal-states-unrepresentable-camp)
7. [Honorable mentions](#honorable-mentions)
8. [Synthesis: axes, not a partition](#synthesis-axes-not-a-partition)

## 1. The Structuralists (The "SOLID / Clean Architecture" Camp)

Their primary philosophy is that software complexity is tamed through strict boundaries, separation
of concerns, and dependency management. They believe that code should model the business domain
perfectly and remain completely independent of frameworks, databases, or UI.

* **The Core Opinion:** If your architecture is correct, changing a database or swapping a web
  framework should be a trivial task that doesn't touch the core business logic.
* **Key Tenets & Buzzwords:** SOLID principles, Dependency Inversion, Clean Architecture, Hexagonal
  Architecture (Ports and Adapters), Domain-Driven Design (DDD), Design Patterns.
* **The Critique:** Critics call this "Architecture Astronautics." They argue it leads to massive
  amounts of boilerplate code, deep inheritance hierarchies, and over-abstraction, making simple
  features take weeks to implement.

**Use this as your GUIDING-PRINCIPLES:**
Keep boundaries where change happens (Structure). Core business logic must not import frameworks, HTTP, or SQL — those are details that depend on the domain, never the reverse. Introduce an abstraction only at a seam that has actually moved twice or is contractually likely to; a boundary with one implementation is speculation, not architecture. When a module crosses ~4 states, model it as an explicit FSM rather than scattered booleans. Let structure grow into the codebase as it earns its keep, not up front.

## 2. The Functional Purists (The "Data Transformation" Camp)

This camp believes that the root of all software evil is *mutable state*. They view software not as
a collection of interacting "objects" (which they find unpredictable), but as a strict pipeline of
data transformations.

* **The Core Opinion:** Functions should be pure — given the same input, they always produce the same
  output, with zero side effects. State should be pushed to the edges of the system (the database or
  the UI), while the core logic remains entirely stateless and immutable.
* **Key Tenets & Buzzwords:** Immutability, Pure Functions, Unidirectional Data Flow, Elm/Redux
  architecture, Event Sourcing, State as a Function of Time.
* **The Critique:** Critics argue this paradigm is a steep mental leap for average developers, can be
  highly unergonomic for standard CRUD (Create, Read, Update, Delete) apps, and can incur
  memory/performance overhead from constantly copying data instead of mutating it.

**Use this as your GUIDING-PRINCIPLES:**
Discipline state, don't scatter it (Functional). Push mutable state to the edges — the database, the UI, the boundary — and keep the core a set of transformations that give the same output for the same input. Maintain a single write path per piece of state; concurrent writers through one door, never many. Prefer append-only event logs over in-place mutation wherever the history has value or the audit matters. Immutability is a tool for predictability here, not a religion — mutate freely inside a function whose outputs are pure.

## 3. The Data-Oriented Designers (The "Hardware First" Camp)

Originating largely from the video game industry but spreading to high-performance computing, this
camp believes Object-Oriented Programming (OOP) is fundamentally at odds with how modern computer
hardware (CPUs and memory) actually works.

* **The Core Opinion:** Objects scatter data randomly across memory, destroying CPU cache efficiency.
  Software should be designed around the *layout of data in memory* and how the hardware processes
  it, not around conceptual "objects" in the developer's mind.
* **Key Tenets & Buzzwords:** Data-Oriented Design (DOD), Struct of Arrays (SoA) vs. Array of Structs
  (AoS), Entity Component Systems (ECS), Cache Locality, SIMD (Single Instruction, Multiple Data).
* **The Critique:** Critics point out that this approach sacrifices human readability for machine
  efficiency. It is usually overkill for 95% of business applications where network latency and
  database queries are the bottlenecks, not CPU cache misses.

**Use this as your GUIDING-PRINCIPLES:**
Measure before you optimize for hardware (Data-Oriented). Do not assert "fast enough" or "too slow" without a profiler; name the assumption and its trigger to revisit instead (assumes <1k rows, revisit if the table grows). Default to the readable data shape and bounded queries; reach for cache-friendly layouts, batching, or SoA only on a path proven hot by measurement. Ninety-five percent of the time the bottleneck is a query or the network, not a cache miss — fix that first. When you do optimize the hot path, leave the ceiling and the upgrade path in a comment.

## 4. The Reactive Decouplers (The "Async Messaging" Camp)

This camp believes that synchronous, blocking calls are the devil. They argue that tightly coupling
systems together via direct HTTP calls creates brittle, unscalable monoliths. Their philosophy
centers on asynchronous communication and eventual consistency.

* **The Core Opinion:** Systems should be composed of small, autonomous services that communicate
  entirely through events and messages. This allows systems to scale independently and remain highly
  available even if downstream services fail.
* **Key Tenets & Buzzwords:** Event-Driven Architecture, CQRS (Command Query Responsibility
  Segregation), Actor Model (Akka/Erlang), Microservices, Pub/Sub, Eventual Consistency, Reactive
  Manifesto.
* **The Critique:** Critics argue this creates "distributed monoliths" that are a nightmare to debug.
  Tracing a single user request across 5 asynchronous services is incredibly hard, and managing
  eventual consistency introduces massive complexity into basic business logic.

**Use this as your GUIDING-PRINCIPLES:**
Async only where decoupling earns its cost (Reactive). Prefer a synchronous, in-process call by default — it is trivial to trace, debug, and reason about. Introduce events, queues, or a service boundary only when two parts genuinely must scale, deploy, or fail independently; splitting for its own sake buys a distributed monolith that is a nightmare to debug. When you do go async, make the flow traceable end-to-end and treat eventual consistency as a deliberate cost you are paying, not a side effect. One event-sourced log with a single writer beats five chatty services exchanging state.

## 5. The Radical Pragmatists (The "Worse is Better / KISS" Camp)

This camp is highly skeptical of grand architectural theories. They believe that premature
optimization and over-engineering are the biggest killers of software projects. Their philosophy is
to get working software into users' hands as fast as possible and let real-world requirements
dictate the architecture.

* **The Core Opinion:** The best architecture is the simplest one that works today. A "Big Ball of
  Mud" (spaghetti code) is actually a valid starting point if it allows you to discover what the
  product actually needs to be.
* **Key Tenets & Buzzwords:** YAGNI (You Aren't Gonna Need It), KISS (Keep It Simple, Stupid), "Worse
  is Better," Monolith-first, Ship Fast/Iterate, Majestic Monolith.
* **The Critique:** Critics argue this philosophy often acts as an excuse for laziness and lack of
  discipline. While it works well for early-stage startups, it inevitably leads to technical debt
  that paralyzes development years down the line if refactoring is never prioritized.

**Use this as your GUIDING-PRINCIPLES:**
Simplicity is the default (Pragmatism). Build the simplest thing that satisfies the stated requirement and nothing more — no interface with one implementation, no config for a value that never changes, no scaffolding "for later." Reach for the standard library before custom code and a native platform feature before a dependency. Ship the lazy version and question extra scope in the same breath; do not relitigate an explicit requirement, only the machinery around it. Simplicity governs unless the Precedence stack gives another principle a specific reason to override.

**Daily operating playbook** for the Radical Pragmatists — the working rules a KISS/YAGNI engineer actually runs on, not the philosophy poster.
Do (constructive patterns)

Ship the vertical slice first. One thin path all the way through — request to DB to response — beats three polished layers with no seam between them. You learn what the product is by using it, not by diagramming it.
Delete before you add. The default move on any change is "can existing code do this?" A removed branch is a bug that can't happen; the shortest working diff wins.
Inline until it hurts twice. Write it straight, duplicated, in place. Extract the abstraction only when the third caller shows up and the shape has stopped moving — not on the second, and never on the first.
Name the shortcut where you take it. A shortcut with a // ponytail: global lock, per-account if throughput matters-style comment is a decision; the same shortcut silent is a landmine. Leave the ceiling and the upgrade trigger, not an apology.
Reach for stdlib → native → installed dep → custom, in that order. Every rung down the ladder is code you don't own and can't be paged for. Stop at the first rung that holds.

**Don't (anti-patterns)**

Building for the scale you don't have. Sharding, queues, and a service mesh for 200 users a day is renting complexity against revenue that doesn't exist. Solve the load you can measure, not the load you imagine.
The speculative interface. One implementation behind an abstraction isn't flexibility, it's a guess about the future wearing a costume. You'll refactor it anyway when the second implementation actually arrives and it doesn't fit the shape you invented.
"Worse is Better" as cover for careless. KISS licenses less code, not flimsier code. Skipping input validation at a trust boundary or picking the algorithm that's wrong on edge cases isn't lazy-efficient, it's just wrong — the Correctness override sits above you for exactly this.
Debt with no ledger. Shortcuts are fine; unnamed, untracked, unbounded shortcuts compound into the Big Ball of Mud the critics warn about. If you never write down what you deferred, "we'll refactor later" is a lie you're telling on purpose.
Relitigating the requirement to avoid the work. YAGNI cuts machinery, not stated needs. "The user doesn't really need restart" when they asked for restart is cost-shifting dressed as minimalism — shrink how it's built, never wave away that it's built.

## 6. The Correctness Zealots (The "Make Illegal States Unrepresentable" Camp)

Runtime bugs are design failures the compiler or model checker should have caught. This camp's enemy
is *runtime uncertainty*: architecture's job isn't to handle invalid states gracefully — it's to make
them impossible to construct in the first place.

* **The Core Opinion:** If a bad state can't be represented, it can't happen. Push correctness into
  types, constraints, and proofs rather than runtime guards.
* **Key Tenets & Buzzwords:** Parse Don't Validate, algebraic data types, typestate, exhaustive
  matching, TLA+/formal methods, property-based testing, "if it compiles, it works." Rust, Haskell,
  strict TypeScript.
* **Why it's not Camp 2:** The Functional Purists' enemy is *mutable state*; this camp's enemy is
  *runtime uncertainty*. Rust is happily mutable yet firmly here. Amazon model-checked DynamoDB with
  TLA+ while writing thoroughly imperative code.
* **The Critique:** "Type Tetris" — days spent encoding an invariant a code review would've caught in
  minutes, brutal onboarding curves, and formal methods rarely surviving contact with a deadline.

**Use this as your GUIDING-PRINCIPLES:**
Make illegal states unrepresentable (Correctness). Prefer designs where the compiler, the type, or a database constraint makes a bad state impossible to construct over runtime code that validates and handles it after the fact. Parse input at the trust boundary into a shape the rest of the system can trust, so downstream code never re-checks. Every non-trivial branch, loop, parser, or money/security path leaves one runnable check behind — the smallest thing that fails if the logic breaks. This overrides simplicity: a check is not optional machinery, and an edge-case-correct solution beats a shorter flimsy one.

## Honorable mentions

Two camps ranked just below the six above, plus one emergent one worth extracting when it applies:

* **Platform Maximalists ("buy don't build" / serverless-first).** Architecture = composing managed
  services; your job is glue code. Conspicuously absent from the list despite being the dominant
  *economic* philosophy in modern startups. Critique: lock-in, cost surprises, you're renting your
  architecture. Ranks 7th, not 6th: it's arguably a procurement stance more than a design philosophy.
* **Database-Centrists ("just use Postgres").** The exact inversion of Camp 1 — the DB isn't a
  swappable detail, it *is* the application (constraints, stored procs, the Supabase/PostgREST
  resurgence).
* **Local-first (emergent — where rebalance-OS lives).** Kleppmann, CRDTs, sync engines. Not yet a
  "major segment," but load-bearing here.

  **Use this as your GUIDING-PRINCIPLES (local-first repos only):**
  State is local-authoritative; sync is a merge, not a fetch. The merge rule is part of the schema, not an afterthought — decide per field how two divergent writes reconcile (last-writer-wins, CRDT, or explicit conflict surface) before the field ships. Never block a local write on the network; the network reconciles later. Treat the sync log as append-only and the source of truth for how state got where it is.

## Synthesis: axes, not a partition

One structural nuance worth flagging if you use this in a talk: these aren't six answers to one
question. They're poles on *different axes* — logic organization (1), state discipline (2), hardware
sympathy (3), communication topology (4), process economics (5), static guarantees (6). So they don't
partition; working engineers are composites. A YAGNI pragmatist running event-sourced append-only logs
with an FSM adoption threshold is straddling camps 5, 4, and 6 simultaneously. Buckets work for naming
tribes; the Precedence stack at the top is what makes composing their directives decidable.