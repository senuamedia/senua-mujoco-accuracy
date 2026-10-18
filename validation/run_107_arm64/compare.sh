#!/usr/bin/env bash
# Run 107's comparison, on the first cloud machine, after the arm64 machine's plays are copied into arm/: every play
# file of each pair of builds compared byte for byte; for a file that differs, the first step (line) where it does, and
# both files read by Senua AI's measure (`final`, the last step's state). Pairs: each build against its own second
# play (determinism on one machine); the arm64 builds against Intel's (across architectures). Writes compare.txt and
# readings.txt.
# usage: compare.sh <sx_contact>   (repository root; validation/run_107_arm64/arm and x86 hold the two machines' plays)
set -u
B="$(cd "$(dirname "${1:?usage: compare.sh <sx_contact>}")" && pwd)/$(basename "$1")"
O=validation/run_107_arm64
PAIRS="arm/relA:arm/relA_2 arm/srcA:arm/srcA_2 arm/srcAnc:arm/srcAnc_2 arm/setAnc:arm/setAnc_2 x86/relX:x86/relX_2 x86/srcXna:x86/srcXna_2 x86/setXna:x86/setXna_2 arm/relA:x86/relX arm/srcA:x86/relX arm/srcAnc:x86/relX x86/srcXna:x86/relX arm/srcAnc:x86/srcXna arm/setAnc:x86/setXna"
: > "$O/compare.txt"; : > "$O/readings.txt"
for p in $PAIRS; do
  a=${p%%:*}; b=${p#*:}; n=0; s=0; dl=""
  for f in $(cd "$O/$a" && find . -type f ! -name stats.txt | sed 's|^\./||' | sort); do
    n=$((n + 1))
    if cmp -s "$O/$a/$f" "$O/$b/$f"; then s=$((s + 1)); else
      line=$(cmp "$O/$a/$f" "$O/$b/$f" 2>&1 | grep -o 'line [0-9]*' | head -1)
      dl="$dl ${f%.txt}(${line:-missing})"
      { echo "$a $f | $("$B" final "$O/$a/$f" < /dev/null | tail -1)"; echo "$b $f | $("$B" final "$O/$b/$f" < /dev/null | tail -1)"; } >> "$O/readings.txt"
    fi
  done
  st=$(cmp -s "$O/$a/stats.txt" "$O/$b/stats.txt" && echo "the same" || echo "different")
  echo "$a against $b: $s of $n play files the same; the solver's statistics $st;${dl:+ differ, at their first differing step:$dl}" >> "$O/compare.txt"
done
