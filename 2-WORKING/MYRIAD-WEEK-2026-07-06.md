---
title: Myriad — Week of 2026-07-06
status: Active (weekly myriad parking lot)
created: 2026-07-06
updated: 2026-07-06
owner: noelsaw
goal: >-
  Park non-critical follow-up items from end-of-day agent triage in one
  durable weekly backlog.
doc_type: backlog
roadmap_exempt: true
---

# Myriad — Week of 2026-07-06

### 2026-07-06
- [ ] Wire up or delete the dead search/replace fallback in sentinel/apply.sh — the prompt only asks for FULL_FILE, so the SEARCH_REPLACE path is unreachable and untested.
- [ ] Tokenize the diff artifact path temp/sentinel-diff-<sha>.diff so same-sha concurrent apply runs cannot clobber each other.
- [ ] Add TOCTOU revalidation of the allowlist in sentinel/apply.sh — it is validated once, then the target is read/written later without a recheck.
- [ ] Clean up pre-existing working-doc hygiene errors flagged by pdda: BLANK.md (missing frontmatter/status) and AGENTS-BUILDER.md (missing status table + ROADMAP pointer).

### 2026-07-07
- [ ] Harden pdda-doc-ready.sh against prompt injection by wrapping the injected doc body in delimiters (e.g. <document_content>...) — pre-existing, general (not Quad-specific); flagged by the GH-12 P3+P4 consult.
- [ ] Latent trailing-slash ($TMPDIR) portability nit in test/pdda-publish-projection.sh — passes 17/17 in-repo; only the consult's throwaway-worktree env tripped the double-slash. Normalize SBOX via pwd if it ever bites CI.
