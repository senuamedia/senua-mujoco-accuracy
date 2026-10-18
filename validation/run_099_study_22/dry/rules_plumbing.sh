#!/usr/bin/env bash
# Study 22's rules plumbing check: the rules judged on the dry run's lines in a scratch copy. Study 21's release suite
# results and run 095's (every switch unset, and the six set) stand in for the three suites. By hand, one value in each
# rule group is changed so its rule must fail: a test in the six-switch suite (M1); one released reading blanked (P0);
# a play file of off's group 15 (E1) and of set6's set (N1) given one byte more; held body 2's released gap to 50 um
# (G14_Q1); the second scene after #2430, its gap in set6 to 11 um (G14_C1); held body 3, set6, moved 10,001 nm (G14_C2);
# load 1's gap in set6 at noslip 100 to 600 um (G14_C3_1); the second welded arm in set6 to 11 um/s (G14_R1); one arm of
# Study 15's in set6 to 11 um/s (G14_R2); set6's other plays given one step at the limit (G14_V1_iteration_limit); cup
# 1 as one mesh, released, under the configuration, to 12,000,000 nm (G15_Q1_1_config); cup 2 as convex meshes in set6
# under the defaults to 40,368,000 nm (G15_C1_set6_2_defaults); cup 2's primitives, released, under the configuration,
# to 11 um/s at the end (G15_S1)
# usage: rules_plumbing.sh <the dry run's folder> <scratch folder> <stand-in suites folder> <sx_contact> <play.sh>
set -eu
D=$1; O=$2; SU=$3; B=$4; P=$5
rm -rf "$O"; cp -R "$D" "$O"
cp "$SU/suite_results_release.txt" "$O/suite_results_release.txt"
cp "$SU/suite_results_off.txt" "$O/suite_results_off.txt"
awk '$1 == 148 { $3 = "Failed" } { print }' "$SU/suite_results_set6.txt" > "$O/suite_results_set6.txt"
awk 'a != 1 && $1 == "rel" && $2 == "arm" { $5 = ""; a = 1 }
     $1 == "rel" && $2 == "g14" && $3 == "held" && $4 == 2 && $5 == "n100" { $11 = 50 }
     $1 == "set6" && $2 == "g14" && $3 == "i2430" && $4 == 2 && $5 == "n100" { $11 = 11 }
     $1 == "set6" && $2 == "g14" && $3 == "held" && $4 == 3 && $5 == "n100" { $7 = 10001 }
     $1 == "set6" && $2 == "g14" && $3 == "load" && $4 == 1 && $5 == "n100" { $9 = 600 }
     $1 == "set6" && $2 == "g14" && $3 == "arm" && $4 == "tipweld" && $5 == 2 { $7 = 11 }
     $1 == "set6" && $2 == "arm" && $3 == "s15_drop1_0.00171" { $5 = 11 }
     $1 == "set6" && $2 == "solver_other" { $6 = 1 }
     $1 == "rel" && $2 == "g15" && $4 == 1 && $5 == "one" && $6 == "config" { $8 = 12000000 }
     $1 == "set6" && $2 == "g15" && $4 == 2 && $5 == "mparts" && $6 == "defaults" { $8 = 40368000 }
     $1 == "rel" && $2 == "g15" && $4 == 2 && $5 == "prim" && $6 == "config" { $10 = 11 }
     { print }' "$O/measured.txt" > "$O/m.txt" && mv "$O/m.txt" "$O/measured.txt"
f=$(cd "$O/off/g15" && ls | grep -v stats | head -1); printf 'x' >> "$O/off/g15/$f"
f=$(cd "$O/set6/sets" && ls | grep -v stats | head -1); printf 'x' >> "$O/set6/sets/$f"
ARMS="rel off set5 set6"
eval "$(sed -n '/^same_files() {/,$p' "$P")"
cat "$O/rules.txt"
