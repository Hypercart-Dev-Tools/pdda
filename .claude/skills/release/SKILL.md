---
name: release
description: Turn a PROJECT/releases/RELEASE-<tag>.md doc into a published GitHub Release. Reads all linked marathon plan docs and closed issue docs, synthesizes the GitHub Release body from their Lessons Learned and Quad Concepts sections, previews the draft, then calls `gh release create <tag>` and writes gh_release_url back into the RELEASE-*.md doc. Trigger on /release <tag-or-path>, "publish this release", or "create GitHub release for <tag>".
---

# /release — release doc → published GitHub Release

Give it a release tag (e.g. `v1.2.0`) or the path to a `PROJECT/releases/RELEASE-*.md` doc. It runs
the release-gate checks, synthesizes a GitHub Release body from the linked marathon and issue docs,
previews everything, and — on one confirmation — publishes the GitHub Release and writes
`gh_release_url` back into the doc.

This is the **publish** front-door for the release lifecycle. It does not create the release doc (use
the `RELEASE-<tag>.md` doc convention in `PROJECT/PDDA.md` for that). It does not move marathon docs
to `3-COMPLETED` (that is a separate step).

## Usage

```
/release v1.2.0                              # find and publish the matching RELEASE-v1.2.0.md
/release PROJECT/releases/RELEASE-v1.2.0.md # explicit path
/release                                     # ask for the tag, then proceed
```

## Steps

0. **Detect PDDA + tools (preflight).**
   - **PDDA repo?** Check for `utils/pdda/pdda.sh` at the repo root. If absent → say so and stop.
   - **Tools?** `gh` (auth'd) is required. If a `gh` call fails, retry **unsandboxed** first before
     concluding it is broken. Confirm `gh auth status` succeeds before proceeding.

1. **Locate the release doc.** From the given tag or path, find the matching
   `PROJECT/releases/RELEASE-<tag>.md`. Error if it doesn't exist or has `status: Published`
   (already published; nothing to do).

2. **Run `pdda.sh release-readiness`** to surface any blocking findings before attempting to
   publish. Report findings to the operator. If error-level findings exist in the current PDDA mode,
   ask the operator to confirm they want to proceed anyway (never auto-skip deterministic errors).

3. **Synthesize the GitHub Release body.** For each marathon doc listed under `marathons:`:
   - Read the doc and extract the `## Lessons Learned` section (if present).
   - Extract `## Quad Concepts` bullets (if present).
   - Compose a brief "what changed" narrative per marathon.
   For each issue listed under `issues_closed:`, add a "Fixes #<n>" reference.
   Combine into a release body: `## What's in this release` (from the doc's own section first, then
   marathon summaries), `## Lessons Learned`, `## Issues closed`. Keep it factual — never invent
   content that isn't in the source docs.

4. **Preview the whole release as one bundle, then get ONE confirmation.** Render together:
   - The `gh release create` command that would be run (tag, title, body)
   - The synthesized release body (full markdown preview)
   - The `gh_release_url` write-back that will happen on confirm
   Nothing is published before the operator confirms.

5. **On confirm, execute in order:**
   - `gh release create <tag> --title "<title>" --notes "<body>"` → capture the returned URL.
   - Update `gh_release_url` in the `RELEASE-<tag>.md` frontmatter with the returned URL.
   - Update `status: Published` and `updated: <today>` in the frontmatter.
   - Remove the release's ROADMAP.md pointer from the active ledger (same convention as completing
     a project doc — the Published release is no longer "in flight").

6. **Report + verify** with `utils/pdda/pdda.sh release-readiness` (should now pass cleanly with
   `gh_release_url` populated and `status: Published` excluding it from RC checks).
   Also run `utils/pdda/pdda.sh roadmap-coverage` (confirms the pointer is no longer required).
   Report the release URL and the updated doc path.

## Guardrails

- **One preview, one confirmation.** Render the `gh release create` command + full body together and
  publish nothing until the operator confirms once.
- **Outward-facing steps confirm first.** A GitHub Release is public and durable (`AGENTS.md` #2/#3).
- **Don't move marathon docs.** This skill publishes the release; verifying that marathons are in
  `3-COMPLETED` is the operator's job before calling `/release` (or acknowledge the warning and
  proceed anyway at their discretion).
- **Never invent release notes.** Synthesize from the actual linked docs. If source docs have no
  `## Lessons Learned` section, note the gap but don't fabricate content.
- **Repo-relative paths only** in doc edits — no absolute local paths.
- **If `gh release create` fails**, report the error verbatim and stop. Do not write `gh_release_url`
  until the create succeeds.
