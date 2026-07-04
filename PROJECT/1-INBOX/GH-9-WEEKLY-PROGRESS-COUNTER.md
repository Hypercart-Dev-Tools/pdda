---
title: Weekly progress counter — open GH issues + closed tasks this week
status: Proposed (1-INBOX — not yet active)
created: 2026-07-03
owner: noel
gh_issue: 9
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/9
doc_type: project
effort: 3
complexity: 3
risk: 1
phases: 2
---

## Ask

Give maintainers a "light at the end of the tunnel" signal: a new deterministic `pdda.sh progress`
subcommand reporting:

1. **Current open GH issues** (repo-wide count).
2. **Closed Tasks this week** (Sunday–Saturday, current week so far).

## Why not `pdda-catchup.sh`

`utils/pdda/pdda-catchup.sh` is an opt-in LLM prose-recommendation tool with no persisted numeric
state — not a counter. `ROUTER.md` already says findings should be deterministic, not overridden by
prose, so this belongs next to `status-table`/`roadmap-coverage` in `pdda.sh`, not the LLM layer.

## Build on existing pieces

- `.pdda-gh-state.tsv` (written by `utils/pdda/pdda-gh-refresh.sh`) already caches issue number →
  OPEN/CLOSED. Currently only `issue-doc-sync` reads it; reuse it for the open-issue count.
- Docs move `PROJECT/2-WORKING/` → `PROJECT/3-COMPLETED/` on task completion, but nothing timestamps
  or counts that move weekly today.

## Acceptance criteria

- New `pdda.sh progress` subcommand, deterministic, no LLM dependency.
- Open-issue count read from the gh-state cache (refresh via `pdda.sh gh-refresh` if stale).
- "Closed this week" cross-checks **both** signals before counting a task, same posture as
  `issue-doc-sync`'s drift detection:
  - the issue's `CLOSED` state in the gh-state cache, and
  - the local `GH-*.md` doc having moved into `PROJECT/3-COMPLETED/` (git log timestamp on that path,
    or a `completed:` frontmatter date going forward).
  - Week window = Sunday–Saturday, current week.
  - Flag, don't silently drop, any mismatch (e.g. issue closed but doc still in `2-WORKING/`).
- Document the subcommand in `ROUTER.md`'s command rail and `PROJECT/PDDA.md`'s "Automation layers".

## Explicitly out of scope: "Marathons"

The original ask also named "closed Marathons this week." **"Marathon" is not a PDDA concept** — it's
a `tick`-native multi-agent run type (`marathon-plan`/`marathon-drive`) that lives entirely in the
`xyz-3-agents-swarm` repo, a separate codebase from this one. PDDA here has no data model for it, and
reaching directly into another repo's `.tick/` state is a deliberate cross-repo coupling decision
bigger than this issue.

If wanted later, the precedent to follow is `PROJECT/3-COMPLETED/PDDA-MULTI-DEVICE-STATUS-VIA-GITPULSE.md`
(piggyback git-pulse's existing sync rather than reaching into the other repo directly):
`xyz-3-agents-swarm` would publish its own weekly marathon-completion count through that same
git-pulse-carried projection channel, and `pdda.sh progress` would optionally read it if present,
fail-open. That half is its own issue, not bundled into this one.

Full discussion: [#9](https://github.com/Hypercart-Dev-Tools/pdda/issues/9)
