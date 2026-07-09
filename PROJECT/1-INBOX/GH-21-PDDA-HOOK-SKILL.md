---
gh_issue: 21
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/21
title: "Add SKILLS/PDDA-hook: opt-in SessionStart doc-governance reminder skill"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-08
doc_type: feedback
context_tags: [skills, hooks, governance, session-start]
related: [SKILLS/PDDA-hook/SKILL.md, SKILLS/PDDA-EOD/SKILL.md, SKILLS/myriad/SKILL.md, ROUTER.md]
---

## Problem

Following `ROUTER.md` -> `AGENTS.md` -> `PROJECT/PDDA.md` depends on the model choosing to (re-)read
them at session start and remembering to keep following them across a long session, after `/compact`,
or after `/clear`. That's a habit, not a guarantee — there was no bundled, self-serve way for an
operator to make their own sessions deterministically PDDA-compliant, either across every PDDA repo on
their machine or just the current one.

## Ask

Ship `SKILLS/PDDA-hook/` — a skill that lets an operator opt in to a `SessionStart` hook re-injecting a
short PDDA doc-governance reminder at every context boundary (`startup`/`resume`/`clear`/`compact`).

Acceptance criteria:

- Auto-scoping: the hook script checks the current repo root for `PROJECT/PDDA.md` and silently no-ops
  in any repo without one — one registration is safe across both PDDA and non-PDDA repos.
- Two install scopes, operator's choice: **global** (`~/.claude/hooks/` + `~/.claude/settings.json`,
  covers every PDDA repo on the machine) or **repo-local** (`.claude/hooks/` +
  `.claude/settings.local.json` inside one repo only).
- Never writes to a repo's *committed* `.claude/settings.json` — that's shared with every teammate who
  clones the repo, so a personal reminder hook must never be forced on people who didn't opt in.
- Propose-then-confirm, matching the `PDDA-EOD`/`myriad` skill pattern already in this repo.
- Ships its own canonical hook script under `SKILLS/PDDA-hook/scripts/`, mirroring `myriad`'s
  `scripts/log_myriad.py` convention, so the skill is self-contained when copied elsewhere.
- Explicitly notes in its own guardrails that global scope is a deliberate exception to this repo's
  existing norm — `pdda-edit-doc-hook.sh`/`pdda-stop-doc-health.sh` are wired repo-local, and PDDA's own
  planning docs otherwise guard against writing to `~/.claude` at all.

## Status

Implemented directly (skill file, canonical script, `README.md` bundled-skills entry) in the same
session as capture; filed per the issue-first SOP for record-keeping, not as queued/unstarted work.
