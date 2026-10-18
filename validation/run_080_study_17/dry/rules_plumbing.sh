#!/usr/bin/env bash
# Study 17's rules plumbing check: the rules judged on the dry run's lines in a scratch copy, then again with one
# condim-1 slide's lost speed changed by hand to 5 um/s, which F1 must fail
set -eu
R=~/work/dry080; O=~/work/plumb80; rm -rf "$O"; cp -R "$R/validation/run_080_study_17/dry" "$O"
B=~/sxbuild/sx_contact; ARMS="rel_def rel_rec"; DTS="0.00114 0.000285"; DIRS="0 22.5 45"; LOCKS="1 0"; SECS=2
LEAST=$(awk -v s="$SECS" 'BEGIN { printf "%d", 0.00001 * 9.8 * s * 1e6 + 0.5 }')
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_080_study_17/play.sh")"
cat "$O/rules.txt"
echo "with one condim-1 slide's lost speed changed by hand to 5 um/s:"
awk '$1 == "rel_def" && $3 == 1 && $4 == "22.5" && $5 == 1 && $6 == "0.00114" { $8 = 5 } { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_080_study_17/play.sh")"
grep 'rel_def_F1' "$O/rules.txt"
