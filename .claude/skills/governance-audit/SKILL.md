---
name: governance-audit
description: Evaluate this repo's governance docs (ROUTER.md, AGENTS.md, GUIDING-PRINCIPLES.md, README.md, CLAUDE.md, PROJECT/PDDA.md, utils/pdda/PDDA-INSTALL.md) for inconsistencies and contradictions — dead cross-references, doc/code drift, and conflicting prose. Runs the deterministic `pdda.sh governance` check first, then reads the same doc set for semantic contradictions a regex can't catch. Use when asked to audit, review, or reconcile the repo's own operating docs, or when CLAUDE.md/AGENTS.md/ROUTER.md may have drifted apart.
---

# /governance-audit — find inconsistencies across the repo's own operating docs

Two-layer review, same split as `pdda.sh run` vs. `pdda-doc-ready.sh` (`PROJECT/PDDA.md` → "Automation
layers"): a deterministic pass for what a script can prove, then a reading pass for what only judgment
can catch. Report-only — this skill never edits a file itself.

## Doc set

The default governance set (skip any that don't exist in this repo):

- `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`
- `PROJECT/PDDA.md`, `utils/pdda/PDDA-INSTALL.md`

If the repo has no `utils/pdda/pdda.sh` (PDDA isn't installed here), skip straight to Step 2 with
whichever of the above docs exist — the doc set alone is still worth auditing.

## Steps

1. **Run the deterministic check.**

   ```bash
   utils/pdda/pdda.sh governance
   ```

   This catches four mechanical drift classes: dead `.md` cross-references, a governance doc that
   exists but `ROUTER.md` never points at, a shipped `pdda.sh` subcommand missing from `ROUTER.md`, and
   a `PDDA_*` env var documented but implemented nowhere. Report these findings as-is — do not
   re-judge or soften a finding this script already proved. Dead-reference and orphan-doc findings are
   `warn` by design (prose extraction is heuristic); subcommand and env-var drift are `error` because
   they come from parsing code, not prose — see `PROJECT/PDDA.md` § "I. `pdda.sh governance`" for why.

2. **Read every governance doc in the set that exists**, in full, in the same pass (small enough to
   hold in context together — that's the point: contradictions only show up when two docs are read
   side by side). Look for what the script structurally cannot check:
   - two docs stating a conflicting rule, threshold, or default for the same thing (e.g. a stale-day
     count, an enforcement mode, a required frontmatter field) — the disagreement itself is the finding,
     independent of which one is "right"
   - a doc claiming ownership of a topic ("the canonical place for X is Y") that conflicts with another
     doc's claim
   - a rule stated as current fact that the code or another doc's own account shows has since changed
     (compare against what you already know from Step 1 and from reading the actual scripts if unsure)
   - a duplicated rule ROUTER.md or AGENTS.md explicitly say belongs in exactly one place — check the
     other doc doesn't also re-specify it
   - stale claims — a doc asserting a file/mechanism exists or behaves a certain way when the repo
     shows otherwise (cross-check with a quick `ls`/`grep`, don't assume prose is current)

3. **Report as one list**, deterministic findings first, then semantic ones. For each: which doc(s),
   the line(s), what's inconsistent, and — for semantic findings only — a suggested resolution (which
   doc should change, or that a human needs to decide). Do not silently drop a Step 1 finding; if you
   think one is a false positive, say so explicitly and why, rather than omitting it.

## Keep it dumb

- Do not edit any file in this pass. If the user wants fixes applied after seeing the report, treat
  that as a separate, explicit follow-up — confirm which findings to act on first.
- Do not re-run or second-guess the deterministic check's verdicts; if a finding looks wrong, say so
  as part of the report, don't suppress it.
- Do not expand the doc set to every markdown file in the repo — `PROJECT/**` plan docs have their own
  contract and their own checks (`pdda.sh frontmatter`, `status-table`, `roadmap-coverage`, ...); this
  skill is scoped to the small set of docs that govern how an agent operates in the repo itself.
