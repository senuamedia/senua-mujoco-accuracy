#!/usr/bin/env bash
# rules_plumbing.sh <sx_contact> <a copy of dry/>: the runner's rules section, word for word (play.sh from same_files()
# to the rules count), judged on a copy of the dry run's folder, so that values changed by hand show which rules fail
set -u
B="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; O="$(cd "$2" && pwd)"; ARMS="set hold inverse"; SC="$O/scenes"; DRY=1
same_files() {  # <folder a> <folder b> <exclude pattern> <subfolders...>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 x=$3 n=0 s=0 f; shift 3
  for f in $(cd "$a" && find "$@" -type f ! -name stats.txt | grep -vE "$x" | sort); do n=$((n + 1)); cmp -s "$a/$f" "$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
vals() { grep "^$1 $2 " "$O/measured.txt" | awk -v k="$3" '{ for (i = 1; i < NF; i++) if ($i == k) print $(i + 1) }'; }
# ---- the rules, each judged by sx_contact rule
RF="$O/rules.txt"; [ "${DRY:-0}" = 1 ] && RF="$O/rules_plumbing.txt"
{
  rule() { "$B" rule "$@" < /dev/null | tail -1; }
  # shellcheck disable=SC2046
  rule E1_rigs_as_before eq $(same_files "$O/before_set" "$O/set" '^$' sets)
  # shellcheck disable=SC2046
  rule P0_every_play_measured all_eq 339 $(for a in $ARMS; do grep "^$a " "$O/measured.txt" | grep -v " solver_" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^(creep_ums|fwdinv_nn|lean_urad|turn_urads|depth_nm|held_nm|coupled_nm|gap_um|fastest_ums|slid_um|expected_um)$/) { if ($(i + 1) ~ /^-?[0-9]+$/) n++ } } END { print n + 0 }'; done)
  # group 1
  # shellcheck disable=SC2046
  rule G1_Q1_the_free_cube_creeps_in_the_set ge "$(grep "^set g1 " "$O/measured.txt" | awk '$6 == 0 && $7 == 0.95' | awk '{ for (i = 1; i < NF; i++) if ($i == "creep_ums") print $(i + 1) }' | sort -n | tail -1)" 10
  # shellcheck disable=SC2046
  rule G1_C1_hold_every_free_cube_holds all_le 10 $(vals hold g1 creep_ums)
  # shellcheck disable=SC2046
  rule G1_C2_inverse_every_free_cube_holds all_le 10 $(vals inverse g1 creep_ums)
  # group 9
  # shellcheck disable=SC2046
  rule G9_Q1_the_set_sinks all_ge 100000 $(grep "^set g9 straight 10 " "$O/measured.txt" | awk '{ for (i = 1; i < NF; i++) if ($i == "depth_nm") print $(i + 1) }')
  # shellcheck disable=SC2046
  rule G9_Q2_the_set_leans all_ge 2000 $(grep "^set g9 offset 3 " "$O/measured.txt" | awk '$6 != 1' | awk '{ for (i = 1; i < NF; i++) if ($i == "lean_urad") print $(i + 1) }')
  for a in hold inverse; do
    # shellcheck disable=SC2046
    rule "G9_D_${a}_every_contact_within_100_um" all_le 100000 $(vals $a "g9 straight" depth_nm)
    # shellcheck disable=SC2046
    rule "G9_L_${a}_every_lean_within_1_mrad" all_le 1000 $(vals $a "g9 offset" lean_urad)
    # shellcheck disable=SC2046
    rule "G9_T_${a}_every_offset_stack_at_rest" all_le 10 $(vals $a "g9 offset" turn_urads)
  done
  # group 14
  # shellcheck disable=SC2046
  rule G14_I1_inverse_dynamics_agrees all_le 1000000 $(vals inverse g1 fwdinv_nn) $(vals inverse g14 fwdinv_nn)
  while read -r sn exp; do
    rule "G14_L1_soft_friction_law_$sn" all_within "$exp" 100 "$(get "inverse g14 ${sn%_*} ${sn#*_}" held_nm)"
  done < "$SC/law.txt"
  # shellcheck disable=SC2046
  rule G14_C1_inverse_coupling_kept all_le 10 $(vals inverse "g14 held" gap_um)
  # shellcheck disable=SC2046
  rule G14_C2_inverse_held_body_held all_le 10000 $(vals inverse "g14 held" held_nm)
  for i in 1 2; do
    rule "G14_C3_inverse_load_as_the_set_$i" all_within "$(get "set g14 load $i" gap_um)" 100 "$(get "inverse g14 load $i" gap_um)"
  done
  # shellcheck disable=SC2046
  rule G14_R1_inverse_held_arms_rest all_le 10 $(vals inverse "g14 arm" creep_ums) $(vals inverse "g14 jf" creep_ums)
  # shellcheck disable=SC2046
  rule G14_N1_hold_nothing_without_a_contact_changes eq $(same_files "$O/set" "$O/hold" '^$' g14)
  rule G14_V1_inverse_iteration_limit eq "$(( $(get "inverse solver_eq" at_iteration_limit) + $(get "inverse solver_other" at_iteration_limit) ))" 0
  rule G14_V1_inverse_warnings eq "$(( $(get "inverse solver_eq" warnings) + $(get "inverse solver_other" warnings) ))" 0
  # the set's own plays
  for a in hold inverse; do
    # shellcheck disable=SC2046
    rule "S_R_${a}_every_arm_rests" all_le 10 $(vals $a arm creep_ums)
    # shellcheck disable=SC2046
    rule "S_G_${a}_every_grip_holds" all_le 10 $(vals $a grip creep_ums)
    # shellcheck disable=SC2046
    rule "S_H_${a}_every_hold_holds" all_le 10 $(vals $a hold creep_ums)
    # shellcheck disable=SC2046
    rule "S_B_${a}_every_box_rests" all_le 10 $(vals $a box fastest_ums)
    while read -r dt ex; do for dir in 0 22.5 45; do
      rule "S_K_${a}_slide_${dir}_$dt" near "$(get "$a slide $dir $dt" slid_um)" "$ex" 10
    done; done < "$SC/slide_expected.txt"
  done
  rule V2_hold_iteration_limit_without_an_equality eq "$(get "hold solver_other" at_iteration_limit)" 0
  rule V2_hold_warnings eq "$(( $(get "hold solver_eq" warnings) + $(get "hold solver_other" warnings) ))" 0
  for a in set hold; do
    echo "reported: $a, the largest forward-inverse difference, nN: $(vals $a g1 fwdinv_nn | sort -n | tail -1) (free cubes), $(vals $a g14 fwdinv_nn | sort -n | tail -1) (group 14)"
  done
  grep "^inverse g14 i2430 \|^set g14 i2430 " "$O/measured.txt" | sed 's/^/reported: /'
  grep "^set g9 offset " "$O/measured.txt" | sed 's/^/reported: /'
  grep "^set slide " "$O/measured.txt" | sed 's/^/reported: /'
  grep " solver_" "$O/measured.txt" | sed 's/^/reported: /'
} > "$RF"
echo "rules: $(grep -c '^RULE' "$RF"), held: $(grep -c ': HELD$' "$RF")" >> "$RF"
