---
name: release-plan
description: Interview the operator to plan a major release in RELEASES.md — the optional forward-looking release ledger. Proposes a canonical version number by scanning CHANGELOG.md's [x.y.z] tags and the ledger's own highest entry, asks a short fixed question set (status/iterations band/target date/codename/milestone/description), previews the block, and appends on one confirmation. Also supports operator-invoked `anchor` and `backfill` modes for representing already-shipped arcs. Sibling front-door to /release (which only publishes an existing entry to GitHub) — this one authors entries. OPERATOR-TRIGGERED ONLY — never offer it unprompted. Trigger on /release-plan, "help me plan the next release", "add a release entry", or "backfill releases from the changelog".
---

# /release-plan — interview → RELEASES.md entry

Give it nothing or a version number. It interviews the operator with a short fixed question set,
proposes a canonical version by cross-referencing `CHANGELOG.md`, previews the block, and appends it
to `RELEASES.md` on one confirmation. It does not touch GitHub — for that, see the `/release` skill
(publish an existing entry) once an entry's `Status` is ready to ship.

This exists to remove *bookkeeping* friction from release planning an operator has already decided to
do — version math, CHANGELOG cross-referencing, format. It does **not** exist to keep `RELEASES.md`
populated.

## Do not offer this skill unprompted

`RELEASES.md` is an optional planning aid, not a checklist (contract: `PROJECT/PDDA.md` →
"RELEASES.md — release ledger"). A sparse, stale, or absent ledger is a valid state, and
`pdda.sh releases` skips a missing file and never blocks.

So: **run this only when an operator explicitly asks for release planning.** Never suggest it after a
release ships, never to "bring the ledger up to date", and never because the file looks empty. An
empty ledger is not a prompt. The reason this warning is here rather than assumed is that the drift
it prevents arrives one individually-reasonable offer at a time, and the aggregate is a second
hand-maintained history that disagrees with `CHANGELOG.md`.

## Usage

```
/release-plan            # ask what to work on, then the question set
/release-plan 1.3.0       # work on this specific Release: block (existing placeholder or new)
/release-plan anchor 1.0.0 [1.1.0 ...]   # anchor already-shipped major arcs the operator names
/release-plan backfill    # operator-only: list shipped versions with no block, for the operator to pick from
```

## Steps

0. **Detect PDDA (preflight).** Check for `utils/pdda/pdda.sh` at the repo root. `RELEASES.md` is a
   PDDA convention (contract lives in `PROJECT/PDDA.md` → "RELEASES.md — release ledger") — if PDDA
   isn't installed in this repo, say so and stop; there's no fallback format to write instead (unlike
   `/idea`, which has a plain-doc fallback).

1. **Read state.** Read `RELEASES.md` (note if it's missing — offer to seed it with the standard
   header from `install.sh`'s `seed_file "RELEASES.md"` block before continuing) and `CHANGELOG.md`.
   From `CHANGELOG.md`, collect any `## [x.y.z] - YYYY-MM-DD` bracketed entries (the canonical-version
   convention already in use — see `check_changelog`); plain `## YYYY-MM-DD` entries have no version
   tag and are only useful as context, not a version source.

2. **Pick the target mode:**
   - **A specific version was given** (`/release-plan 1.3.0`) → find that `Release:` block in
     `RELEASES.md`. If it exists, this is a fill-in/update pass. If it doesn't, this is a new entry at
     that version.
   - **`anchor <version> [...]`** → the operator has named specific already-shipped versions they
     want represented as historical anchors (usually only when first adopting the ledger). Draft a
     block for **exactly the versions named** and no others.
   - **`backfill`** → the operator has explicitly asked to see what's shippable-but-unblocked. Diff
     the `CHANGELOG.md` bracketed versions against `RELEASES.md`'s `Release:` values and present the
     result **as a menu, not a to-do list** — the operator picks; you draft only what they pick, and
     drafting nothing is a normal outcome. Exclude any version already covered by an `Iterations:`
     band (it is accounted for by definition), and say so rather than listing it. Apply step 2a to
     each pick.

     Two rules make this safe rather than a pre-changelog generator: **never call these versions
     "missing"** — a shipped version absent from this file is correctly recorded in `CHANGELOG.md` and
     nowhere else — and **never run this mode unprompted**, including as a follow-up suggestion after
     some other `/release-plan` invocation. It runs when the operator types `backfill`, and not
     otherwise.
   - **Nothing given** → ask: new forward-looking entry, or fill in an existing `Placeholder`/`TBD`
     block? List the current placeholder entries as options if any exist.

2a. **Apply the admission rule before drafting anything.** A block earns its place by being worth
   *planning toward* — a named arc with a theme, a target date, and a milestone. Two hard stops:
   - If the only thing that can go in `Description:` is a restatement of what changed, **say so and
     stop.** It belongs in `CHANGELOG.md` and nowhere else. Do not draft the block anyway.
   - If the proposed version falls inside an existing block's `Iterations:` band, it is **already
     accounted for** — that is what the band means. Say which release reserves it and stop; do not
     add a block. (`pdda.sh releases` warns on this too, but the skill should never create the
     finding in the first place.)

3. **Propose a version number** (skip if step 2 already fixed one). Take the highest `CHANGELOG.md`
   bracketed version and the highest `Release:` value in `RELEASES.md`; propose the next value bumped
   at whichever level seems obvious from the operator's one-line description (patch/minor/major is a
   judgment call — state your reasoning, don't just assign it silently). The operator can override.

4. **Ask the fixed question set** (skip any already answered — e.g. an anchored version's `Status`
   is always `Shipped`, its `Target Date` is blank, its `Description` is synthesized in step 5, not
   asked). Prefer `AskUserQuestion`:
   1. **Status** — free text, unvalidated (`Draft` / `Working` / `Placeholder` / `Shipped` are the
      common values seen so far; anything else is fine per the contract).
   2. **Iterations** — the band of version numbers this release reserves, `<lo>-<hi>` (e.g.
      `1.3.0-1.3.4`). Offer it, don't require it; blank means no band. Explain what it buys in one
      line: versions inside the band ship freely into `CHANGELOG.md` and never get their own block
      here, so "where does 1.3.2 go?" has a written answer instead of becoming a new row.
   3. **Target Date** — `YYYY-MM-DD`, or blank/`TBD` if not known yet.
   4. **Codename** — optional, `n/a` is fine.
   5. **Milestone** — the GitHub milestone *title* this release's issues are filed under, if one
      exists. Optional and never nudged; it is a pointer so scope can be queried
      (`gh issue list --milestone "<title>"`) rather than listed here.
   6. **Description** — one line. For an anchor, skip asking and synthesize in step 5 instead.

5. **Synthesize the description when anchoring.** For a `Shipped` version being anchored, read that
   version's `## [x.y.z] - date` section in `CHANGELOG.md` and write a one-line summary in the same
   voice as the existing shipped entries (`1.0.0`/`1.1.0` in this repo are the pattern: what shipped
   + a `See CHANGELOG.md [x.y.z] - date.` pointer, not a duplicate of the full changelog prose). For
   a forward-looking entry, never fabricate a description from nothing — if the operator's answer in
   step 4 was empty, ask again rather than inventing scope.

6. **Preview the whole block (or blocks, if anchoring several), then get ONE confirmation.** Render
   the exact `Release:`/`Iterations:`/`Status:`/`Target Date:`/`Codename:`/`Milestone:`/
   `Description:`/`GH_URL:` text as it will be appended, in the flat `Label: value` format with a
   blank line between blocks — omitting any field left blank. Nothing is written before the operator
   confirms.

7. **On confirm, write.** Append the block(s) to `RELEASES.md` (new file: write the standard header
   first, then the block; existing file: append after the last block, preserving the blank-line
   separator). Never reorder or edit blocks the operator didn't ask about.

8. **Verify + report.** Run `utils/pdda/pdda.sh releases` and report any findings (e.g. an invalid
   `Target Date`). Report what was written, and point the operator at `/release <version>` if an
   entry's `Status` is now ready to actually ship — publishing to GitHub is a separate step.

## Guardrails

- **Operator-triggered only.** Never offer this skill unprompted, never after a release ships, never
  because the ledger looks sparse. See "Do not offer this skill unprompted" above — this is the one
  guardrail that, if broken, quietly converts the file into a pre-`CHANGELOG.md`.
- **Decline blocks that don't earn their place.** The admission rule (step 2a) is a stop, not a
  preference. A version that only restates what changed, or that sits inside an existing
  `Iterations:` band, gets an explanation and no block.
- **Interview + synthesize, don't fabricate.** Version numbers, dates, and status are always either
  operator-supplied or clearly derived from `CHANGELOG.md` history — never invented. An anchored
  description must trace to real `CHANGELOG.md` content for that version.
- **One preview, one confirmation.** Render every block that will be appended together; write nothing
  until the operator confirms once.
- **Never touches GitHub.** No `gh` calls here — that's `/release`'s job, after `Status` says the
  entry is ready.
- **Never edits existing blocks silently.** Filling in a `Placeholder` still previews the full
  replacement block before writing; `anchor` only adds blocks for versions the operator named, and
  `backfill` only for versions the operator picked off the menu.
- **Repo-relative paths only** in any output — no absolute local paths.
- **Verify with the check that covers the file.** `pdda.sh releases` is warn-only by design (never
  blocks) — report its findings, don't treat a warn as a hard stop.
