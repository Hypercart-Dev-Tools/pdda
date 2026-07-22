#!/usr/bin/env bash
# Test: pdda.sh governance — dead-reference resolution (incl. bare-filename fallback + GH-doc
# exemption), orphan-doc detection, subcommand drift, and env-var drift.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf '----\n%s\n----\n' "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf '----\n%s\n----\n' "$1" ;; *) pass "$3" ;; esac; }
assert_eq()       { [ "$1" = "$2" ] && pass "$3" || fail "$3 (expected '$2', got '$1')"; }

SBOX=""
cleanup() { [ -n "$SBOX" ] && rm -rf "$SBOX"; }
trap cleanup EXIT

new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-governance.XXXXXX")"
  mkdir -p "$SBOX/PROJECT/2-WORKING" "$SBOX/utils/pdda"
}

run_check() {
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_MODE=full \
  PDDA_FORMAT=text \
  bash "$PDDA" governance 2>&1
}

# --- dead reference: a markdown link to a file that does not exist --------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

See [the plan](PROJECT/2-WORKING/NOPE.md) for details.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference" "dead markdown-link reference is flagged"
assert_contains "$out" "NOPE.md" "flags the specific missing file"
assert_contains "$out" "WARN [pdda-check-governance]" "dead reference is severity warn, not error"

# --- bare filename that exists elsewhere in the repo is NOT flagged (blank.md-style mention) -------
new_sandbox
mkdir -p "$SBOX/PROJECT/3-COMPLETED"
: > "$SBOX/PROJECT/3-COMPLETED/blank.md"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

`blank.md` placeholders are scaffolding and should be ignored.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'blank.md'" "bare filename found elsewhere in the repo is not flagged dead"

# --- a GH-<n>-*.md name is a naming-convention example, never a real cross-reference ---------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Name it like `GH-1234-EXAMPLE-DOC.md`.
EOF
out="$(run_check)"
assert_absent "$out" "GH-1234-EXAMPLE-DOC.md" "GH-issue example filename is exempt from dead-reference checking"

# --- orphan doc: a present governance doc the index doc never mentions ----------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Nothing else mentioned here.
EOF
cat > "$SBOX/AGENTS.md" <<'EOF'
# AGENTS.md
EOF
out="$(run_check)"
assert_contains "$out" "not referenced anywhere in ROUTER.md" "a governance doc unreferenced by the index doc is flagged"
assert_contains "$out" "WARN [pdda-check-governance]" "orphan-doc finding is severity warn, not error"

# --- subcommand drift: the real pdda.sh dispatcher has a 'governance' subcommand -------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Run `pdda.sh frontmatter` and `pdda.sh roadmap`.
EOF
out="$(run_check)"
assert_contains "$out" "subcommand 'governance' is not documented" "an undocumented real subcommand is flagged"
assert_contains "$out" "ERROR [pdda-check-governance]" "subcommand drift is severity error (mechanical, blocks in full)"

new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Run `pdda.sh governance` for the doc-consistency check.
EOF
out="$(run_check)"
assert_absent "$out" "subcommand 'governance' is not documented" "a documented real subcommand is not flagged"

# --- env-var drift: a fabricated var is flagged; a real one implemented in pdda-lib.sh is not -------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Set `PDDA_TOTALLY_MADE_UP_VAR` before running.
EOF
out="$(run_check)"
assert_contains "$out" "PDDA_TOTALLY_MADE_UP_VAR" "a fabricated env var not read by any shipped script is flagged"
assert_contains "$out" "WARN [pdda-check-governance]" \
  "env-var drift is severity warn, not error (PDDA-INSTALL.md legitimately documents canonical-only pdda-sync.sh vars that a target install never ships)"

new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
Set `PDDA_MODE` before running.
EOF
out="$(run_check)"
assert_absent "$out" "PDDA_MODE' which no shipped script" "a real env var implemented in pdda-lib.sh is not flagged"

# ==================================================================================================
# GH-23 P3 — the dead-reference scan reaches *.sh, not just *.md.
#
# A router's most load-bearing lines are the commands it tells an agent to run. Those never look like a
# markdown link, and they rarely close a backtick span right after the suffix — they carry arguments.
# Before P3 the scan matched neither, so a router could point every agent at a script that does not
# exist and `pdda.sh run` would report success. That is how LTVera-Pandas was installed.
#
# The positives below FAIL against pre-P3 pdda.sh. The negatives PASS against it — they are guards on
# the widening, not evidence for it, and the whole risk of P3 lives in them: the same pattern that
# catches `pdda-sync.sh push` could just as easily misread `pdda.sh run` as a path.
# ==================================================================================================

# --- POSITIVE: a dead .sh reference in a markdown link --------------------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Run [the sync tool](utils/pdda/pdda-sync.sh) to distribute.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'utils/pdda/pdda-sync.sh'" "dead .sh markdown-link reference is flagged"

# --- POSITIVE: a dead .sh reference in a whole backtick span ---------------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The installer is `install.sh` and it lives at the repo root.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'install.sh'" "dead .sh backtick-span reference is flagged"

# --- POSITIVE: command position inside a ```bash fence (the exact LTVera symptom) ------------------
# _pdda_gov_scannable_lines exempts only console/text/transcript fences, so a ```bash fence IS scanned.
# The line was invisible because it is a bare command invocation: no link, no closing backtick.
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

To distribute this runtime to other repos:

```bash
utils/pdda/pdda-sync.sh push
```
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'utils/pdda/pdda-sync.sh'" \
  "a bare command invocation inside a scanned bash fence is flagged (GH-23 root symptom)"

# --- POSITIVE: command position in a backtick span that carries an argument ------------------------
# The canonical ROUTER.md's own dead ref was `.xyz/utils/marathon-plan.sh --help`. Suffix widening
# ALONE never catches this: the span does not close after ".sh". This is why (c) exists.
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Vendored copy: see `.xyz/utils/marathon-plan.sh --help` for the generator.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference '.xyz/utils/marathon-plan.sh'" \
  "a backtick span carrying an argument is still a path claim and is flagged"

# --- POSITIVE (regression fixture): the real ROUTER.md that shipped into LTVera-Pandas -------------
# Byte-identical capture of the router install.sh --with-startup-docs wrote into that repo. Every .sh
# it names is absent there. This is the bug of record; it must never scan clean again.
new_sandbox
cp "$REPO_ROOT/test/fixtures/gh-23/LTVera-Pandas-ROUTER.md" "$SBOX/ROUTER.md"
out="$(run_check)"
assert_contains "$out" "dead reference 'install.sh'" "LTVera fixture: dead install.sh is flagged"
assert_contains "$out" "utils/pdda/pdda-sync.sh" "LTVera fixture: dead pdda-sync.sh is flagged"
assert_contains "$out" "utils/pdda/pdda.sh" "LTVera fixture: dead pdda.sh is flagged"
assert_absent "$out" "ERROR [pdda-check-governance] $SBOX/ROUTER.md" \
  "LTVera fixture: dead refs are warn-only, never error (house style: recommend, never act)"

# --- NEGATIVE CONTROL: a live .sh reference must NOT be flagged ------------------------------------
new_sandbox
mkdir -p "$SBOX/utils/pdda"
: > "$SBOX/utils/pdda/pdda.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The runnable surface is `utils/pdda/pdda.sh`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'utils/pdda/pdda.sh'" "a live .sh path that exists is not flagged"

# --- NEGATIVE CONTROL: a non-path code span (`pdda.sh run`) must NOT be flagged --------------------
# `pdda.sh` resolves through the bare-filename repo-wide fallback; the trailing subcommand word is not
# a second reference. Over-flagging either half would make every command rail in every router noisy.
new_sandbox
mkdir -p "$SBOX/utils/pdda"
: > "$SBOX/utils/pdda/pdda.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Before reporting success, run `pdda.sh run` or `utils/pdda/pdda.sh <check>`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a code span with a subcommand argument yields no dead reference"
assert_absent "$out" "'run'" "the subcommand word is never extracted as a path"

# --- NEGATIVE CONTROL: a glob is a pattern, not a path claim --------------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Keep the shipped `utils/pdda-*.sh` surface in sync with the manifest.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a glob pattern is not treated as a path claim"

# --- NEGATIVE CONTROL: a .sh word mid-sentence is prose, not a command ----------------------------
# (c) only matches at line start or right after a backtick — where a shell command's program sits.
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Historically the entry point was named setup.sh before the rename.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'setup.sh'" "a bare .sh word mid-sentence is prose, not a command-position path"

# --- NEGATIVE CONTROL: `./x.sh` in command position resolves against the repo root -----------------
# A doc nested under utils/pdda/ saying `./install.sh` means "run it from the repo root", not
# "utils/pdda/./install.sh". Resolving it relative to the referencing doc invents a dead ref.
new_sandbox
: > "$SBOX/install.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
./install.sh /path/to/repo
```
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a leading ./ in command position resolves against the repo root"

# --- NEGATIVE CONTROL: one ref named twice on a line yields one finding, not two -------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Run `install.sh` — yes, `install.sh` — from the root.
EOF
out="$(run_check)"
n="$(printf '%s\n' "$out" | grep -c "dead reference 'install.sh'" || true)"
assert_eq "$n" "1" "a ref repeated on one line is deduplicated into a single finding"

# --- NEGATIVE CONTROL: shipped-doc exemptions still suppress canonical-only tools ------------------
# GH-15's carve-out, now load-bearing for .sh too: PROJECT/PDDA.md ships to every target, where
# install.sh and the sync engine legitimately do not exist. Without this, a fresh install self-inflicts
# 46 warns on first run and buries the target's own drift signal.
new_sandbox
mkdir -p "$SBOX/PROJECT"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
See `PROJECT/PDDA.md`.
EOF
cat > "$SBOX/PROJECT/PDDA.md" <<'EOF'
# PDDA.md

Install with `install.sh <target>` and distribute with `utils/pdda/pdda-sync.sh push`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'install.sh'" "shipped doc: canonical-only install.sh is exempt"
assert_absent "$out" "dead reference 'utils/pdda/pdda-sync.sh'" "shipped doc: canonical-only sync engine is exempt"

# --- NEGATIVE CONTROL: the exemption is scoped to shipped docs only --------------------------------
# A repo-authored governance doc naming a missing install.sh is still a real bug (this is the very
# defect P3 removed from the canonical GUIDING-PRINCIPLES.md).
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md
See `GUIDING-PRINCIPLES.md`.
EOF
cat > "$SBOX/GUIDING-PRINCIPLES.md" <<'EOF'
# GUIDING-PRINCIPLES.md
The contract must be cheap to adopt (`install.sh`).
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'install.sh'" \
  "a NON-shipped governance doc naming a missing install.sh is still flagged (exemption does not leak)"

# --- POSITIVE: command-position refs terminated by prose/shell punctuation ------------------------
# Found by an adversarial cross-model review of P3. A command is rarely the last thing on its line.
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
alpha.sh; beta.sh
```

`gamma.sh, then keep going`
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'alpha.sh'" "a command terminated by ';' is flagged"
assert_contains "$out" "dead reference 'gamma.sh'" "a command terminated by ',' is flagged"
assert_absent "$out" "dead reference 'alpha.sh;'" "the terminator is not part of the extracted path"

# --- NEGATIVE CONTROL: a trailing '.' is NOT a terminator ------------------------------------------
# `deploy.sh.bak` must not be harvested as `deploy.sh`. A sentence ending in a bare command name is the
# rarer case; a false flag on a real backup file is the worse one. This is a deliberate, documented miss.
new_sandbox
: > "$SBOX/deploy.sh.bak"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

`deploy.sh.bak` is the backup we keep around.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'deploy.sh'" "a '.sh.' inside a longer suffix is not extracted"

# --- NEGATIVE CONTROL: .shtml is not .sh ------------------------------------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
legacy.shtml
```
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a longer suffix (.shtml) never matches the .sh pattern"

# ==================================================================================================
# GH-33 — interpreter-wrapped script invocations (bash x.sh, sudo ./x.sh, sh setup.sh, env FOO=1 ./x.sh)
# --------------------------------------------------------------------------------------------------
# P3's command-position pattern only matches a .sh that OPENS a code span or scanned fence line — where
# a shell command's PROGRAM sits. Hand the script to an interpreter and it moves to ARGUMENT position,
# so the scan went blind: `bash utils/x.sh` extracted nothing. Each is a real path claim; a router could
# point every agent at `bash missing.sh` and `pdda.sh run` stayed green. Same family as GH-23.
#
# The positives below FAIL against pre-GH-33 pdda.sh. The negatives are the whole risk of the widening:
# an interpreter allowlist that also swallowed `bash -c "..."`, a quoted arg, or a $VAR would invent
# dead refs out of ordinary shell prose.
# ==================================================================================================

# --- POSITIVE: `bash <path>` in argument position (the exact blind spot) ---------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
bash utils/pdda/missing.sh
```
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'utils/pdda/missing.sh'" \
  "an interpreter-wrapped 'bash <path>' names a dead script and is flagged (GH-33)"

# --- POSITIVE: `sudo ./x.sh` — transparent sudo prefix, leading ./ resolves to a bare name ---------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
sudo ./deploy.sh
```
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'deploy.sh'" "a sudo-prefixed './x.sh' is flagged when dead (GH-33)"

# --- POSITIVE: `sh <path>` and `source <path>` are interpreters too -------------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
sh scripts/setup.sh
source lib/helpers.sh
```
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'scripts/setup.sh'" "an 'sh <path>' invocation is flagged (GH-33)"
assert_contains "$out" "dead reference 'lib/helpers.sh'" "a 'source <path>' invocation is flagged (GH-33)"

# --- POSITIVE: `env FOO=1 ./x.sh` — env + assignments, then the path IS the program ----------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
env FOO=1 ./run.sh
```
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'run.sh'" "an 'env VAR=val ./x.sh' invocation resolves the path and is flagged (GH-33)"

# --- NEGATIVE CONTROL: `bash -c "..."` — the argument is code, not a path -------------------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
bash -c "run deploy.sh now"
```
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a .sh inside a 'bash -c' string argument is never a path claim (GH-33)"

# --- NEGATIVE CONTROL: `bash "$VAR/x.sh"` — a variable expansion is not a path claim ---------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
bash "$SCRIPTS/setup.sh"
```
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a \$VAR-prefixed argument after an interpreter is not extracted (GH-33)"

# --- NEGATIVE CONTROL: `sudo rm -rf x` — a wrapper with no .sh program yields nothing --------------
new_sandbox
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

Cleanup: `sudo rm -rf build` before reinstalling.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "a sudo-prefixed command with no script argument yields no finding (GH-33)"

# --- NEGATIVE CONTROL: a live interpreter-wrapped ref must NOT be flagged --------------------------
new_sandbox
mkdir -p "$SBOX/utils/pdda"
: > "$SBOX/utils/pdda/pdda.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

```bash
bash utils/pdda/pdda.sh run
```
EOF
out="$(run_check)"
assert_absent "$out" "dead reference" "an interpreter-wrapped ref to a file that exists is not flagged (GH-33)"

# ==================================================================================================
# GH-34 — the bare-filename fallback treated a reference as a glob, not a literal.
# --------------------------------------------------------------------------------------------------
# _pdda_gov_resolve_ref's repo-wide fallback passed the ref straight to `find -name "$ref"`, which
# globs. A markdown link (whose extraction class admits [ ] * ?) carrying `build[1].sh` resolved against
# a repo holding `build1.sh` — a DIFFERENT file — so the dead ref was scored LIVE. A false negative in
# the check whose whole job is catching them. (Backtick/command-position refs are shielded — their
# classes exclude glob metachars — but markdown-link refs are not, which is the reachable vector.)
# ==================================================================================================

# --- POSITIVE: a glob-metachar ref must match literally, not as a pattern --------------------------
new_sandbox
: > "$SBOX/build1.sh"          # the DIFFERENT file a glob would wrongly match
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

See [the packager](build[1].sh) for the build step.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'build[1].sh'" \
  "a glob-metachar ref is matched literally; 'build[1].sh' does not resolve against 'build1.sh' (GH-34)"

# --- NEGATIVE CONTROL: the literal bare-filename fallback still resolves a real mention ------------
new_sandbox
mkdir -p "$SBOX/utils/pdda"
: > "$SBOX/utils/pdda/pdda-lib.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The helpers live in `pdda-lib.sh`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'pdda-lib.sh'" \
  "a bare filename that exists elsewhere still resolves under literal matching (GH-34 no regression)"

# ==================================================================================================
# GH-48 — the bare-filename fallback re-walked the whole repo tree in a bash `while read` loop, once
# per LINE mentioning an unresolved bare name (not deduped per run). On a large real repo with a
# common bare command name (e.g. `pdda.sh`) mentioned on dozens of lines, that multiplied into a
# multi-minute stall. Fixed by letting `find -name` (glob-escaped, GH-34-safe) do the matching natively
# during ONE traversal per unique bare name (memoized per run in a small per-name cache directory)
# instead of a bash-level basename compare against every entry in the tree.
# ==================================================================================================

# --- REGRESSION: a bare filename resolves correctly even when its directory contains a literal tab --
# The first fix attempt stored "basename<TAB>path" and split lookups on tab — a path whose directory
# portion itself contained a real tab byte then got truncated by that split, so a real, existing file
# was scored as a dead reference. The index must preserve the whole path untouched.
new_sandbox
tabdir="$SBOX/some$(printf '\t')dir"
mkdir -p "$tabdir"
: > "$tabdir/pdda-lib.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The helpers live in `pdda-lib.sh`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'pdda-lib.sh'" \
  "a bare filename resolves correctly even when its directory contains a literal tab byte (GH-48)"

# --- REGRESSION: a `find` permission error elsewhere in the tree doesn't stop a real bare ref from --
# --- resolving. Each lookup runs its own `find -name` (see _pdda_gov_resolve_ref) with stderr
# --- suppressed; BSD find keeps emitting entries it CAN reach and only its exit status reflects the
# --- error, so a real match outside the blocked subtree must still be found.
if [ "$(id -u 2>/dev/null)" = "0" ]; then
  pass "find-permission-error case skipped — running as root, chmod 000 can't simulate a denial"
else
  new_sandbox
  mkdir -p "$SBOX/utils/pdda"
  : > "$SBOX/utils/pdda/pdda-lib.sh"
  cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The helpers live in `pdda-lib.sh`.
EOF
  noexec_dir="$SBOX/unreadable"
  mkdir -p "$noexec_dir"
  chmod 000 "$noexec_dir"
  out="$(PDDA_REPO_ROOT="$SBOX" PDDA_MODE=full PDDA_FORMAT=text bash "$PDDA" governance 2>&1)"
  chmod 755 "$noexec_dir"   # restore before cleanup can remove it
  assert_absent "$out" "dead reference 'pdda-lib.sh'" \
    "a find permission error elsewhere in the tree still resolves a real bare ref found outside it (GH-48)"
fi

# --- REGRESSION: first-traversal-match-wins is preserved even when the first match is a directory --
# A second-attempt fix added `-type f` to the lookup, which changed WHICH entry `find` could return:
# the old bash loop (and this fix) can match a directory whose basename equals the bare ref first, and
# only the caller's `[ -f "$resolved" ]` decides it's dead — same as before. `-type f` would instead
# skip past that directory to a later real file and wrongly call the ref live.
new_sandbox
mkdir -p "$SBOX/aaa/target.md" "$SBOX/zzz"     # "aaa/target.md" (a DIR) sorts before "zzz/target.md"
: > "$SBOX/zzz/target.md"                      # a real FILE with the same basename, later in traversal
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

See `target.md` for details.
EOF
out="$(run_check)"
assert_contains "$out" "dead reference 'target.md'" \
  "a same-named directory earlier in traversal order still shadows a later real file (GH-48, no -type f)"

# --- REGRESSION: a bare filename resolves correctly even when its directory contains a literal
# --- newline byte. The index-file version of this fix stored one path per line — a path whose
# --- directory portion itself contained a real newline byte then split into two records, corrupting
# --- it. `find -name` + NUL-delimited `-print0`/`read -r -d ''` can't split on a byte a path can't
# --- contain, so this can't happen.
new_sandbox
nldir="$SBOX/some
dir"
mkdir -p "$nldir"
: > "$nldir/pdda-lib.sh"
cat > "$SBOX/ROUTER.md" <<'EOF'
# ROUTER.md

The helpers live in `pdda-lib.sh`.
EOF
out="$(run_check)"
assert_absent "$out" "dead reference 'pdda-lib.sh'" \
  "a bare filename resolves correctly even when its directory contains a literal newline byte (GH-48)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
