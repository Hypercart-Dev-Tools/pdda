---
name: pdda-hook
description: Opt in to a deterministic SessionStart reminder that re-anchors PDDA doc-governance rules (ROUTER.md -> AGENTS.md -> PROJECT/PDDA.md) at every context boundary, instead of relying on the model to remember them from a single read. Optionally, and only when asked, also install a default-off PreToolUse gate that refuses edits to governed docs when the session never opened ROUTER.md. Use when the operator wants their own sessions to be more reliably PDDA-compliant across one repo or every PDDA repo on their machine, says things like "set up the PDDA hook", "make sure I always follow ROUTER.md", or invokes /pdda-hook. Installs nothing without confirmation and never edits a repo's committed .claude/settings.json.
---

# /pdda-hook — opt in to the PDDA doc-governance reminder

`AGENTS.md`/`ROUTER.md` compliance today depends on the model choosing to (re-)read them — across a
long session, after `/compact`, or after `/clear`, that's a habit, not a guarantee. This skill installs
a `SessionStart` hook that deterministically re-injects a short PDDA reminder at every point a session's
context actually resets (`startup`, `resume`, `clear`, `compact`), so compliance doesn't depend on the
model remembering.

The hook auto-scopes itself at runtime: it checks the current repo root for `PROJECT/PDDA.md` and
no-ops silently if that file isn't there. One registration is safe to leave in place across both PDDA
and non-PDDA repos.

## Guardrails

- **Personal, opt-in, propose-then-confirm.** Nothing is written until the operator explicitly says yes
  to both the scope and the exact file diff.
- **Never edit a repo's committed `.claude/settings.json`.** That file is shared with every teammate who
  clones the repo — writing a personal reminder hook into it would force this on people who never opted
  in. Only ever write to the operator's own `~/.claude/settings.json` (global scope) or a repo's
  `.claude/settings.local.json` (repo-local scope).
  - `.claude/settings.local.json` is untracked by Claude Code convention, but that's only a guarantee if
    something actually ignores it. Before writing repo-local, run `git check-ignore -q
    .claude/settings.local.json`. If it's already ignored (via the repo's own `.gitignore` or the
    operator's global `~/.config/git/ignore`), proceed. If it is **not** ignored by anything, say so and
    ask whether to add a `.claude/settings.local.json` line to the repo's `.gitignore` before writing —
    don't assume it's covered and risk a personal hook registration landing in a commit.
- **Global scope is a deliberate exception to this repo's own norm**, not an oversight: PDDA's other
  hooks (`utils/pdda/pdda-edit-doc-hook.sh`, `utils/pdda/pdda-stop-doc-health.sh`) are wired repo-local
  in `.claude/settings.json` and PDDA's own docs guard against writing to `~/.claude` at all. This skill
  breaks that norm on purpose, because "remember to open ROUTER.md" is a cross-repo operator habit, not
  a per-repo lint rule — but it must stay confined to the operator's own machine config, never a
  committed file, and the skill should say so plainly before writing anything.
- **Dedup before writing.** If a hook already targets `SessionStart` with the same matcher in the target
  settings file, show the existing entry and ask whether to keep it, skip, or add alongside — never
  silently duplicate.
- **Copy the canonical script, don't re-author it inline.** The sources of truth are
  `<skill-dir>/scripts/pdda-doc-governance-reminder.sh` and, for the optional gate,
  `<skill-dir>/scripts/pdda-router-read-gate.sh` (`<skill-dir>` = the absolute directory this `SKILL.md`
  was loaded from). Copy verbatim to the resolved target path; don't hand-type a fresh copy that can
  drift from the source.
- **The gate is not part of the default install.** It is `PreToolUse`, it refuses tool calls, and it is
  the only thing here that acts rather than reminds. Offer it only when asked. See "Optional: the
  router-read gate".

## Steps

1. **Ask scope.** Two options:
   - **Global (recommended for an operator who works in several PDDA repos)** — script goes to
     `~/.claude/hooks/pdda-doc-governance-reminder.sh`, registered once in `~/.claude/settings.json`.
     Because the script auto-detects `PROJECT/PDDA.md`, this single registration covers every PDDA repo
     on the machine without per-repo setup, and never touches anything inside any repo's working tree.
   - **Repo-local (this repo only)** — script goes to `.claude/hooks/pdda-doc-governance-reminder.sh`
     inside the current repo, registered in that repo's `.claude/settings.local.json` (not
     `settings.json` — see Guardrails). Choose this if the operator wants the reminder scoped to one
     repo, or doesn't want a standing global hook.

2. **Resolve `<skill-dir>`** — the directory this `SKILL.md` was loaded from — and confirm
   `<skill-dir>/scripts/pdda-doc-governance-reminder.sh` exists.

3. **Check for an existing registration** in the target settings file (`SessionStart` hooks whose
   `command` already references a PDDA reminder script, under any of the `startup`/`resume`/`clear`/
   `compact` matchers). If found, ask keep / skip / add-alongside before doing anything else.

4. **Copy the script** to the resolved target path (`~/.claude/hooks/...` or
   `<repo>/.claude/hooks/...`), creating the parent directory if needed, then `chmod +x` it.

5. **Pipe-test both branches** before touching any settings file:
   ```bash
   # inside a PDDA repo (has PROJECT/PDDA.md) — should print the reminder
   <target-script-path>
   # outside any PDDA repo — should print nothing, exit 0
   cd /tmp && <target-script-path>; echo "exit=$?"
   ```

6. **Show the exact settings-file diff** — four new `SessionStart` hook entries (matchers `startup`,
   `resume`, `clear`, `compact`, each pointing at the copied script) — merged into any existing `hooks`
   block. Never replace the file wholesale; preserve every existing key. Apply only after the operator
   confirms.

7. **Validate** with `jq -e '.hooks.SessionStart[] | select(.matcher == "compact") | .hooks[] | select(.command | contains("pdda-doc-governance")) | .command' <target-settings-file>` and `jq empty <target-settings-file>` for overall syntax.

8. **Report the activation caveat.** A settings file edited mid-session won't be picked up by the
   currently running session — the operator needs to run `/hooks` (reloads config) once, or start a
   fresh session, before the hook fires.

## Optional: the router-read gate (`PreToolUse`, off by default)

Do not offer this unprompted. Install it only if the operator asks for enforcement rather than a
reminder — "make it actually stop me", "I keep skipping ROUTER.md".

Reminder directive 1 is the only directive that is both expensive and unverifiable; every other one
names a command whose output proves it ran. That asymmetry is why agents drop it. This gate makes it
verifiable: `<skill-dir>/scripts/pdda-router-read-gate.sh`, wired to `PreToolUse` with matcher
`Write|Edit`, refuses an edit to `PROJECT/**`, `ROADMAP.md`, or `CHANGELOG.md` when nothing in the
session's transcript shows `ROUTER.md` being read or `/pdda` being invoked.

**Two independent switches, both off.** Registering the hook does nothing on its own — the gate also
requires a `.pdda-router-gate` file at the repo root (or `PDDA_ROUTER_GATE=1`). `PDDA_ROUTER_GATE=0`
always wins, so a single command can bypass it without deleting the lever. Same convention as
`.pdda-quad` / `PDDA_QUAD`. A repo without `PROJECT/PDDA.md` is never gated, so one global registration
stays safe everywhere.

**It fails open, on purpose.** No `jq`, no readable transcript, an unparseable transcript, a payload it
does not recognize — every one of those allows the write and says on stderr that it could not evaluate.
The gate blocks only when it positively established that the router went unread. This is PDDA's own
recurring bug (GH-23, GH-27, BUG-001b: *a check that could not run must not report success*) applied to
the one component that acts instead of recommending. A gate that blocks on a guess would be the first
thing anyone turns off, and they would be right to.

Install steps mirror the ones above, with the same guardrails: copy the script, **pipe-test it first**,
show the exact diff, and write only to `~/.claude/settings.json` or an ignored
`.claude/settings.local.json` — **never a repo's committed `.claude/settings.json`**. Then tell the
operator the gate is still inert until they create `.pdda-router-gate`, and show them the one-line
bypass. Pipe-test with a payload naming a governed file:

```bash
printf '{"tool_name":"Edit","tool_input":{"file_path":"'"$PWD"'/ROADMAP.md"},"transcript_path":"/nonexistent","cwd":"'"$PWD"'"}' \
  | <target-script-path>; echo "exit=$?"   # expect exit=0 and a "could not evaluate" line: fail-open
```

## Operating stance

- If the operator declines both scopes or the diff, leave the tree untouched and say so — don't retry
  with a different scope unasked.
- If `<skill-dir>/scripts/pdda-doc-governance-reminder.sh` is missing (this skill folder was copied
  incompletely), say so and stop rather than reconstructing the script from memory.
- This skill adds a `SessionStart` hook entry by default, and — **only when the operator explicitly asks
  for it** — one `PreToolUse` entry (see "Optional: the router-read gate"). It touches no other hook
  event, and never modifies `ROUTER.md`, `AGENTS.md`, or `PROJECT/PDDA.md` themselves.
  - *This line used to promise the skill "does not touch `PreToolUse`". GH-23 P4b changed that on
    purpose, and amended the promise rather than leaving it quietly false. The gate remains off unless
    the operator asks for it AND creates the lever file, so the default behavior this line originally
    described is still what an operator gets by saying yes to step 1 alone.*
