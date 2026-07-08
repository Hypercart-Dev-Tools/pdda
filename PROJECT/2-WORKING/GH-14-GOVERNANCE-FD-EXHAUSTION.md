---
title: "pdda-check-governance: fd exhaustion on stock macOS bash 3.2; crashed check silently reports pass"
status: Active
created: 2026-07-08
updated: 2026-07-08
owner: noel
gh_issue: 14
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/14
doc_type: bugfix
branch: main
effort: 2
complexity: 2
risk: 1
phases: 3
context_tags: [governance, bash-compat, silent-failure]
goal: >
  Fix the file-descriptor exhaustion in `pdda-check-governance`'s dead-reference scan
  (`utils/pdda/pdda.sh:684-697`) that crashes or truncates findings under stock macOS bash 3.2.57 (no
  Homebrew bash), and close the independent BUG-001b gap where a crashed check still lets the overall
  run report "all checks passed" — a "no win reported unverified" violation in the project's own terms.
related: [PROJECT/PDDA.md]
---

## Status

| What was just completed | What's next |
|---|---|
| Issue #14 triaged and promoted to `2-WORKING`; reporter's verification matrix (5 environments, bash 3.2/5.2, before/after patch) and one-line fix transcribed below. | Phase 1 — apply the verified one-line fix at `utils/pdda/pdda.sh:695`, then re-run the reporter's matrix locally. |

## Table of contents

- [Phase 1 — Fix the fd-exhaustion bug (pdda.sh:695)](#phase-1--fix-the-fd-exhaustion-bug-pddashor695)
- [Phase 2 — BUG-001b: surface check-level runtime failures](#phase-2--bug-001b-surface-check-level-runtime-failures)
- [Phase 3 — Verification](#phase-3--verification)

## Problem

`pdda-check-governance`'s dead-reference scan nests a per-line process substitution (`utils/pdda/pdda.sh:695`,
`done < <(_pdda_gov_extract_refs "$text")`) inside a middle loop that keeps its own process substitution open
for the whole file (line 696). Bash 3.2.57 — frozen since 2007, still the default `/bin/bash` on every stock
macOS install with no Homebrew bash — does not reap process-substitution file descriptors promptly, so fds
accumulate roughly 1-per-line until the process hits its limit.

**Blast radius:** any repo containing a few-hundred-line doc self-triggers this on stock macOS. `PDDA-INSTALL.md`
(shipped by the installer itself) is long enough, so **every fresh install self-triggers the bug** on a Mac with
no Homebrew bash.

**Severity compounder (BUG-001b):** the check fails silently. In the reporter's run #1, the fd wall hit mid-scan,
the check returned early having recorded only 2 of 34 real findings, and the aggregate `pdda.sh run` still
printed "all checks passed" / `errors=0`. Nothing signals the operator that the result is incomplete — this is
filed alongside the root bug because the silent-pass behavior is what makes the fd bug severe rather than a
minor compat nit.

### Reporter's verification matrix

All runs against the same target (fresh `EOS-daily-skill` clone, observe-mode install, pinned to `c8ce498`):

| # | Environment | Result | Governance findings |
|---|---|---|---|
| 1 | bash 3.2.57 (macOS), ulimit 256 (stock) | fd error wall mid-check; check silently incomplete; run reports "all checks passed" | 2 of 34 |
| 2 | bash 3.2.57 (macOS), ulimit 4096 | `zsh: trace trap` (SIGTRAP) — entire run dies, no summary | 2 of 34 |
| 3 | bash 5.2.21 (Linux), ulimit 1024 | completes normally | 34 of 34 (reference) |
| 4 | bash 3.2.57 (macOS), ulimit 256, **patched** | clean — no fd errors, no trap | **34 of 34** |
| 5 | bash 3.2.57 (macOS), ulimit 4096, **patched** | clean | **34 of 34** |

Row 2 matters: raising `ulimit` is **not** a workaround — it converts a semi-graceful degradation into a hard
crash. Only the loop restructure fixes it.

## Phase 1 — Fix the fd-exhaustion bug (pdda.sh:695)

Apply the reporter's verified one-line fix:

```bash
# before
done < <(_pdda_gov_extract_refs "$text")
# after
done <<< "$(_pdda_gov_extract_refs "$text")"
```

Command substitution closes its fd immediately on completion; the here-string preserves the parent-shell
`while` loop so the `pdda_record_finding` counters accumulate correctly across iterations (the likely reason
`< <(...)` was used in the first place). Here-strings are valid bash 3.2 syntax, so this needs no version gate.

**QA gate:**
- [ ] `utils/pdda/pdda.sh governance` runs clean under the repo's default shell with no fd/trap errors
- [ ] finding count matches the pre-fix bash-5.2 reference count (no regression in detection, only in survivability)
- [ ] diff stays narrowly scoped to the fd-exhaustion loop at `utils/pdda/pdda.sh:695` — no incidental
      refactor of the surrounding dead-reference scan

## Phase 2 — BUG-001b: surface check-level runtime failures

Independent of the fd fix: a nonzero exit / crash from any individual check function inside `pdda.sh run` must
be counted and surfaced in the run summary, not silently absorbed into "all checks passed". Add a
`checks-failed-to-run: N` line (or equivalent field) to the aggregate summary, distinct from `errors`/`warns`
finding counts, so an operator can tell "0 findings because it looked and found nothing" apart from "0 findings
because it crashed before looking."

**Scope note (from Codex consult review, adjudicated 2026-07-08):** `cmd_run` (`utils/pdda/pdda.sh:808-819`)
calls each check as a plain function (`"$fn"`), in-process — it only sees a failure if the function itself
returns nonzero. Two distinct failure shapes exist, and this phase only covers one of them:
- **soft degrade** — the check hits an internal error (e.g. a process substitution fails to open) but the
  surrounding loop treats it as EOF and the function still `return`s 0. This is the case a
  `checks-failed-to-run` field actually fixes: the check body must be tightened to detect this condition and
  return nonzero / record an explicit runtime-error finding, not just rely on summary-line formatting.
- **hard crash** — the check's fd exhaustion kills the whole `bash utils/pdda/pdda.sh` process outright
  (reproduced live in this repo during triage: `bash utils/pdda/pdda.sh governance` exited 134/SIGABRT under a
  raised `ulimit`, matching the reporter's row 2). No code inside `pdda.sh` can self-report after its own
  process has died — an external caller (cron job, CI step, pre-commit hook) must check `pdda.sh`'s own
  top-level exit code / signal, which is outside this phase's control surface. Phase 1's fix is what actually
  eliminates this case for `pdda-check-governance`; this phase is a general safety net for *other* checks that
  might soft-degrade the same way, not a guarantee against every hard crash.

**QA gate:**
- [ ] the check body itself (not just `cmd_run`'s summary formatting) converts a swallowed internal failure
      into a nonzero return / explicit runtime-error finding — verified with a synthetic soft-degrade case,
      not just the fd bug
- [ ] a check that exits nonzero or is killed mid-run is reflected in the `pdda.sh run` summary output
- [ ] a check that completes normally with zero findings still reports a clean summary (no false positives)
- [ ] behavior holds under both `observe` and `full` `PDDA_MODE` (the new signal is informational and must not
      change the gating semantics of `pdda.sh run` itself — that stays `PDDA_MODE`'s job)
- [ ] `PROJECT/PDDA.md`'s "Suggested output contract" section is updated to document the new
      `checks-failed-to-run` field in the same change (AGENTS.md #5 — keep the installer surface in lockstep)

## Phase 3 — Verification

Re-run the reporter's 5-environment matrix (or the closest reproducible subset available locally — at minimum
row 1's stock-macOS-bash-3.2 case, since that is the default shell on every fresh install) against the patched
`pdda.sh`, confirm parity with the bash-5.2 reference finding count, and record the result in `CHANGELOG.md`.

**QA gate:**
- [ ] patched stock-macOS-bash-3.2 run matches the bash-5.2 reference finding count (34/34 in the reporter's
      fixture, or the repo's own equivalent full count)
- [ ] `CHANGELOG.md` entry added citing issue #14 and the verification result
- [ ] issue #14 closed on GitHub once both phases are verified in this repo
