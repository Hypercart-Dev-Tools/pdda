#!/usr/bin/env bash
# test/pdda-install-startup-docs.sh — GH-23 P1 + GH-25.
#
# Two defects lived in the same four lines of install.sh:
#
#   GH-23 P1  --with-startup-docs copied the canonical repo's own ROUTER.md verbatim, so every target
#             was told to run install.sh and utils/pdda/pdda-sync.sh — neither of which a target has.
#   GH-25     copy_runtime has no create-only guard, so the same flag silently destroyed a
#             repo-authored AGENTS.md (61,829 bytes in LTVera-Pandas) with PDDA's 2,289-byte stub.
#
# These tests pin the fix: ROUTER.md is written from templates/ROUTER.target.md, and the startup docs
# are create-only unless --force.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }
check(){ if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (want '$2', got '$1')"; fi; }

SBOX="$(mktemp -d "${TMPDIR:-/tmp}/pdda-install-startup.XXXXXX")"
trap 'rm -rf "$SBOX"' EXIT

new_target() {  # <name> -> prints path
  local d="$SBOX/$1"
  mkdir -p "$d" && ( cd "$d" && git init -q . )
  printf '# README\n' > "$d/README.md"
  printf '%s\n' "$d"
}

# Anything the canonical repo has and a target does not. A target router naming any of these is the bug.
CANONICAL_ONLY='install\.sh|pdda-sync\.sh|\.xyz'

# ---------------------------------------------------------------------------------------------------
# 1. The template exists and is not just a copy of the canonical router.
# ---------------------------------------------------------------------------------------------------
if [ -f "$REPO/templates/ROUTER.target.md" ]; then
  ok "templates/ROUTER.target.md exists"
else
  bad "templates/ROUTER.target.md exists"
fi

if cmp -s "$REPO/templates/ROUTER.target.md" "$REPO/ROUTER.md"; then
  bad "target template differs from the canonical ROUTER.md"
else
  ok "target template differs from the canonical ROUTER.md"
fi

n=$(grep -cE "$CANONICAL_ONLY" "$REPO/templates/ROUTER.target.md" || true)
check "$n" "0" "target template names zero canonical-only scripts/paths"

# The canonical router still legitimately documents them — the template is what got stripped, not it.
n=$(grep -cE "$CANONICAL_ONLY" "$REPO/ROUTER.md" || true)
if [ "$n" -gt 0 ]; then
  ok "canonical ROUTER.md still documents its own tooling ($n refs)"
else
  bad "canonical ROUTER.md lost its own tooling refs"
fi

# ---------------------------------------------------------------------------------------------------
# 2. A fresh --with-startup-docs install writes the template, never the canonical router.
# ---------------------------------------------------------------------------------------------------
T="$(new_target fresh)"
"$REPO/install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1

if cmp -s "$T/ROUTER.md" "$REPO/templates/ROUTER.target.md"; then
  ok "installed ROUTER.md == templates/ROUTER.target.md"
else
  bad "installed ROUTER.md != templates/ROUTER.target.md"
fi

if cmp -s "$T/ROUTER.md" "$REPO/ROUTER.md"; then
  bad "installed ROUTER.md is NOT the canonical router"
else
  ok "installed ROUTER.md is NOT the canonical router"
fi

n=$(grep -cE "$CANONICAL_ONLY" "$T/ROUTER.md" || true)
check "$n" "0" "installed ROUTER.md names zero canonical-only scripts/paths"

# ---------------------------------------------------------------------------------------------------
# 3. Every *.sh path named in the installed router resolves inside the target. (P2's assertion.)
# ---------------------------------------------------------------------------------------------------
dead=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  [ -e "$T/$ref" ] || { dead=$((dead+1)); printf '     dead .sh ref: %s\n' "$ref"; }
done < <(grep -oE '[A-Za-z0-9_./-]+\.sh' "$T/ROUTER.md" | sort -u)
check "$dead" "0" "every .sh ref in the installed router exists in the target"

# ---------------------------------------------------------------------------------------------------
# 4. GH-25: a repo-authored AGENTS.md survives --with-startup-docs.
# ---------------------------------------------------------------------------------------------------
T="$(new_target authored)"
printf '# AGENTS.md\n\nMY HARD-WON REPO CONVENTIONS.\n' > "$T/AGENTS.md"
printf '# GUIDING-PRINCIPLES.md\n\nMY OWN PRINCIPLES.\n' > "$T/GUIDING-PRINCIPLES.md"
a_before=$(md5 -q "$T/AGENTS.md" 2>/dev/null || md5sum "$T/AGENTS.md" | cut -d' ' -f1)
g_before=$(md5 -q "$T/GUIDING-PRINCIPLES.md" 2>/dev/null || md5sum "$T/GUIDING-PRINCIPLES.md" | cut -d' ' -f1)

"$REPO/install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1

a_after=$(md5 -q "$T/AGENTS.md" 2>/dev/null || md5sum "$T/AGENTS.md" | cut -d' ' -f1)
g_after=$(md5 -q "$T/GUIDING-PRINCIPLES.md" 2>/dev/null || md5sum "$T/GUIDING-PRINCIPLES.md" | cut -d' ' -f1)
check "$a_after" "$a_before" "repo-authored AGENTS.md survives --with-startup-docs (GH-25)"
check "$g_after" "$g_before" "repo-authored GUIDING-PRINCIPLES.md survives --with-startup-docs (GH-25)"

# A repo-authored ROUTER.md is equally protected.
T="$(new_target authored-router)"
printf '# ROUTER.md\n\nMY OWN ROUTER.\n' > "$T/ROUTER.md"
r_before=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
"$REPO/install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1
r_after=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
check "$r_after" "$r_before" "repo-authored ROUTER.md survives --with-startup-docs"

# ---------------------------------------------------------------------------------------------------
# 5. --force is the opt-in that overwrites. Negative control for test 4: prove the guard, not a no-op.
# ---------------------------------------------------------------------------------------------------
"$REPO/install.sh" "$T" --with-startup-docs --no-register --force >/dev/null 2>&1
r_forced=$(md5 -q "$T/ROUTER.md" 2>/dev/null || md5sum "$T/ROUTER.md" | cut -d' ' -f1)
if [ "$r_forced" != "$r_before" ]; then
  ok "--force does overwrite the startup docs (guard is real, not a silent skip)"
else
  bad "--force did not overwrite — the create-only guard may be unconditional"
fi
if cmp -s "$T/ROUTER.md" "$REPO/templates/ROUTER.target.md"; then
  ok "--force rewrites ROUTER.md from the template"
else
  bad "--force rewrote ROUTER.md from something other than the template"
fi

# ---------------------------------------------------------------------------------------------------
# 6. --help tells the truth: it must not promise an "adapted" copy of files it copies verbatim.
# ---------------------------------------------------------------------------------------------------
help_txt="$("$REPO/install.sh" --help 2>&1 || true)"
if printf '%s' "$help_txt" | grep -q 'templates/ROUTER.target.md'; then
  ok "--help names the template ROUTER.md is written from"
else
  bad "--help does not name the template"
fi
if printf '%s' "$help_txt" | grep -qi 'create-only'; then
  ok "--help states the create-only semantics"
else
  bad "--help does not state create-only semantics"
fi

# ---------------------------------------------------------------------------------------------------
# 7. A fresh install is clean under the target's own checks.
# ---------------------------------------------------------------------------------------------------
T="$(new_target clean)"
"$REPO/install.sh" "$T" --with-startup-docs --no-register >/dev/null 2>&1
errs=$( cd "$T" && utils/pdda/pdda.sh run 2>&1 | grep -cE '^ERROR' || true )
check "$errs" "0" "a fresh --with-startup-docs install reports zero errors in the target"

printf '\n=== pdda-install-startup-docs: %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
