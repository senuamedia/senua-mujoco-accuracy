#!/usr/bin/env bash
# Study 21's rules plumbing check: the rules judged on the dry run's lines in a scratch copy. Run 064's release and run
# 087's suite results stand in for the three suites. By hand, one value in each group is changed so its rule must fail:
# a test in the five-switch suite (M1), one held cube's creep to 50 um/s (G1_H1), slide 1's deceleration at the coarse
# step to 4000 mm/s2 (G7_S2_1), setting 1's depth at a quarter of the time constant to 4300 nm (G8_R1_1), setting 3's
# rebound at the finest step to 1100 (G10_R1 lines of setting 3 with k64), and one released arm's reading blanked (P0)
set -eu
R=~/work/dry091; O=~/work/plumb91; rm -rf "$O"; cp -R "$R/validation/run_091_study_21/dry" "$O"
cp ~/work/plumb91src/suite_results_release.txt "$O/suite_results_release.txt"
cp ~/work/plumb91src/suite_results_off.txt "$O/suite_results_off.txt"
awk '$1 == 148 { $3 = "Failed" } { print }' ~/work/plumb91src/suite_results_set5.txt > "$O/suite_results_set5.txt"
awk 'h != 1 && $1 == "v2set" && $2 == "hold" && $6 == 1 { $9 = 50; h = 1 }
     $1 == "v1set" && $2 == "slide" && $3 == 1 && $4 == "0.002" { $6 = 4000 }
     $1 == "rel" && $2 == "rest" && $3 == 1 && $4 == 4 { $6 = 4300 }
     $1 == "rel" && $2 == "drop" && $3 == 3 && $4 == 64 { $6 = 1100 }
     a != 1 && $1 == "rel" && $2 == "arm" { $5 = ""; a = 1 }
     { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
B=~/work/mbuild/sx_contact_new3; ARMS="rel off v1set v2set"; CUBES="a b"
G1DT=0.00114; G7DTS="0.002 0.0005 0.000125 3.125e-05"; G10DT=0.01; G10KS="1 2 4 8 16 32 64"
G7V1=1; G7MU1=0.4; G7V2=1; G7MU2=0.4
G10TC1=0.02; G10DR1=0.2; G10TC2=0.04; G10DR2=0.2; G10TC3=0.02; G10DR3=0.5
frac() { awk -v a="$1" -v k="$2" 'BEGIN { printf "%.10g", a / k }'; }
eval "$(sed -n '/^same_files() {/,$p' "$R/validation/run_091_study_21/play.sh")"
cat "$O/rules.txt"
