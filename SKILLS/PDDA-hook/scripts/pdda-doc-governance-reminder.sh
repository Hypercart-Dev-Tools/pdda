#!/usr/bin/env bash
# Canonical source for the PDDA-hook skill's SessionStart reminder.
# Fires on startup/resume/clear/compact — every point a Claude Code session's
# context actually resets, which is where "read ROUTER.md/AGENTS.md" is most
# likely to get silently skipped.
#
# Auto-scopes itself: no-ops in any repo without PROJECT/PDDA.md, so the same
# script is safe to register once (globally) and cover every PDDA repo, or
# register per-repo — see SKILLS/PDDA-hook/SKILL.md for both install paths.

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

[ -f "$root/PROJECT/PDDA.md" ] || exit 0

cat << 'REMINDER'
DOC GOVERNANCE (PDDA) — this repo's docs are governed deterministically, not by memory:
1. Read ROUTER.md first for startup order and canonical entry points; AGENTS.md for
   behavioral rules; the linked PROJECT/** doc for the work being touched.
2. If this turn touches PROJECT/** docs, ROADMAP.md, or CHANGELOG.md, follow the
   PROJECT/PDDA.md contract — keep ROADMAP.md pointers current, don't hand-roll
   checklists PDDA already owns.
3. Before reporting doc-hygiene or roadmap work done, run `utils/pdda/pdda.sh run`
   (or the relevant subcommand). Do not override deterministic PDDA findings with prose.
4. Before reporting code/runtime work done, run the repo's own verification command
   (e.g. `./validate.sh`) if one exists.
5. Update CHANGELOG.md at the end of the iteration per PROJECT/PDDA.md.
REMINDER
