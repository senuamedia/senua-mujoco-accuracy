#!/usr/bin/env bash
# rules_changed.sh <sx_contact> <dry/> <rules_plumbing.sh>: the rules judged on a scratch copy of the dry run, first as
# it is, then with one value in each rule group changed by hand so that its rule must fail, and two play files given
# one byte more; the two judgements are kept as rules_plumbing_unchanged.txt and rules_plumbing_changed.txt
set -eu
B=$1; D="$(cd "$2" && pwd)"; P=$3
T=$(mktemp -d); cp -R "$D" "$T/c"
bash "$P" "$B" "$T/c"; cp "$T/c/rules_plumbing.txt" "$D/rules_plumbing_unchanged.txt"
M="$T/c/measured.txt"
chg() {  # <line prefix> <key> <new value>: that value on the first line with the prefix
  awk -v p="$1" -v k="$2" -v v="$3" 'BEGIN { done = 0 } { if (!done && index($0, p) == 1) { for (i = 1; i < NF; i++) if ($i == k) { $(i + 1) = v; done = 1; break } } print }' "$M" > "$M.new"
  mv "$M.new" "$M"
}
one_more() { if [ -f "$1" ]; then printf 'x' >> "$1"; else printf 'x' >> "$1.gz"; fi; }
one_more "$T/c/before_set/sets/s15_rest1_0.00171.txt"                    # E1
chg "set slide 0 0.002 " expected_um x                                   # P0
awk '{ if ($1 == "set" && $2 == "g1" && $6 == 0 && $7 == 0.95) { for (i = 1; i < NF; i++) if ($i == "creep_ums") $(i + 1) = 0 } print }' "$M" > "$M.new"; mv "$M.new" "$M"   # G1 Q1
chg "hold g1 a 3 " creep_ums 11                                          # G1 C1
chg "set g9 straight 10 0.0015 1 " depth_nm 99999                        # G9 Q1
chg "set g9 offset 3 0.0015 2 " lean_urad 1999                           # G9 Q2
chg "hold g9 straight 10 0.0015 2 " depth_nm 100001                      # G9 D, hold
chg "inverse g9 offset 3 0.0015 3 " lean_urad 1001                       # G9 L, inverse
chg "hold g9 offset 1 0.0015 1 " turn_urads 11                           # G9 T, hold
chg "inverse g1 b 6 " fwdinv_nn 1000001                                  # G14 I1
chg "inverse g14 held 1 " held_nm 2000                                   # G14 L1, held 1
chg "inverse g14 held 2 " gap_um 11                                      # G14 C1
chg "inverse g14 load 1 " gap_um 600                                     # G14 C3, load 1
chg "inverse g14 jf 2 0.00171 " creep_ums 11                             # G14 R1
one_more "$T/c/hold/g14/held_1_held.txt"                                 # G14 N1
chg "inverse solver_other " at_iteration_limit 1                         # G14 V1, the iteration limit
chg "hold slide 0 0.002 " slid_um 381180                                 # S K, hold, slide 0 at 2 ms
chg "inverse box box_mujoco " fastest_ums 11                             # S B, inverse
chg "hold solver_eq " warnings 1                                         # V2, hold, warnings
bash "$P" "$B" "$T/c"; cp "$T/c/rules_plumbing.txt" "$D/rules_plumbing_changed.txt"
rm -rf "${T:?}"
