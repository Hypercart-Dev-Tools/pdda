---
title: agents-builder skill — interview a user's architectural style into an AGENTS-TEMP.md
status: Active — planned; queued for the 2026-07-07 marathon (phase p2)
created: 2026-07-06
updated: 2026-07-06
owner: noel
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 1
goal: >
  A new Claude Code skill that interviews a user about their project and produces an AGENTS-TEMP.md
  capturing their preferred architectural style, drawn from the six opinionated camps + honorable
  mentions in AGENTS-BUILDER.md. It NEVER overwrites or edits an existing AGENTS.md — it only writes a
  side file the user hand-merges. Design locked with the operator: scenario-inference interview, full
  (directives + Daily playbooks) output, global skill home with the camps content embedded.
---

# agents-builder skill

An interactive skill that turns a short interview into a starting-point `AGENTS-TEMP.md` in the user's
project — a curated extract of the architectural camps in
[`AGENTS-BUILDER.md`](AGENTS-BUILDER.md), weighted to how they actually build. The user then hand-merges
it; the skill **never** touches an existing `AGENTS.md`.

## Status

| What was just completed | What's next |
|---|---|
| Planned with the operator; three design forks locked (scenario→infer interview, full directives+playbooks output, global skill with embedded camps content). Queued as phase `p2` of the [2026-07-07 marathon](../../marathon/MARATHON-2026-07-07.yaml). | Build `skills/agents-builder/` (SKILL.md + reference/camps.md + scripts/build_agents_temp.py) + `test/agents-builder.sh`; then hand-install to `~/.claude/skills/`. |

## Locked decisions (operator, 2026-07-06)

- **Interview = scenario → infer camps.** The skill asks about the *project* (what you're building,
  scale today, correctness-critical paths, async/independent-scaling needs, team familiarity with
  FP/types), then maps answers to the six camps + honorable mentions. The user needn't know the
  taxonomy; the mapping heuristic lives in the skill.
- **Output = full.** `AGENTS-TEMP.md` carries the **Precedence stack** + each selected camp's
  **GUIDING-PRINCIPLES** paragraph **and** its **Do / Don't Daily playbook** — the richest form, closest
  to the source doc.
- **Home = global, content embedded.** The skill installs to `~/.claude/skills/agents-builder/` and
  **bundles** the camps taxonomy so it works in any repo (not just this one).

## Isolation contract (hard requirement)

- **Never modifies `AGENTS.md`.** The skill only ever writes `AGENTS-TEMP.md` in the current project
  root. If `AGENTS-TEMP.md` already exists, it writes `AGENTS-TEMP-<n>.md` rather than clobbering. It
  reads an existing `AGENTS.md` only to *show a diff hint*, never to edit it.
- **Deterministic assembly.** The interview (Claude, from `SKILL.md`) resolves a camp selection; a
  helper script does the file assembly from the embedded taxonomy, so the output is reproducible and
  testable independent of the model.

## Build shape

Because a marathon runs inside this repo and can't write outside it, the artifact is **built repo-local**
under `skills/agents-builder/`, then **installed to the global skills dir by a documented manual step**
(the skill's runtime home is `~/.claude/skills/agents-builder/`).

- `skills/agents-builder/SKILL.md` — the scenario interview + the scenario→camps inference heuristic +
  the precedence-ordering rule, ending in a call to the assembler. Frames every question, states the
  never-touch-AGENTS.md contract, and shows the user the selection before writing.
- `skills/agents-builder/reference/camps.md` — the camps taxonomy **copied from `AGENTS-BUILDER.md`**
  (Precedence stack, the 6 camps each with GUIDING-PRINCIPLES + Daily playbook, honorable mentions incl.
  local-first, the synthesis note). This is the embedded content that makes the skill portable.
- `skills/agents-builder/scripts/build_agents_temp.py` — deterministic assembler. Input: selected camp
  ids + precedence order + primary (as JSON/args). Output: `AGENTS-TEMP.md` in the target project =
  Precedence stack + per selected camp {GUIDING-PRINCIPLES paragraph + Daily playbook}, parsed out of
  `reference/camps.md`. Refuses to write over `AGENTS.md`; auto-suffixes if `AGENTS-TEMP.md` exists.
- `test/agents-builder.sh` — asserts: a given selection produces a well-formed `AGENTS-TEMP.md`
  (Precedence present, each selected camp's directive **and** playbook present, unselected camps absent);
  an existing `AGENTS.md` is left byte-for-byte untouched; an existing `AGENTS-TEMP.md` is not clobbered.

## Phase p2 — build the skill (repo-local) + tests

Deliver the four files above. Manual post-build step (human, out of marathon scope): copy
`skills/agents-builder/` → `~/.claude/skills/agents-builder/` and smoke-test `/agents-builder` in a
throwaway repo.

**QA gate:** `python3 skills/agents-builder/scripts/build_agents_temp.py` given a sample selection emits
a full `AGENTS-TEMP.md` (Precedence + selected directives + playbooks, unselected camps absent); a
pre-existing `AGENTS.md` is provably untouched and a pre-existing `AGENTS-TEMP.md` is not clobbered;
`test/agents-builder.sh` green. Skill body (`SKILL.md`) documents the scenario→camps mapping and the
install step. Shippable alone (install is the human follow-up).

## Open follow-ups (not this phase)

- Whether to also ship a `/agents-builder` reverse mode that critiques an *existing* AGENTS.md against
  the camps. Parked.
- `AGENTS-BUILDER.md` itself is a `guiding-principles` doc mis-shelved in `2-WORKING` (fails status-table
  + roadmap-coverage). Reshelving it is tracked separately in the myriad backlog, not here.
