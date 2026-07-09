---
gh_issue: 17
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/17
title: "PROJECT/PDDA.md dead-references RECAP.md and REAL-AGENT-OBSERVATIONS.md — neither file exists"
status: Completed — both conventions confirmed retired; prose corrected, 4 dead-ref warns cleared
created: 2026-07-08
updated: 2026-07-08
owner: noel
doc_type: bugfix
context_tags: [governance, doc-accuracy]
related: [PROJECT/PDDA.md, GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md]
goal: >
  Make `PROJECT/PDDA.md`'s CHANGELOG section describe reality: stop claiming two retired conventions
  (RECAP, REAL-AGENT-OBSERVATIONS) are live files, and clear the 4 dead-reference warns those claims
  raise on every `pdda.sh run`.
---

## Status

| What was just completed | What's next |
|---|---|
| Human decision obtained: **both conventions are retired.** `PROJECT/PDDA.md` prose rewritten so neither is backtick-wrapped as a live `X.md` reference, and `CHANGELOG.md` is named as the successor for run-specific compliance findings (previously an orphaned destination). Verified: governance dead-ref warns 4 → 0. | Nothing. Close issue #17. |

## Problem

`PROJECT/PDDA.md`'s "CHANGELOG.md — end-of-iteration record" section makes two claims that don't match
reality:

- "It replaces `RECAP.md` (retired → `PROJECT/4-MISC/`)" — `RECAP.md` does not exist in
  `PROJECT/4-MISC/`, or anywhere else in the repo.
- "`REAL-AGENT-OBSERVATIONS.md` still holds run-specific compliance findings" — this file doesn't exist
  anywhere in the repo either.

Found during GH-15 remediation (2026-07-08); GH-15's exemption-manifest fix deliberately left these
flagged rather than exempting them, since this is a different root cause (a doc claiming a currently-real
artifact vs. GH-15's "installer deliberately omits a real HQ file").

## Impact

Triggers 4 `pdda-check-governance` dead-reference `warn` findings on every `pdda.sh run` in this repo
(currently `PROJECT/PDDA.md` lines ~669, 670, 688, 696).

## Needs a human decision before fixing

- Was `REAL-AGENT-OBSERVATIONS.md` actually retired too (same as `RECAP.md`), or does it still need to
  exist as a real file agents should be writing compliance findings to?
- If both are genuinely retired, reword the prose to describe them as historical facts without
  backtick-wrapping them as `X.md` (the dead-reference check reads that as a live cross-reference
  regardless of surrounding context — this is itself a lesson learned from GH-15, see that doc's
  "Lessons Learned" section).

## Fix size

Small — a ~2-4 line prose correction in `PROJECT/PDDA.md` once intent is confirmed. Falls under the
issue-first SOP's trivial-edit floor size-wise; tracked here because it needs a decision first, not just
a mechanical fix.

## Decision (2026-07-08)

**Both conventions are retired.** Neither file should be recreated. Confirmed by the maintainer, and
corroborated by `git log --all` — neither path has ever existed in this repo's history, so the claims
were aspirational text carried over from the upstream repo PDDA was extracted from, not a record of
files that were later deleted.

## Resolution (2026-07-08)

Three prose edits in `PROJECT/PDDA.md`'s "CHANGELOG.md — end-of-iteration record" section, all of them
dropping the backticked filename form the dead-reference check reads as a live cross-reference:

1. `It replaces `RECAP.md` (retired → `PROJECT/4-MISC/`)` → "It supersedes the retired RECAP
   convention" (the parenthetical was doubly wrong: the file is not in `4-MISC` either).
2. "This is the provenance guarantee `RECAP.md` used to carry" → "…the retired RECAP convention used
   to carry."
3. "`REAL-AGENT-OBSERVATIONS.md` still holds run-specific compliance findings" — the load-bearing one.
   Deleting the sentence outright would have left compliance findings with **no destination**, so the
   role was explicitly reassigned to `CHANGELOG.md` rather than silently dropped.

**Verified:** `utils/pdda/pdda.sh governance` → dead-reference `warns=4` before, `warns=0` after.

## Lessons Learned (For Future Agents)

- **A retired convention and a deleted file are not the same thing.** The instinct here was to hunt for
  where `RECAP.md` "went." It never existed. When a governance doc references a file with no git
  history, suspect inherited text from an upstream repo, not a deletion.
- The dead-reference check is **purely lexical**: any `` `Something.md` `` in a governance doc is a
  live reference, regardless of whether the surrounding prose says "retired," "former," or "deleted."
  To describe a retired artifact, name it *without* the backticks and the `.md` suffix. (GH-15 learned
  this same lesson from the other direction and chose to exempt rather than reword.)
- Removing a dangling reference can silently orphan a *responsibility*. Claim #3 pointed compliance
  findings at a nonexistent file; deleting the sentence would have made the contract quietly
  incomplete. Check what a dead reference was *load-bearing for* before cutting it.
