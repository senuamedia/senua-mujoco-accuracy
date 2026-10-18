#!/usr/bin/env bash
# Run 108's comparisons and rules (preregistrations/PREREGISTRATION_24.md), on the first cloud machine, after the arm64
# machine's plays are copied into arm/: every play file of each pair of builds compared byte for byte (cmp); for a pair
# that differs, the first step where each file does and both files read by Senua AI's measure (`final`); every rule
# judged by the measure's `rule`. With DRY=1 it reads dry/ and writes rules_plumbing.txt.
# usage: judge.sh <sx_contact> [folder]   (repository root; the folder holds arm/ and x86/, default the run's own)
set -u
B="$(cd "$(dirname "${1:?usage: judge.sh <sx_contact> [folder]}")" && pwd)/$(basename "$1")"
O=${2:-validation/run_108_study_24}; [ "${DRY:-0}" = 1 ] && [ -z "${2:-}" ] && O=validation/run_108_study_24/dry
RF="$O/rules.txt"; [ "${DRY:-0}" = 1 ] && RF="$O/rules_plumbing.txt"
same() {  # <build a> <build b>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 n=0 s=0 f
  for f in $(cd "$O/$a" && find . -type f ! -name stats.txt | sed 's|^\./||' | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
count() { (cd "$O/$1" && find . -type f ! -name stats.txt | wc -l | tr -d ' '); }
: > "$O/compare.txt"; : > "$O/readings.txt"
for p in arm/relA:arm/relA_2 arm/srcA:arm/srcA_2 arm/clangAnc:arm/clangAnc_2 arm/setA:arm/setA_2 x86/relX:x86/relX_2 x86/setX:x86/setX_2 arm/srcA:x86/relX arm/clangAnc:x86/relX arm/setA:x86/setX arm/relA:x86/relX; do
  a=${p%%:*}; b=${p#*:}; dl=""
  for f in $(cd "$O/$a" && find . -type f ! -name stats.txt | sed 's|^\./||' | sort); do
    if ! cmp -s "$O/$a/$f" "$O/$b/$f"; then
      line=$(cmp "$O/$a/$f" "$O/$b/$f" 2>&1 | grep -o 'line [0-9]*' | head -1); dl="$dl ${f%.txt}(${line:-missing})"
      { echo "$a $f | $("$B" final "$O/$a/$f" < /dev/null | tail -1)"; echo "$b $f | $("$B" final "$O/$b/$f" < /dev/null | tail -1)"; } >> "$O/readings.txt"
    fi
  done
  read -r s n <<< "$(same "$a" "$b")"
  echo "$a against $b: $s of $n play files the same; the solver's statistics $(cmp -s "$O/$a/stats.txt" "$O/$b/stats.txt" && echo "the same" || echo "different");${dl:+ differ, at their first differing step:$dl}" >> "$O/compare.txt"
done
{
  rule() { "$B" rule "$@" < /dev/null | tail -1; }
  rule E0_both_machines_played_the_same_numbers eq "$(cmp -s "$O/arm/draw.txt" "$O/x86/draw.txt" && echo 1 || echo 0)" 1
  N=$(count x86/relX)
  # shellcheck disable=SC2046
  rule P0_every_play_made all_eq "$N" $(for b in arm/relA arm/relA_2 arm/srcA arm/srcA_2 arm/clangAnc arm/clangAnc_2 arm/setA arm/setA_2 x86/relX_2 x86/setX x86/setX_2; do count $b; done)
  for b in arm/relA arm/srcA arm/clangAnc arm/setA x86/relX x86/setX; do
    # shellcheck disable=SC2046
    rule "D1_${b#*/}_the_same_twice" eq $(same "$b" "${b}_2")
  done
  # shellcheck disable=SC2046
  rule X1_gcc_on_arm64_makes_the_intel_release eq $(same arm/srcA x86/relX)
  # shellcheck disable=SC2046
  rule X2_clang_without_fma_on_arm64_makes_the_intel_release eq $(same arm/clangAnc x86/relX)
  # shellcheck disable=SC2046
  rule X3_the_set_on_arm64_makes_the_set_on_intel eq $(same arm/setA x86/setX)
  read -r s n <<< "$(same arm/relA x86/relX)"
  rule Q1_the_arm64_release_departs_somewhere le "$s" "$((n - 1))"
  sed 's/^/reported: /' "$O/compare.txt"
} > "$RF"
echo "rules: $(grep -c '^RULE' "$RF"), held: $(grep -c ': HELD$' "$RF")" >> "$RF"
