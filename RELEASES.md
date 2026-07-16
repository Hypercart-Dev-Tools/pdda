# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's `CHANGELOG.md` — lessons
learned belong there at ship time, not duplicated here). Contract lives in `PROJECT/PDDA.md` →
"RELEASES.md — release ledger". Add new fields only when a real need shows up; this intentionally
started smaller than the old per-file convention.

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