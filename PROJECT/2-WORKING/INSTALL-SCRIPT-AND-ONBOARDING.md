---
title: Root install.sh + operator onboarding
status: Active
created: 2026-06-25
updated: 2026-06-25
owner: noel
goal: >
  Ship a root install.sh that installs the PDDA surface into a foreign repo in a clean zero state,
  and improve README for operator onboarding — while this repo keeps dogfooding PDDA on itself.
branch: consolidate-utils-to-dispatcher
gh_issue: pending (gh auth re-login required; rename this doc to GH-<n>-… once the issue exists)
---

## Status

| What was just completed | What's next |
|---|---|
| Built root `install.sh` (copies the canonical-4 runtime + contract, seeds the `PROJECT/**` tree and blank `ROADMAP`/`CHANGELOG`/activity/`.pdda-mode`, `chmod`s, verifies with `pdda.sh run`); verified install + idempotent re-run + `--force` / `--with-startup-docs` / `--mode` against throwaway targets. Rewrote `README.md` for operator onboarding; updated `PDDA-INSTALL.md` + `ROUTER.md` in lockstep. | Re-auth `gh`, open the tracking issue, rename this doc to `GH-<n>-…`, then merge the branch. |

## Context

Issue-first SOP could not run as written: `gh` auth is down (invalid keyring token), so no GitHub
issue was opened yet. This doc is the in-repo execution record in the meantime; it carries
`gh_issue: pending` and must be renamed to the canonical `GH-<n>-…` form once the issue exists.

This repo intentionally keeps its own populated `ROADMAP.md` / `CHANGELOG.md` / `PROJECT/**` as a
live PDDA demo. The "zero state" reset applies only to the *target* repos `install.sh` provisions,
never to this source repo.

## Scope

- `install.sh` (repo root) — executable form of `utils/PDDA-INSTALL.md`.
  - Copies runtime: `utils/pdda.sh`, `utils/pdda-lib.sh`, `utils/pdda-doc-ready.sh`, `PROJECT/PDDA.md`.
  - Creates `PROJECT/{1-INBOX,2-WORKING,3-COMPLETED,4-MISC}` with `blank.md`.
  - Synthesizes blank seeds (never copied from here): `ROADMAP.md`, `CHANGELOG.md`,
    `PROJECT/PDDA-ACTIVITY.jsonl`, `.pdda-mode`.
  - Idempotent (create-only seeds; `--force` to overwrite); `--with-startup-docs`; `--mode`.
  - Runs `pdda.sh run` in the target as a post-install smoke test.
- `README.md` — operator-first onboarding (install path, day-to-day commands, modes).
- Lockstep doc updates: `utils/PDDA-INSTALL.md`, `ROUTER.md`.

## Phase 1 — install.sh + onboarding

Actions: build the script, rewrite README, update the manifest + router.

### QA gate

- [x] `bash -n install.sh` clean.
- [x] Fresh install into an empty git repo → `pdda.sh run` exits 0, all checks pass.
- [x] Re-run is idempotent: runtime refreshed, operator-edited `ROADMAP.md` content preserved.
- [x] `--with-startup-docs` installs `ROUTER.md` + `AGENTS.md`; `--mode light` writes `.pdda-mode`.
- [x] `install.sh` refuses to target the pdda source repo itself.
- [x] This repo's own `pdda.sh run` stays green with this doc + its roadmap pointer present.

## Phase 2 — issue-first reconciliation (blocked on gh)

Actions: `gh auth login`; open the tracking issue; rename this doc `GH-<n>-INSTALL-SCRIPT.md`,
carrying `gh_issue` forward; update the ROADMAP pointer; merge the branch.

### QA gate

- [ ] Issue exists and is linked from this doc's `gh_issue` + `source`.
- [ ] Doc renamed to `GH-<n>-…`; ROADMAP pointer updated to match.
