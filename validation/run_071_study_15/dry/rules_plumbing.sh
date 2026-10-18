#!/usr/bin/env bash
set -u
R=~/work/dry071; O=~/work/plumb71; rm -rf "$O"; cp -R "$R/validation/run_071_study_15/dry" "$O"
cp "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_release.txt"
cp "$R/validation/run_068_full_set/suite_results_off.txt" "$O/suite_results_off.txt"
awk "\$1 == 148 { \$3 = \"Failed\" } { print }" "$R/validation/run_068_full_set/suite_results_all.txt" > "$O/suite_results_on.txt"
B=~/sxbuild/sx_contact; ARMS="rel_def rel_rec off_def off_rec on_rec on_rk4"
DTS="0.00119 0.0002975"; DC=0.00119; DF=0.0002975; DIRS="0 22.5 45"; FDIRS="0 11.25 22.5 33.75 45"; FRS="0.5 0.75 0.95"
LADDER="0.01 0.0025 0.000625 0.00015625"; GOFF=0.0077
COULOMB=$(awk -v v=1.15 -v u=0.411 "BEGIN { printf \"%d\", v * v / (2 * u * 9.8) * 1e6 + 0.5 }")
eval "$(sed -n "/^get() {/,\$p" "$R/validation/run_071_study_15/play.sh")"
cat "$O/rules.txt"
