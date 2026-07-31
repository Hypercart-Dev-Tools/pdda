# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's `CHANGELOG.md` — lessons
learned belong there at ship time, not duplicated here). Contract lives in `PROJECT/PDDA.md` →
"RELEASES.md — release ledger". Add new fields only when a real need shows up; this intentionally
started smaller than the old per-file convention.

## This file is OPTIONAL — read this before proposing an edit to it

`RELEASES.md` is an **optional planning aid**. It is not a required artifact, not a checklist, and
not something to keep topped up. An empty file, a stale file, or no file at all are all valid
states — `pdda.sh releases` skips a missing file and never blocks.

**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
already shipped.** Do not treat a sparse file as an incomplete one. Edit it only when an operator
explicitly asks for release *planning*.

**What earns a block.** Being worth *planning toward* — a named arc with a theme, usually carrying a
target date and a milestone. If the only thing that can go in `Description:` is a restatement of what
changed, it belongs in `CHANGELOG.md` and nowhere else. The test is the theme, not the paperwork:
`Target Date:` and `Milestone:` are optional and their absence never disqualifies a block.

**`Iterations:` reserves a band of version numbers** (`Iterations: 1.5.0-1.5.4`) that are reserved
and deliberately not enumerated. Versions inside a band ship freely and are recorded in
`CHANGELOG.md` only; they never get a block here — except the band's own owner, whose `Release:` is
the band's low end and which keeps its block by construction. Any *other* version inside an existing
band is already accounted for, so a block for it is a duplicate — `pdda.sh releases` warns on exactly
that. If a band runs out, widen it; promote to the next release only if the work became a new arc.

Release: 1.0.0
Status: Shipped
Target Date:
Codename: Bronze
Description: Standalone baseline (shipped 2026-06-24) — consolidated utils/ into a single pdda.sh dispatcher (10 files -> 3) and reset the repo from its xyz-3-agents-swarm origin into a self-contained, installable baseline. See CHANGELOG.md [1.0.0] - 2026-06-24.
GH_URL:

Release: 1.1.0
Status: Shipped
Target Date:
Codename: Silver
Description: First zero-error, zero-warn baseline (shipped 2026-07-08) — GH-17 + GH-18 fixed, three inactive docs archived, pdda.sh run clean across all nine checks for the first time. See CHANGELOG.md [1.1.0] - 2026-07-08.
GH_URL:

Release: 1.2.0
Status: Draft
Target Date:
Codename: Gold
Description: Light weight Releases System scaffolded. First publicly announced version.
GH_URL: https://github.com/Hypercart-Dev-Tools/pdda/releases/tag/untagged-56f4458c604bdb0bd6b8

Release: 1.3.0
Status: Placeholder
Target Date: TBD
Codename: Titanium
Description: TBD

Release: 1.4.0
Status: Placeholder
Target Date: TBD
Codename: Platinum
Description: TBD