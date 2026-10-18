#!/usr/bin/env bash
# rules_changed.sh <sx_contact> <dry/>: the judge run on seven scratch copies of the dry run, each with one change made
# by hand so that one rule must fail, and on the dry run as it is; each judgement's rule lines into
# rules_changed.txt, headed by the change. Changes: E0, a draw differs; P0, one play file missing from both plays of a
# build; D1, one byte more in one file of relA's second play; X1, X2, X3, one byte more in the same file of both plays
# of srcA, clangAnc, setA; Q1, relA's plays replaced by relX's.
# usage: rules_changed.sh <sx_contact> <dry folder>   (repository root)
set -u
B=$1; D="$(cd "${2:?}" && pwd)"; J=validation/run_108_study_24/judge.sh; OUTF="$D/rules_changed.txt"; : > "$OUTF"
F=d_hold.txt
one() {  # <label> <commands to run in the copy, as a string>
  local T; T=$(mktemp -d); cp -R "$D/arm" "$D/x86" "$T/"
  (cd "$T" && eval "$2")
  DRY=1 bash "$J" "$B" "$T" > /dev/null 2>&1
  { echo "== $1"; grep '^RULE' "$T/rules_plumbing.txt" | awk '{ print $2, $NF }'; tail -1 "$T/rules_plumbing.txt"; } >> "$OUTF"
  rm -rf "${T:?}"
}
one "as it is" ":"
one "E0: the Intel machine's draw changed" "sed -i '1s/ .*/ 0.0021/' x86/draw.txt"
one "P0: $F missing from both plays of srcA" "rm arm/srcA/$F arm/srcA_2/$F"
one "D1: one byte more in $F of relA's second play" "printf x >> arm/relA_2/$F"
one "X1: one byte more in $F of both plays of srcA" "printf x >> arm/srcA/$F; printf x >> arm/srcA_2/$F"
one "X2: one byte more in $F of both plays of clangAnc" "printf x >> arm/clangAnc/$F; printf x >> arm/clangAnc_2/$F"
one "X3: one byte more in $F of both plays of setA" "printf x >> arm/setA/$F; printf x >> arm/setA_2/$F"
one "Q1: relA's plays replaced by relX's" "rm -rf arm/relA arm/relA_2; cp -R x86/relX arm/relA; cp -R x86/relX arm/relA_2"
