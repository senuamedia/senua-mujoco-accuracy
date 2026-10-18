#!/usr/bin/env bash
# Run 015: the second registered study (preregistrations/PREREGISTRATION_02.md), played once. Two arms on Google
# DeepMind's Linux release: released (MuJoCo's defaults) and recommended (cone=elliptic noslip=10). Each plays the
# registered holds and slides and the first deep dive's suite 1 on the registered cube; every rule is judged by
# sx_contact rule. DRY=1 plays throwaway parameters on the released arm only, into dry/; no rule is read from it.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh>   (repository root, rigs built)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact> <runner folder>}")" && pwd)/$(basename "$1")"
M="$(cd "${2:?runner folder}" && pwd)"
O=validation/run_015_study_02
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS=released; CUBE="mass=1 radius=0.05"; MU=0.5; LIM=4.9; V=1
else
  OUT=$O; ARMS="released recommended"; CUBE="mass=1.6 radius=0.045"; MU=0.45; LIM=7.056; V=1.1
  export SUITE_CUBE="mass=1.6 radius=0.045" SUITE_H0=0.09 SUITE_VX=3 SUITE_VXCHAIN=1.2 SUITE_MU=0.45 SUITE_VSLIDE=4 \
    SUITE_MUHOLD=0.4 SUITE_HOLD=3.7632 SUITE_SLIP=7.5264 SUITE_LIFT=47.04
fi
mkdir -p $OUT
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M2=$OUT/measured.txt; : > $M2
for a in $ARMS; do
  cfg=""; [ $a = recommended ] && cfg="cone=elliptic noslip=10"
  W=$OUT/$a/runs; mkdir -p $W; S=$OUT/$a/stats.txt; : > $S
  for dt in 0.002 0.0005; do
    for dir in 0 30 60; do
      for fr in 0.5 0.75 0.95; do
        p=$(awk -v f=$fr -v l=$LIM 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        tools/mjc_contact $W/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 mu=$MU $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $cfg >> $S
        echo "$a hold $dir $fr $dt creep_ums $("$B" creep $W/hold_${dir}_${fr}_$dt.txt | tail -1 | pick mean_speed_ums)" >> $M2
      done
      # shellcheck disable=SC2086
      tools/mjc_contact $W/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=1.2 dir=$dir $cfg >> $S
      echo "$a slide $dir $dt slid_um $("$B" stop $W/slide_${dir}_$dt.txt | tail -1 | pick slid_um)" >> $M2
    done
  done
  # shellcheck disable=SC2086
  tools/contact_suite.sh s15_$a $cfg > /dev/null
  SUITE_MU10K=4500 SUITE_SLIPMN=7526 bash "$M/sx_contact_suite.sh" suites/1/s15_$a $OUT/$a/suite1.txt > /dev/null 2>&1
  mkdir -p $OUT/$a/suite1_plays && cp suites/1/s15_$a/* $OUT/$a/suite1_plays/
  passed=$(grep '^SUITE passed' $OUT/$a/suite1.txt | awk '{ print $3 }')
  t06=$(grep '^T06' $OUT/$a/suite1.txt | grep -c ': FAIL$')
  most=$(cat $S suites/1/s15_$a/stats.txt | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > m) m = $2 } END { print m + 0 }')
  lim=$(cat $S suites/1/s15_$a/stats.txt | grep -o 'at_iteration_limit [0-9]*' | awk '{ n += $2 } END { print n + 0 }')
  warn=$(cat $S suites/1/s15_$a/stats.txt | grep -o 'warnings [0-9]*' | awk '{ n += $2 } END { print n + 0 }')
  echo "$a suite passed ${passed:-none} t06_failed $t06 most_iterations $most at_iteration_limit $lim warnings $warn" >> $M2
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M2) measured lines"; exit 0; }
get() { grep "^$1 " $M2 | pick "$2"; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
rule R1_released_creeps ge $(get "released hold 0 0.5 0.002" creep_ums) 100
rule R1_released_direction share $(get "released slide 0 0.002" slid_um) $(get "released slide 30 0.002" slid_um) 100 115
rule R2_every_hold_holds all_le 10 $(grep '^recommended hold ' $M2 | awk '{ for (i = 1; i < NF; i++) if ($i == "creep_ums") print $(i + 1) }' | sed 's/^-//')
for dt in 0.002 0.0005; do
  rule R3_no_direction_$dt all_within $(get "recommended slide 0 $dt" slid_um) 10000 $(get "recommended slide 30 $dt" slid_um) $(get "recommended slide 60 $dt" slid_um)
done
rule R4_coulomb all_within 137188 100 $(for dir in 0 30 60; do get "recommended slide $dir 0.0005" slid_um; done)
rule R5_ten_tests eq $(get "recommended suite" passed) 10
rule R5_released_hold_fails eq $(get "released suite" t06_failed) 1
rule R6_iteration_limit eq $(get "recommended suite" at_iteration_limit) 0
rule R6_warnings eq $(get "recommended suite" warnings) 0
rule R6_most_iterations le_plus $(get "recommended suite" most_iterations) $(get "released suite" most_iterations) 3
echo "rules: $(wc -l < $R), held: $(grep -c ': HELD$' $R)" | tee -a $R
