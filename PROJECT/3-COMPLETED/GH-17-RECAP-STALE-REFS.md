---
gh_issue: 17
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/17
title: "PROJECT/PDDA.md dead-references RECAP.md and REAL-AGENT-OBSERVATIONS.md — neither file exists"
status: Fixed (pending PR merge)
created: 2026-07-08
doc_type: bugfix
context_tags: [governance, doc-accuracy]
related: [PROJECT/PDDA.md, GH-15-FRESH-INSTALL-GOVERNANCE-NOISE.md]
---

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

## Resolution (2026-07-08)

Checked the sibling `xyz-3-agents-swarm` repo (the project this standalone `pdda` repo's runtime and
contract docs were originally extracted from) — both `PROJECT/4-MISC/RECAP.md` and
`PROJECT/4-MISC/REAL-AGENT-OBSERVATIONS.md` genuinely exist there, as Trinity-spike-specific artifacts
(a session recap, a real-agent hand-test log). Confirmed via `git log -S"RECAP.md" -- PROJECT/PDDA.md`
that both mentions have been present since this repo's first commit — they were never real files here;
the prose was copy-pasted from the origin repo's context without being genericized for the standalone
PDDA product doc.

That resolves the "needs a human decision" question cleanly: this was never a "should this file exist"
case, it's a "this contract doc named another repo's project-specific files by mistake" case. Fixed by
genericizing the three affected passages in `PROJECT/PDDA.md`'s "CHANGELOG.md — end-of-iteration record"
section (and the GH-15 exemption-manifest note that referenced this as an open item) to describe the
*concept* (a superseded narrative log; an optional local compliance-observations doc) without naming
specific filenames that don't belong to the generic PDDA contract.

**Verified:** `pdda.sh governance` now reports `errors=0 warns=0` (previously 4 warns). Full `pdda.sh
run` clean. Shipped together with GH-18 on branch `fix/GH-17-GH-18`; PR open, not yet merged.
