---
title: Defacto Project Memory Layer Reframing
status: Active
created: 2026-07-06
updated: 2026-07-06
owner: Agent
goal: Implement quick wins to reframe PDDA as a project memory layer, providing AI agents with past context and lessons learned so they don't get stuck.
effort: 2
complexity: 2
risk: 1
phases: 2
---

# Defacto Project Memory Layer Reframing

This project implements quick wins to help PDDA act as a defacto project memory layer. Instead of just hygiene, PDDA will actively collect intelligence, lessons, and context to prevent agents from repeating mistakes.

## Status

| What was just completed | What's next |
|---|---|
| Phase 2 execution: Added automation nudges to LLM layer. | All phases complete. Ready for 3-COMPLETED movement. |

## Table of contents

- [Phase 0 - Technical Spike (LLM Script Analysis)](#phase-0---technical-spike-llm-script-analysis)
- [Phase 1 - Contract and Guideline Updates](#phase-1---contract-and-guideline-updates)
- [Phase 2 - Automation Nudges](#phase-2---automation-nudges)

## Phase 0 - Technical Spike (LLM Script Analysis)

Analyze the existing `utils/pdda/pdda-doc-ready.sh` to determine the best insertion point for the new `related` and `decisions/` nudges, and how we handle frontmatter array parsing (for `context_tags`).

- [x] Read `utils/pdda/pdda-doc-ready.sh` to understand how it checks frontmatter.
- [x] Determine if `context_tags` requires changes to the deterministic `pdda.sh` or just the LLM script.
- [x] Write findings back into this section.

### Phase 0 Findings
- **LLM Script (`pdda-doc-ready.sh`)**: The script uses a single `$RUBRIC` prompt passed to the LLM. It currently instructs the LLM to check for missing triage ratings. We can simply append an instruction to this rubric to also check if `related:` is empty on medium-large tasks, and if `risk` >= 4 lacks a `decisions/` reference.
- **Deterministic Script (`pdda.sh`)**: The `check_frontmatter` function in `pdda.sh` only validates specific keys it knows about. Unknown/optional fields are ignored. Therefore, adding `context_tags:` does NOT require modifying the deterministic shell script. We can just document it in `PROJECT/PDDA.md`.

### QA Checklist (Phase 0)

- [x] Findings are explicitly documented in this section.
- [x] Implementation plan for Phase 2 is validated or updated based on findings.

## Phase 1 - Contract and Guideline Updates

Update the canonical markdown documents to reframe PDDA's purpose and establish the new memory conventions.

- [x] Update `ROUTER.md` startup sequence: add a step instructing agents to search `PROJECT/3-COMPLETED/` and `CHANGELOG.md` for past context when exploring or blocked.
- [x] Update `PROJECT/PDDA.md`:
  - Add requirement for a `## Lessons Learned (For Future Agents)` section before moving a doc to `3-COMPLETED`.
  - Reframe the "Discovery & spike phases" section to explicitly mention "Memory Injection" (capturing quirks, gotchas, mechanics).
  - Add `context_tags` as an optional recommended frontmatter field.

### QA Checklist (Phase 1)

- [x] `ROUTER.md` contains the memory retrieval step.
- [x] `PROJECT/PDDA.md` documents the `Lessons Learned` requirement.
- [x] `PROJECT/PDDA.md` frames spikes as memory injection.
- [x] `utils/pdda/pdda.sh governance` passes without errors (ensuring no dead links were introduced).

## Phase 2 - Automation Nudges

Update the LLM readiness script to enforce or suggest memory linking.

- [x] Modify `utils/pdda/pdda-doc-ready.sh` to check if `related:` is empty on medium-large tasks, and emit a warning suggesting to link past context.
- [x] Modify `utils/pdda/pdda-doc-ready.sh` to warn if a doc with `risk: 4` or `5` does not link a `decisions/` record.

### QA Checklist (Phase 2)

- [x] `utils/pdda/pdda.sh doc-ready` successfully runs on this plan doc and correctly reports any memory-related warnings.
- [x] No deterministic tests or builds are blocked (LLM findings remain warn-capped).
