---
title: Marathon Plan (2026-07-07) — myriad-review reader (GH-11) + agents-builder skill
status: Archived (4-MISC) 2026-07-22 — never fired; both lanes overtaken by events
created: 2026-07-07
updated: 2026-07-22
owner: noel
branch: main
doc_type: project
lanes: [GH-11, agents-builder-skill]
execution: parallel subagents, one per lane — independent (disjoint) write-sets
goal: >
  Two independent, repo-general build phases for today's marathon: p1 myriad-review reader (GH-11,
  read-only backlog reader + a one-pointer pdda.sh wiring) and p2 agents-builder skill (scenario-
  inference interview skill). No depends_on — either order. Hand-authored (Option B): the ROADMAP
  auto-generator (Option A, .xyz/utils/marathon-plan.sh) currently reports 0 active lanes across the
  full backlog (9 held) since most ledger items are gated on other work; these two lanes were
  deliberately curated and pre-briefed outside that ranking.
---

# Marathon Plan — 2026-07-07 · myriad-review reader + agents-builder skill

## Status

| What was just completed | What's next |
|---|---|
| **Archived 2026-07-22 without ever firing.** Both lanes were planned and briefed (`marathon/MARATHON-2026-07-07.yaml` + `marathon/briefs/`), then overtaken by events: lane p1 (myriad-review reader) shipped independently and issue [#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11) is CLOSED; lane p2 (agents-builder skill) moved to its own tracked capture, [AGENTS-BUILDER-SKILL.md](../2-WORKING/AGENTS-BUILDER-SKILL.md) under open issue [#42](https://github.com/Hypercart-Dev-Tools/pdda/issues/42). | Nothing — this plan is superseded. Live agents-builder work continues under #42; do not fire this YAML. |

## Why this exists

- **GH-11** traces to issue [#11](https://github.com/Hypercart-Dev-Tools/pdda/issues/11) — the
  `/myriad` parking lot has no read path today; the fix is a tiny read-only reader plus a one-pointer
  `pdda.sh run` wiring so `/pdda` surfaces the backlog transitively.
- **agents-builder skill** traces to the operator-locked design in
  [PROJECT/2-WORKING/AGENTS-BUILDER-SKILL.md](AGENTS-BUILDER-SKILL.md) — a scenario-inference
  interview skill that writes `AGENTS-TEMP.md` from the camps taxonomy in
  `PROJECT/4-MISC/OPINIONATED-ARCHITECTURE/OPINIONATED-PATTERNS.md`; never touches an existing
  `AGENTS.md`.

## Collision map — the one safety rule

Two lanes may run concurrently **iff their write-sets are disjoint.**

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| `utils/pdda/pdda-myriad.sh`, `test/pdda-myriad.sh`, `utils/pdda/pdda.sh` | ✅ only GH-11 touches this | #11 |
| `skills/agents-builder/**`, `test/agents-builder.sh` | ✅ only agents-builder-skill touches this | agents-builder-skill |

No overlap between the two lanes' write-sets — safe to run in the same wave.

## Per-lane summary

| # | Item | Deliverable | Write-set | cx/risk/eff |
|---|------|-------------|-----------|-------------|
| #11 | myriad-review reader | read-only `/myriad` backlog reader + `pdda.sh run` pointer | `utils/pdda/pdda-myriad.sh`, `test/pdda-myriad.sh`, `utils/pdda/pdda.sh` | 2/1/2 |
| agents-builder-skill | agents-builder skill | scenario-interview skill → `AGENTS-TEMP.md` | `skills/agents-builder/SKILL.md`, `skills/agents-builder/reference/camps.md`, `skills/agents-builder/scripts/build_agents_temp.py`, `test/agents-builder.sh` | 3/2/3 |

## Recommended waves

**Wave 1 — parallel (2 lanes ‖):** #11 ‖ agents-builder-skill
> No `depends_on` between p1/p2 — either order, or both in the same wave (disjoint write-sets).

## Execution contract

- Each lane fires as a worktree-isolated subagent, scoped via `ALLOW_PATHS` to its write-set (see
  each brief's "Your write lane").
- Per lane: land the change with a passing regression test (`test/pdda-myriad.sh`,
  `test/agents-builder.sh`); leave a status line in this doc.
- Reviewer for both lanes: `codex` (see `marathon/MARATHON-2026-07-07.yaml`).

## How to fire a lane

```bash
RELAY_TURN_TIMEOUT_S=1200 \
MARATHON_ROOT="$PWD" \
MARATHON_YAML_BIN="$PWD/.xyz/bin/marathon-yaml" \
TICK_BIN="$PWD/.xyz/bin/tick" \
MARATHON_DRIVE="$PWD/.xyz/relay-automation/marathon-drive.sh" \
bash .xyz/relay-automation/marathon.sh --plan marathon/MARATHON-2026-07-07.yaml \
     --builder agy [--dry-run]
```

Driving vendored-`.xyz`-against-parent-repo trips the harness cross-repo containment guard — see the
4-attempt dogfood in [PROJECT/2-WORKING/GH-10-SENTINEL.md](GH-10-SENTINEL.md); expect the same
friction. `marathon-yaml --dry-run` validates the plan cleanly.
