---
title: Myriad — Week of 2026-07-06
status: Active (weekly myriad parking lot)
created: 2026-07-06
updated: 2026-08-03
owner: noelsaw
goal: >-
  Park non-critical follow-up items from end-of-day agent triage in one
  durable weekly backlog.
doc_type: backlog
roadmap_exempt: true
---

# Myriad — Week of 2026-07-06

## Status

| What was just completed | What's next |
|---|---|
| **Relocated into PDDA governance (2026-08-03).** This week file was written by `/myriad` into a repo-root `2-WORKING/` — the skill's pre-PDDA default — and was left there by the [2026-07-18 triage disposition](../1-INBOX/MARATHON-TRIAGE-2026-07-17.md) because the parking-lot data did not follow the skill out to `giant-brains-claude-skills`. Moved to `PROJECT/2-WORKING/` so the backlog is governed rather than stranded. The `/myriad` skill's `log_myriad.py` now resolves its parking lot PDDA-aware (PDDA repo → `PROJECT/2-WORKING/`, anything else → repo root), so this cannot recur here. | Work off the 6 open items below. They are a **parking lot, not a burndown** — `roadmap_exempt: true`, so no ROADMAP pointer is expected. Retire the file when every box is checked or reassigned to a GH issue. |

### 2026-07-06
- [ ] Wire up or delete the dead search/replace fallback in sentinel/apply.sh — the prompt only asks for FULL_FILE, so the SEARCH_REPLACE path is unreachable and untested.
- [ ] Tokenize the diff artifact path temp/sentinel-diff-<sha>.diff so same-sha concurrent apply runs cannot clobber each other.
- [ ] Add TOCTOU revalidation of the allowlist in sentinel/apply.sh — it is validated once, then the target is read/written later without a recheck.
- [ ] Clean up pre-existing working-doc hygiene errors flagged by pdda: BLANK.md (missing frontmatter/status) and AGENTS-BUILDER.md (missing status table + ROADMAP pointer).

### 2026-07-07
- [ ] Harden pdda-doc-ready.sh against prompt injection by wrapping the injected doc body in delimiters (e.g. <document_content>...) — pre-existing, general (not Quad-specific); flagged by the GH-12 P3+P4 consult.
- [ ] Latent trailing-slash ($TMPDIR) portability nit in test/pdda-publish-projection.sh — passes 17/17 in-repo; only the consult's throwaway-worktree env tripped the double-slash. Normalize SBOX via pwd if it ever bites CI.
