#!/usr/bin/env bash
# Study 18's rules plumbing check: the rules judged on the dry run's lines in a scratch copy, then again with one RK4
# chain reading changed by hand to 500 ppm, which R1 must fail
set -eu
R=~/work/dry081; O=~/work/plumb81; rm -rf "$O"; cp -R "$R/validation/run_081_study_18/dry" "$O"
B=~/sxbuild/sx_contact; DTS="0.01 0.0025 0.000625 0.00015625"
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_081_study_18/play.sh")"
cat "$O/rules.txt"
echo "with the RK4 free chain's energy at 0.0025 changed by hand to 500 ppm:"
awk '$1 == "free" && $2 == "RK4" && $3 == "0.0025" { $5 = 500 } { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_081_study_18/play.sh")"
grep 'R1_' "$O/rules.txt"
