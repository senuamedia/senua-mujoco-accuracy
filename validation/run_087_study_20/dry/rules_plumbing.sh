#!/usr/bin/env bash
# Study 20's rules plumbing check: the rules judged on the dry run's lines in a scratch copy, run 064's release and run
# 086's suite results standing in for the three suites; by hand, one test changed in the five-switch suite (M1 must fail),
# one hold of version 2's set changed to 50 um/s (H1 must fail) and one released arm's reading blanked (P0 must fail)
set -eu
R=~/work/dry087; O=~/work/plumb87; rm -rf "$O"; cp -R "$R/validation/run_087_study_20/dry" "$O"
cp ~/work/plumb87src/suite_results_release.txt "$O/suite_results_release.txt"
cp ~/work/plumb87src/suite_results_off.txt "$O/suite_results_off.txt"
awk '$1 == 148 { $3 = "Failed" } { print }' ~/work/plumb87src/suite_results_on.txt > "$O/suite_results_set5.txt"
awk 'done != 1 && $1 == "v2set" && $2 == "hold" { $9 = 50; done = 1 } d2 != 1 && $1 == "rel" && $2 == "arm" { $5 = ""; d2 = 1 } { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
B=~/sxbuild/sx_contact; ARMS="rel off v1set v2set"
eval "$(sed -n '/^same_files() {/,$p' "$R/validation/run_087_study_20/play.sh")"
cat "$O/rules.txt"
