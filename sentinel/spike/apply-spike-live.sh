#!/usr/bin/env bash
# Sourced by apply-spike.sh `live`. Real measurement: for each scenario, ONE model call renders the
# SAME edit in BOTH formats (controls for model variance), then each is applied to a fresh copy of the
# real repo doc and scored: applied? intended-change-present? no-collateral-loss? hardened-gate-pass?
#
# Marker protocol (not JSON — doc bodies contain braces/quotes that break brace-matching):
#   ===FULL_FILE===\n<entire updated doc>\n===END_FULL_FILE===
#   ===SEARCH_REPLACE===\n<Aider SEARCH/REPLACE blocks>\n===END_SEARCH_REPLACE===

PDDA_LLM_BIN="${PDDA_LLM_BIN:-}"
PDDA_LLM_ARGS="${PDDA_LLM_ARGS:--p}"
if [ -z "$PDDA_LLM_BIN" ] || ! command -v "$PDDA_LLM_BIN" >/dev/null 2>&1; then
  echo "live: PDDA_LLM_BIN unset/not-found — set it (e.g. PDDA_LLM_BIN=codex PDDA_LLM_ARGS=\"exec -s read-only\")" >&2
  exit 2
fi
read -ra _llm_args <<<"$PDDA_LLM_ARGS"
[ -n "${PDDA_LLM_MODEL:-}" ] && _llm_args+=(--model "$PDDA_LLM_MODEL")

rm -rf "$WORK"; mkdir -p "$WORK"
RESULTS="$WORK/results.tsv"
printf 'scenario\tformat\tapplied\tintended\tno_collateral\tgate\tnote\n' > "$RESULTS"

# Scenario table: src<TAB>instruction<TAB>assert_present<TAB>must_keep(;;-separated)
# All src files are REAL docs in this repo. Edits are small, realistic doc-drift fixes.
scenarios() {
cat <<'SCN'
ROUTER.md	Add a new command-rail entry line for a `pdda.sh progress` subcommand (reports open GitHub issues + Tasks closed this week), placed alongside the other `pdda.sh <check>` command lines. Change nothing else.	pdda.sh progress	pdda.sh governance;;pdda.sh gh-refresh;;pdda.sh doc-ready
README.md	The installer gained a `--dry-run` flag (preview actions without writing). Add one line describing it to the "Installer options" block. Change nothing else.	--dry-run	--with-startup-docs;;--mode observe|light|full;;## Day-to-day use
CHANGELOG.md	Add a new dated section `## 2026-07-06` at the very top (above the newest existing entry) with one bullet: "Sentinel Phase 1 shipped — dry-run doc-governance orchestrator." Keep all existing entries.	2026-07-06	## Maintaining;;PDDA
utils/pdda/PDDA-INSTALL.md	Document that Sentinel honors a `SENTINEL_ENABLED` kill-switch env var (set 0 to disable). Add a short mention in a sensible existing section. Change nothing else.	SENTINEL_ENABLED	PDDA_MODE;;install
ROUTER.md	In the "Role split" list, add a bullet for `sentinel/run.sh` = the dry-run doc-governance orchestrator. Change nothing else.	sentinel/run.sh	GUIDING-PRINCIPLES.md;;AGENTS.md;;## Startup sequence
SCN
}

extract() {  # <marker> <response-file>  -> prints body between ===<marker>=== and ===END_<marker>===
  awk -v s="===$1===" -v e="===END_$1===" '
    $0==s {on=1; next} $0==e {on=0} on {print}
  ' "$2"
}

score_one() {  # <scenario> <format> <applied 0/1> <result-file> <assert> <orig-file> <note>
  local scn="$1" fmt="$2" applied="$3" res="$4" assert="$5" orig="$6" note="$7"
  local intended=0 nocol=0 gate=0 lost=0
  if [ "$applied" = "1" ]; then
    grep -Fq -e "$assert" "$res" 2>/dev/null && intended=1   # -e: assert may start with '--'
    # collateral = original non-blank lines that VANISHED from the result (as exact lines). A targeted
    # add should lose ~0; a full-file rewrite that drops a section spikes this. <=3 tolerates minor
    # reflow. This is precisely the full-file lossiness signal search/replace can't exhibit.
    lost="$(awk 'NR==FNR{seen[$0]=1;next} $0 ~ /[^ \t]/ && !($0 in seen){m++} END{print m+0}' "$res" "$orig")"
    [ "${lost:-0}" -le 3 ] && nocol=1
    hardened_gate "$res" && gate=1
    [ "$note" = "ok" ] && note="lost=$lost"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$scn" "$fmt" "$applied" "$intended" "$nocol" "$gate" "$note" >> "$RESULTS"
}

n=0
while IFS=$'\t' read -r src instr assert keep; do
  [ -n "$src" ] || continue
  n=$((n+1))
  srcpath="$REPO_ROOT/$src"
  [ -f "$srcpath" ] || { echo "skip $src (missing)"; continue; }
  scn="$(basename "$src")#$n"
  echo ">> scenario $n: $src — ${instr%%.*}."

  prompt="You are editing ONE documentation file. Apply EXACTLY this change and nothing else:
$instr

Return the SAME edit rendered in BOTH formats, using these literal markers and nothing outside them:

===FULL_FILE===
<the ENTIRE updated file, complete, no elisions or '...'>
===END_FULL_FILE===
===SEARCH_REPLACE===
<one or more Aider-style blocks; SEARCH text must be copied BYTE-FOR-BYTE from the current file>
<<<<<<< SEARCH
(exact existing lines)
=======
(replacement lines)
>>>>>>> REPLACE
===END_SEARCH_REPLACE===

The current file ($src) is below:
--- BEGIN CURRENT FILE ---
$(cat "$srcpath")
--- END CURRENT FILE ---"

  resp="$WORK/resp.$n.txt"
  # </dev/null is load-bearing: codex exec reads stdin, and without this it drains the while-loop's
  # scenario list (fd 0 = the scenarios process substitution), ending the loop after one iteration.
  "$PDDA_LLM_BIN" ${_llm_args[@]+"${_llm_args[@]}"} "$prompt" > "$resp" 2>/dev/null </dev/null || true

  # --- full-file ---
  ff="$WORK/ff.$n.md"; extract FULL_FILE "$resp" > "$ff"
  tgt="$WORK/ff-target.$n.md"; cp "$srcpath" "$tgt"
  if [ -s "$ff" ]; then
    note="$(apply_full_file "$tgt" "$ff" 2>&1)"; rc=$?
    [ "$rc" -eq 0 ] && score_one "$scn" full_file 1 "$tgt" "$assert" "$srcpath" "ok" \
                    || score_one "$scn" full_file 0 "$tgt" "$assert" "$srcpath" "${note:-guard}"
  else
    score_one "$scn" full_file 0 "$tgt" "$assert" "$srcpath" "no FULL_FILE marker"
  fi

  # --- search/replace ---
  sr="$WORK/sr.$n.md"; extract SEARCH_REPLACE "$resp" > "$sr"
  tgt2="$WORK/sr-target.$n.md"; cp "$srcpath" "$tgt2"
  if [ -s "$sr" ]; then
    note="$(apply_search_replace "$tgt2" "$sr" 2>&1)"; rc=$?
    case "$rc" in
      0) score_one "$scn" search_replace 1 "$tgt2" "$assert" "$srcpath" "ok" ;;
      3) score_one "$scn" search_replace 0 "$tgt2" "$assert" "$srcpath" "anchor-not-found" ;;
      4) score_one "$scn" search_replace 0 "$tgt2" "$assert" "$srcpath" "ambiguous" ;;
      5) score_one "$scn" search_replace 0 "$tgt2" "$assert" "$srcpath" "malformed" ;;
      *) score_one "$scn" search_replace 0 "$tgt2" "$assert" "$srcpath" "err$rc" ;;
    esac
  else
    score_one "$scn" search_replace 0 "$tgt2" "$assert" "$srcpath" "no SR marker"
  fi
done < <(scenarios)

echo
echo "=== RESULTS (per scenario) ==="
column -t -s$'\t' "$RESULTS"

echo
echo "=== TALLY (applied / intended / no_collateral / gate-pass, out of $n) ==="
for fmt in full_file search_replace; do
  awk -F'\t' -v f="$fmt" '
    $2==f { a+=$3; i+=$4; c+=$5; g+=$6; t++ }
    END { printf "%-15s applied=%d/%d  intended=%d/%d  no_collateral=%d/%d  gate=%d/%d  clean(all4)=", f, a,t, i,t, c,t, g,t }
  ' "$RESULTS"
  awk -F'\t' -v f="$fmt" '$2==f && $3==1 && $4==1 && $5==1 && $6==1 {ok++} END{print ok+0}' "$RESULTS"
done
echo
echo "results.tsv -> $RESULTS"
