---
name: release-plan
description: Interview the operator to build up RELEASES.md — the forward-looking release ledger. Proposes a canonical version number by scanning CHANGELOG.md's [x.y.z] tags and the ledger's own highest entry, asks a short fixed question set (status/target date/codename/description), synthesizes a description from matching CHANGELOG.md history when backfilling an already-shipped version, previews the block, and appends on one confirmation. Sibling front-door to /release (which only publishes an existing entry to GitHub) — this one authors entries. Trigger on /release-plan, "help me fill out RELEASES.md", "add a release entry", or "backfill releases from the changelog".
---

# /release-plan — interview → RELEASES.md entry

Give it nothing, a version number, or "backfill". It interviews the operator with a short fixed
question set, proposes a canonical version by cross-referencing `CHANGELOG.md`, previews the block,
and appends it to `RELEASES.md` on one confirmation. It does not touch GitHub — for that, see the
`/release` skill (publish an existing entry) once an entry's `Status` is ready to ship.

This exists because `RELEASES.md` is only useful if it stays populated, and staring at a blank
ledger (or a wall of `Placeholder`/`TBD` entries) is friction most operators won't push through
unprompted. The interview does the bookkeeping (version math, CHANGELOG cross-referencing, format);
the operator only supplies judgment calls (status, target date, what a release is actually for).

## Usage

```
/release-plan            # ask what to work on, then the question set
/release-plan 1.3.0       # work on this specific Release: block (existing placeholder or new)
/release-plan backfill    # scan CHANGELOG.md for shipped versions missing from RELEASES.md
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
   - **`backfill`** → diff the `CHANGELOG.md` bracketed versions against `RELEASES.md`'s `Release:`
     values; list ones present in `CHANGELOG.md` but missing from `RELEASES.md`. Confirm the list with
     the operator before drafting (could be several blocks) — don't draft blocks the operator didn't
     ask for.
   - **Nothing given** → ask: new forward-looking entry, or fill in an existing `Placeholder`/`TBD`
     block? List the current placeholder entries as options if any exist.

3. **Propose a version number** (skip if step 2 already fixed one). Take the highest `CHANGELOG.md`
   bracketed version and the highest `Release:` value in `RELEASES.md`; propose the next value bumped
   at whichever level seems obvious from the operator's one-line description (patch/minor/major is a
   judgment call — state your reasoning, don't just assign it silently). The operator can override.

4. **Ask the fixed question set** (skip any already answered — e.g. a backfilled version's `Status`
   is always `Shipped`, its `Target Date` is blank, its `Description` is synthesized in step 5, not
   asked). Prefer `AskUserQuestion`:
   1. **Status** — free text, unvalidated (`Draft` / `Working` / `Placeholder` / `Shipped` are the
      common values seen so far; anything else is fine per the contract).
   2. **Target Date** — `YYYY-MM-DD`, or blank/`TBD` if not known yet.
   3. **Codename** — optional, `n/a` is fine.
   4. **Description** — one line. For a backfill, skip asking and synthesize in step 5 instead.

5. **Synthesize the description when backfilling.** For a `Shipped` version being backfilled, read
   that version's `## [x.y.z] - date` section in `CHANGELOG.md` and write a one-line summary in the
   same voice as the existing shipped entries (`1.0.0`/`1.1.0` in this repo are the pattern: what
   shipped + a `See CHANGELOG.md [x.y.z] - date.` pointer, not a duplicate of the full changelog
   prose). For a forward-looking entry, never fabricate a description from nothing — if the operator's
   answer in step 4 was empty, ask again rather than inventing scope.

6. **Preview the whole block (or blocks, if backfilling several), then get ONE confirmation.** Render
   the exact `Release:`/`Status:`/`Target Date:`/`Codename:`/`Description:`/`GH_URL:` text as it will
   be appended, in the flat `Label: value` format with a blank line between blocks. Nothing is written
   before the operator confirms.

7. **On confirm, write.** Append the block(s) to `RELEASES.md` (new file: write the standard header
   first, then the block; existing file: append after the last block, preserving the blank-line
   separator). Never reorder or edit blocks the operator didn't ask about.

8. **Verify + report.** Run `utils/pdda/pdda.sh releases` and report any findings (e.g. an invalid
   `Target Date`). Report what was written, and point the operator at `/release <version>` if an
   entry's `Status` is now ready to actually ship — publishing to GitHub is a separate step.

## Guardrails

- **Interview + synthesize, don't fabricate.** Version numbers, dates, and status are always either
  operator-supplied or clearly derived from `CHANGELOG.md` history — never invented. A backfilled
  description must trace to real `CHANGELOG.md` content for that version.
- **One preview, one confirmation.** Render every block that will be appended together; write nothing
  until the operator confirms once.
- **Never touches GitHub.** No `gh` calls here — that's `/release`'s job, after `Status` says the
  entry is ready.
- **Never edits existing blocks silently.** Filling in a `Placeholder` still previews the full
  replacement block before writing; backfill mode only adds blocks for versions missing entirely.
- **Repo-relative paths only** in any output — no absolute local paths.
- **Verify with the check that covers the file.** `pdda.sh releases` is warn-only by design (never
  blocks) — report its findings, don't treat a warn as a hard stop.
