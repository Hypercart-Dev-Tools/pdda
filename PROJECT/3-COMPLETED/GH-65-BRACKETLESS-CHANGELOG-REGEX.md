---
title: "GH-65 (and GH-13) — changelog check misses bracketless `## x.y.z - YYYY-MM-DD` version headers"
status: "Completed (3-COMPLETED)"
created: 2026-09-14
updated: 2026-09-14
owner: Noel Saw
goal: Support bracketless version headings in check_changelog regex without false positive warnings.
gh_issue: 65
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/65
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-65 (and GH-13) — changelog check misses bracketless `## x.y.z - YYYY-MM-DD` version headers

## Status

| What was just completed | What's next |
|---|---|
| Updated `check_changelog()` in `utils/pdda/pdda.sh` using paired-bracket alternatives `((\[[^][[:space:]]+\]|[^][[:space:]]+)[[:space:]]*(-|–)[[:space:]]*)?` and terminal date extraction; added regression tests in `test/pdda-changelog.sh` (18 passed); updated `PROJECT/PDDA.md` specification; QA reviewed and approved via Codex relay consult. | Shipped in canonical repo; distributed via `pdda-sync.sh push`. |

## Acceptance

- `pdda-check-changelog` accepts:
  - Bracketed: `## [1.2.3] - YYYY-MM-DD`
  - Bracketless semver: `## 1.4.211 - YYYY-MM-DD`
  - Bracketless quad-version: `## 1.3.5.58 - YYYY-MM-DD`
  - Bare date: `## YYYY-MM-DD`
- Strict boundary behavior:
  - Rejects unbalanced opening brackets (e.g. `## [1.2.3 - DATE`)
  - Rejects unbalanced closing brackets (e.g. `## 1.2.3] - DATE`)
- Freshness calculation extracts terminal date accurately via `sed` pattern even if prefix contains a date-like token (e.g. `## 2025-01-01 - 2026-06-30`).
- All existing and new regression tests pass (18/18 in `test/pdda-changelog.sh`, full suite clean pass).

## Lessons Learned (For Future Agents)

- Consuming repos frequently diverge on changelog formatting conventions (bracketed semver vs bracketless semver vs quad-digit releases). A regex requiring literal `[` / `]` causes false positive `add-dated-entry` warnings that erode trust in the check.
- When relaxing bracket delimiters, use paired alternatives `(\[[^][[:space:]]+\]|[^][[:space:]]+)` rather than independent `\[?` and `\]?` to prevent accepting malformed one-sided bracket headings.
- Terminal date extraction must extract the date token associated with the entry date rather than naively running `grep -Eo | head -1` across the entire line, which could pick up a date-like prefix or version string.
