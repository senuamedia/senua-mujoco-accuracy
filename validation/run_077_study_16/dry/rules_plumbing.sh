#!/usr/bin/env bash
# Study 16's rules plumbing check: the rules judged on the dry run's lines in a scratch copy, with run 064's release and
# runs 068 and 074's suite results standing in for the four suites (run 068's off and all for every switch unset and
# the four set, run 074's on for the collinear switch alone), one test changed by hand in the collinear-alone suite
set -eu
R=~/work/dry077; O=~/work/plumb77; rm -rf "$O"; cp -R "$R/validation/run_077_study_16/dry" "$O"
cp "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_release.txt"
cp "$R/validation/run_068_full_set/suite_results_off.txt" "$O/suite_results_off.txt"
cp "$R/validation/run_068_full_set/suite_results_all.txt" "$O/suite_results_set4.txt"
awk '$1 == 148 { $3 = "Failed" } { print }' "$R/validation/run_074_boxbox_collinear/suite_results_on.txt" > "$O/suite_results_col.txt"
squeeze() { :; }   # the dry run's stack files are compressed already
B=~/sxbuild/sx_contact; ARMS="rel_def rel_rec off_def off_rec set_rec set4_rec col_def"
DTS="0.00114 0.000285 0.0001425"; NS="3 5 9 12"; TOLS="def 1e-10 1e-12"
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_077_study_16/play.sh")"
cat "$O/rules.txt"
# and again with the collinear-alone reading removed, which M0 must fail
echo "with the collinear-alone suite reading removed:"
rm -f "$O/suite_results_col.txt"
eval "$(sed -n '/^get() {/,$p' "$R/validation/run_077_study_16/play.sh")"
grep -E 'M0|M2' "$O/rules.txt"
