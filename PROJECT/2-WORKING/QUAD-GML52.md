Here is the proposal packaged into a complete design document. I've included the initial concept, the adversarial persona review to stress-test the idea, and the final technical implementation plan. 

You can copy the markdown below into a new file (e.g., `PROJECT/1-INBOX/quad-concepts-mode.md`) to bring it into your PDDA lifecycle.

***

# Proposal: "Quad Concepts" Mode

## 1. The Initial Concept

**Goal:** Provide an opt-in, system-wide mode that ensures every tracked PDDA document (`PROJECT/2-WORKING` and `PROJECT/3-COMPLETED`) opens with a highly scannable summary of its core ideas. 

**The Rule:** Immediately following the `## Status` table, a document must contain a `## Quad Concepts` section with exactly 1 to 4 bullet points. 

**Why?** When a human or a cold-start agent opens a doc, the `## Status` table tells them *where the work is*, but it doesn't tell them *what the work actually is*. A quick glance at 4 key concepts provides immediate mental scaffolding (e.g., "Ah, this is about token refresh, race conditions, and Redis locks") before diving into the dense execution details. 

**How it's enabled:** Similar to the `full` enforcement mode, it is set in `.pdda-mode` as `quad-concepts`. In this mode, PDDA operates in a blocking manner (like `full`), but adds the Quad Concepts deterministic check to the gate.

---

## 2. Adversarial Review Persona Pass

To ensure this feature doesn't disrupt PDDA's core utility, we need to view it through several adversarial lenses.

### Persona 1: The "Trivial Fix" Developer
**Critique:** *"I just want to fix a one-line typo in a working doc, but because it's in `2-WORKING`, PDDA is blocking my commit because I didn't add 4 bullet points to the top. This is bureaucratic garbage."*
**Mitigation:** The rule should be "up to 4" (meaning 1 to 4). If a doc is truly trivial, the developer can add a single bullet like `- Typo fix in auth flow`. Furthermore, PDDA's existing `roadmap_exempt: true` frontmatter escape hatch can be extended to `quad_exempt: true` for docs that are purely administrative or don't warrant conceptual scaffolding. 

### Persona 2: The Rigid Automation Agent
**Critique:** *"As an LLM trying to write these docs, how do I know where the Quad Concepts end and the actual plan begins? If I generate a concept that wraps to two lines, does your bash script break? What if I use `*` instead of `-` for bullets?"*
**Mitigation:** The deterministic check must be strictly scoped. It must look for the `## Quad Concepts` header and parse *only* consecutive lines starting with `- ` until it hits a blank line or the next `## ` header. Any deviation (wrong bullet character, missing blank line) results in a deterministic `error`, forcing the agent to correct the format before it can pass.

### Persona 3: The Context Drift Manager
**Critique:** *"When a doc moves from `2-WORKING` to `3-COMPLETED`, the key concepts might have changed during the build. Are we enforcing that these get updated? This creates a stale-memory risk."*
**Mitigation:** PDDA's philosophy is "honesty over perfection." The deterministic check only ensures the section *exists* and is *formatted correctly*. The opt-in LLM pass (`pdda-doc-ready.sh`) should be updated to emit a *warning* (never a block) if the Quad Concepts seem disconnected from the document's `## Lessons Learned` or final status. The human is responsible for updating them at closeout.

### Persona 4: The PDDA Architect
**Critique:** *"We already have `context_tags` as an optional frontmatter field. Why are we duplicating this in markdown? Isn't this scope creep?"*
**Mitigation:** `context_tags` are for database-style retrieval (e.g., "find all docs tagged `auth`"). Quad Concepts are for *human cognitive load reduction*—they are meant to be read in the first 5 seconds of opening a file. They serve different audiences (search vs. glance). They can coexist.

---

## 3. Technical Implementation Plan

To implement "Quad Concepts" cleanly within PDDA's existing architecture:

### A. Installer Updates (`install.sh`)
1. Update the `case "$MODE" in` validation to accept `quad-concepts`.
2. Update the `usage()` text:
   ```text
   --mode <m>             Initial .pdda-mode: observe (default) | light | full | quad-concepts.
   ```
3. Update the `MODE_BLURB` logic in `install.sh`:
   ```bash
   quad-concepts) MODE_BLURB="on rails + requires up to 4 key concepts at the top of every doc" ;;
   ```

### B. Deterministic Shell Check (`utils/pdda/pdda.sh` & `pdda-lib.sh`)
Add a new function `check_quad_concepts()` that triggers if `PDDA_MODE="quad-concepts"`.
*   **Scope:** Only run on files in `PROJECT/2-WORKING` and `PROJECT/3-COMPLETED`. (Skip `1-INBOX` and `4-MISC`).
*   **Skip logic:** If frontmatter contains `quad_exempt: true`, skip the check.
*   **Parsing logic:**
    1. Find `## Quad Concepts`.
    2. Ensure the next non-empty lines start with `- `.
    3. Count the bullets. If count is `0` or `> 4`, emit an `error`.
    4. If the section is missing entirely, emit an `error`.

### C. Seed Template Updates (`install.sh` seeds)
Update the blank seeds for `ROADMAP.md` and the `PROJECT/PDDA.md` contract to document the new section:
```markdown
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |

## Quad Concepts
<!-- List 1 to 4 key concepts for quick human/agent orientation. Delete this section if quad_exempt: true -->
- Concept 1
- Concept 2

## Context
...
```

### D. LLM Readiness Layer (`utils/pdda/pdda-doc-ready.sh`)
Add a rubric check specifically for `quad-concepts` mode:
*   *Warning:* "Quad Concepts are too vague (e.g., 'backend', 'bug'). Consider making them specific to the mechanics of this doc."
*   *Warning:* "Quad Concepts do not appear to match the final implementation described in the doc. Update them before closing."

### Summary
"Quad Concepts" bridges the gap between PDDA's strict structural enforcement and the need for immediate, human-readable context. By gating it as a mode, teams can opt into it when their docs become too dense to parse at a glance.