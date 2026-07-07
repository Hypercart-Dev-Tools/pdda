# Phase p2 — agents-builder skill (repo-local build; global install is a human follow-up)

Build a Claude Code skill that interviews a user about their project and emits an `AGENTS-TEMP.md`
capturing their preferred architectural style. Canonical contract:
`PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md`. Content source:
`PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/OPINIONATED-PATTERNS.md` (the SSOT taxonomy doc — consolidated
2026-07-07 from a duplicate that had drifted in `PROJECT/2-WORKING/AGENTS-BUILDER.md`, now deleted).

## Locked design (do not redecide)

- **Interview = scenario → infer camps.** `SKILL.md` asks about the project (what's being built, scale
  today, correctness-critical paths, async/independent-scaling needs, team FP/type familiarity), then
  maps answers to the six camps + honorable mentions. The mapping heuristic lives in `SKILL.md`.
- **Output = full.** `AGENTS-TEMP.md` = the **Precedence stack** + each selected camp's
  **GUIDING-PRINCIPLES** paragraph **and** its **Do / Don't Daily playbook**.
- **Home = global, content embedded.** Bundle the camps taxonomy into the skill so it is portable.
- **Non-negotiable quality goals are always included, unconditionally.** Every generated
  `AGENTS-TEMP.md` also carries the **Non-negotiable quality goals** block (Maintainable, Durable,
  Secure, Performant, Portable) from `OPINIONATED-PATTERNS.md`, right after the Precedence stack. This
  is NOT part of the interview's camp selection — no camp can opt out of it, and even a zero-camp
  (precedence-only) run still emits it.

## Task

Deliver these four files:

- `skills/agents-builder/SKILL.md` — the scenario interview, the scenario→camps inference heuristic, the
  precedence-ordering rule, the never-touch-`AGENTS.md` contract, a "show the selection, confirm, then
  write" flow, and the call to the assembler. Include the documented manual install step
  (`skills/agents-builder/` → `~/.claude/skills/agents-builder/`).
- `skills/agents-builder/reference/camps.md` — the camps taxonomy **copied from
  `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/OPINIONATED-PATTERNS.md`**: Precedence stack, the
  **Non-negotiable quality goals** block, all six camps (each with its GUIDING-PRINCIPLES paragraph
  **and** Daily playbook), honorable mentions incl. local-first, and the synthesis note. This is the
  embedded content. (Note: `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/` also holds an existing reverse-
  diagnosis skill, `SKILL.md`, that reads this same taxonomy file — read it for awareness, do not
  edit it, and do not merge it into this build.)
- `skills/agents-builder/scripts/build_agents_temp.py` — deterministic assembler. Input: selected camp
  ids + precedence order + primary (JSON on stdin or args). Output: writes `AGENTS-TEMP.md` in the
  **target project cwd** = Precedence stack + **Non-negotiable quality goals (always, unconditionally,
  even with zero camps selected)** + per selected camp {GUIDING-PRINCIPLES + Daily playbook}, parsed
  out of `reference/camps.md`. **Never writes `AGENTS.md`.** If `AGENTS-TEMP.md` already exists, write
  `AGENTS-TEMP-<n>.md` instead of clobbering. Python 3.6+, stdlib only.
- `test/agents-builder.sh` — asserts a sample selection yields a well-formed `AGENTS-TEMP.md` (Precedence
  present; **Non-negotiable quality goals block present regardless of which camps were selected,
  including a zero-camp run**; each selected camp's directive AND playbook present; unselected camps
  absent); a pre-existing `AGENTS.md` is byte-for-byte untouched; a pre-existing `AGENTS-TEMP.md` is not
  clobbered (suffix used).

## Your write lane (STRICT — containment-enforced)

Edit **only**: `skills/agents-builder/SKILL.md`, `skills/agents-builder/reference/camps.md`,
`skills/agents-builder/scripts/build_agents_temp.py`, `test/agents-builder.sh`.

Read for reference (do NOT edit): `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/OPINIONATED-PATTERNS.md`
(copy its content into `camps.md`), `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/SKILL.md` (a different,
already-shipped skill — for awareness only), `PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md`. Do NOT edit
any `AGENTS.md`, `OPINIONATED-PATTERNS.md`, or anything under `~/.claude/`. The harness commits for
you; do not run git.

## Guardrails

- **Never modify `AGENTS.md`.** The skill and its assembler only ever produce `AGENTS-TEMP.md` (or a
  suffixed variant). This is the load-bearing safety property — the reviewer will test it explicitly.
- **Deterministic assembly.** Content comes from the embedded `camps.md`, parsed by section — the model
  picks camps; the script assembles. No network, no model call in the script.
- **Repo-local only.** Build under `skills/agents-builder/`; the global install is a HUMAN step, not part
  of this artifact. Do not attempt to write outside the repo.

## Definition of Done (reviewer gate)

- `python3 skills/agents-builder/scripts/build_agents_temp.py` with a sample selection emits a full
  `AGENTS-TEMP.md` (Precedence + **Non-negotiable quality goals, always present** + selected camps'
  directives + playbooks; unselected camps absent). The same holds for a zero-camp selection
  (Precedence + quality goals only, still emitted).
- A pre-existing `AGENTS.md` is provably untouched; a pre-existing `AGENTS-TEMP.md` is not clobbered.
- `test/agents-builder.sh` is green; `utils/pdda/pdda.sh run` still green.
- `SKILL.md` documents the scenario→camps mapping and the manual install step. No file outside the write
  lane is modified.
