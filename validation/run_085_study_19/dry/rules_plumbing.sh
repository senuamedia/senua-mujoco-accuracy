#!/usr/bin/env bash
# Study 19's rules plumbing check: the rules judged on the dry run's lines in a scratch copy, run 064's release and run
# 084's suite results standing in for the three suites, one test changed by hand in the five-switch suite (M1 must
# fail) and one box's fastest speed changed by hand to 50 um/s (R1 must fail)
set -eu
R=~/work/dry085; O=~/work/plumb85; rm -rf "$O"; cp -R "$R/validation/run_085_study_19/dry" "$O"
cp ~/work/rec084plumb/suite_results_release.txt "$O/suite_results_release.txt"
cp ~/work/rec084plumb/suite_results_off.txt "$O/suite_results_off.txt"
awk '$1 == 148 { $3 = "Failed" } { print }' ~/work/rec084plumb/suite_results_set5.txt > "$O/suite_results_set5.txt"
awk '$1 == "set5" && $3 == "2" && $5 == "n100" { $9 = 50 } { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
B=~/sxbuild/sx_contact; ARMS="rel off set4 set5"; BOXES="1 2 3"; DTB=0.016
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_085_study_19/play.sh")"
cat "$O/rules.txt"
