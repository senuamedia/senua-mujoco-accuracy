#!/usr/bin/env bash
# Run 012: the first registered study (preregistrations/PREREGISTRATION_01.md), played once. Three arms, each in its
# own scratch copy of the repository, the rigs built against:
#   stock   Google DeepMind's Linux release of MuJoCo 3.16.0
#   off     MuJoCo built from source with patches/in_design/slip_aligned_pyramid.diff, switch unset
#   on      the same, MUJOCO_SLIP_ALIGNED_PYRAMID=1
# Each plays the registered scenes and both of the first deep dive's contact suites; then every registered rule is
# judged by sx_contact rule. DRY=1 plays the registration's throwaway parameters on the stock arm only, into dry/, to
# check that the runner runs to the end; no rule is read from it.
# usage: play.sh <sx_contact binary>   (repository root; RELEASE and PATCHED set to the two MuJoCo install folders)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_012_study_01; ROOT=$(pwd)
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; CUBE="mass=1 radius=0.05"; MU=0.4; V=1; P65=3.185; P85=4.165; ARMS="stock"
else
  OUT=$O; CUBE="mass=1.4 radius=0.04"; MU=0.35; V=0.8; P65=3.1213; P85=4.0817; ARMS="stock off on"
fi
mkdir -p $OUT
play_arm() {  # in a scratch copy: every registered play, each STATS line kept in its own file
  local r=runs s=stats
  mkdir -p $r $s
  for dt in 0.001 0.00025; do
    for dir in 0 15 30 60 75; do
      tools/mjc_contact $r/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=1.2 dir=$dir > $s/slide_${dir}_$dt.txt
    done
  done
  for dir in 0 30 60; do
    tools/mjc_contact $r/hold_${dir}_0.65.txt dt=0.001 h0=0 mu=$MU $CUBE push=$P65 pushat=0.4 secs=1.6 dir=$dir > $s/hold_${dir}_0.65.txt
    tools/mjc_contact $r/hold_${dir}_0.85.txt dt=0.001 h0=0 mu=$MU $CUBE push=$P85 pushat=0.4 secs=1.6 dir=$dir > $s/hold_${dir}_0.85.txt
    tools/mjc_contact $r/free_${dir}.txt dt=0.001 h0=0 vx0=$V mu=$MU $CUBE secs=1.2 lock=0 dir=$dir > $s/free_${dir}.txt
  done
  tools/contact_suite.sh defaults > /dev/null
  tools/contact_suite2.sh defaults > /dev/null
}
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && for n in mjc_contact mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
   if [ -n "$sw" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$sw; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
   play_arm)
  rm -rf $ROOT/$OUT/$name; mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $X/suites $ROOT/$OUT/$name/; rm -rf $X
}
for a in $ARMS; do
  case $a in stock) arm stock "$RELEASE";; off) arm off "$PATCHED";; on) arm on "$PATCHED" 1;; esac
done
# ---- measuring: every number a rule reads, each from Senua AI's measuring program or the rig's own STATS line
field() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' "$1"; }
slid() { "$B" stop "$1" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "slid_um") print $(i + 1) }'; }
creep() { "$B" creep "$1" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $(i + 1) }'; }
abs() { local x=$1; echo "${x#-}"; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  d=$OUT/$a
  for dt in 0.001 0.00025; do for dir in 0 15 30 60 75; do
    echo "$a slide $dir $dt slid_um $(slid $d/runs/slide_${dir}_$dt.txt) side_um $(field $d/stats/slide_${dir}_$dt.txt side_um)" >> $M
  done; done
  for dir in 0 30 60; do
    for fr in 0.65 0.85; do echo "$a hold $dir $fr creep_ums $(creep $d/runs/hold_${dir}_$fr.txt)" >> $M; done
    echo "$a free $dir 0.001 slid_um $(slid $d/runs/free_$dir.txt) side_um $(field $d/stats/free_$dir.txt side_um)" >> $M
  done
  most=0; lim=0; warn=0
  for f in $d/stats/*.txt $d/suites/*/defaults/stats.txt; do
    while read -r line; do
      x=$(echo "$line" | awk '{ for (i = 1; i < NF; i++) if ($i == "most_iterations") print $(i + 1) }'); [ -n "$x" ] && [ "$x" -gt "$most" ] && most=$x
      x=$(echo "$line" | awk '{ for (i = 1; i < NF; i++) if ($i == "at_iteration_limit") print $(i + 1) }'); [ -n "$x" ] && lim=$((lim + x))
      x=$(echo "$line" | awk '{ for (i = 1; i < NF; i++) if ($i == "warnings") print $(i + 1) }'); [ -n "$x" ] && warn=$((warn + x))
    done < "$f"
  done
  echo "$a solver most_iterations $most at_iteration_limit $lim warnings $warn" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M) measured lines"; exit 0; }
get() { grep "^$1 " $M | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
# ---- the rules, each judged by sx_contact rule
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
n=0; same=0; for f in $(cd $OUT/stock && find runs stats suites -type f | sort); do n=$((n + 1)); cmp -s $OUT/stock/$f $OUT/off/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
s0=$(get "stock slide 0 0.001" slid_um)
rule R2_stock_direction_30 share $s0 $(get "stock slide 30 0.001" slid_um) 100 115
rule R2_stock_direction_60 share $s0 $(get "stock slide 60 0.001" slid_um) 100 115
for dt in 0.001 0.00025; do
  rule R3_no_direction_$dt all_within $(get "on slide 0 $dt" slid_um) 10000 $(for dir in 15 30 60 75; do get "on slide $dir $dt" slid_um; done)
  rule R4_no_drift_$dt all_le 10 $(for dir in 0 15 30 60 75; do abs $(get "on slide $dir $dt" side_um); done)
done
rule R5_coulomb all_within 93295 100 $(for dir in 0 15 30 60 75; do get "on slide $dir 0.00025" slid_um; done)
for fr in 0.65 0.85; do
  rule R6_no_direction_hold_$fr all_within $(get "on hold 0 $fr" creep_ums) 100 $(get "on hold 30 $fr" creep_ums) $(get "on hold 60 $fr" creep_ums)
done
rule R7_stock_hold_lets_go share $(get "stock hold 0 0.85" creep_ums) $(get "stock hold 30 0.85" creep_ums) 1 10
rule R8_free_cube all_within $(get "on free 0 0.001" slid_um) 100 $(get "on free 30 0.001" slid_um) $(get "on free 60 0.001" slid_um)
rule R8_free_cube_drift all_le 1000 $(abs $(get "on free 30 0.001" side_um)) $(abs $(get "on free 60 0.001" side_um))
n=0; same=0; for f in $(cd $OUT/stock && find suites -type f | sort); do n=$((n + 1)); cmp -s $OUT/stock/$f $OUT/on/$f && same=$((same + 1)); done
rule R9_nothing_else eq $same $n
rule R10_iteration_limit eq $(get "on solver" at_iteration_limit) 0
rule R10_warnings eq $(get "on solver" warnings) 0
rule R10_most_iterations le_plus $(get "on solver" most_iterations) $(get "stock solver" most_iterations) 2
echo "rules: $(wc -l < $R), held: $(grep -c ': HELD$' $R)" | tee -a $R
