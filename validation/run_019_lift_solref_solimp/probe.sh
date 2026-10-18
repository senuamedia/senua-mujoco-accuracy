#!/usr/bin/env bash
# Run 019, design probe (not registered): the sliding lift (finding F3, known issue M5) under MuJoCo's own contact
# reference and impedance, solref and solimp, the options run 016 did not try. Only values MuJoCo's documentation gives
# are played (modeling.rst of 3.16.0), nothing swept or fitted:
#   def      MuJoCo's defaults: solref "0.02 1", solimp "0.9 0.95 0.001 0.5 2"
#   ref      solref "0.01 1", the documentation's contact example (a time constant of 0.01 s; MuJoCo's stiffness guard
#            raises it to twice the step where the step is longer than 5 ms)
#   imp      solimp ".95 .99 .0001", the same example's impedance
#   both     the example's solref and solimp together, as the documentation writes its contact
#   d0       solimp "0 0.95 0.001 0.5 2": the documentation's advice for smooth dynamics, solimp[0] = 0
#   direct   solref "-1000 0", the documentation's example in the direct format, stiffness 1000 and no damping (its
#            bouncing sphere)
# Each plays a subset of run 016's slides (a 1 kg cube, half-size 0.05 m, that cannot turn, set down touching the ground
# and set sliding), under MuJoCo's default cone and integrator: friction 0.4 at 0.6, 1.2 and 2.4 m/s, and friction 0.1
# and 0.8 at 1.2 m/s, at 10 ms, 2.5 ms and 0.625 ms. Step 0: the def arm, with solref and solimp unset, is played as run
# 016 played it, and each of its 15 files is compared byte for byte with run 016's.
# Each play is read by Senua AI's measure: sx_contact hover (while sliding: the highest the lowest face rises above the
# ground, the fastest it moves up, the deepest it sinks) and stop (how far it slid; Coulomb's distance is v^2 / (2 mu g)).
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_contact built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_019_lift_solref_solimp; W=$O/runs; mkdir -p $W
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
CUBE="mass=1 radius=0.05"
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
one() {  # one <arm> <mu> <v> <k> <settings...>: the play exactly as run 016's probe makes it, plus the arm's settings
  local arm="$1" mu="$2" v="$3" k="$4"; shift 4
  local f=$W/${arm}_mu${mu}_v${v}_$k.txt secs
  secs=$(awk -v m="$mu" -v v="$v" 'BEGIN { s = v / (m * 9.8) + 0.5; if (s > 3.5) s = 3.5; printf "%.2f", s }')
  # shellcheck disable=SC2086
  tools/mjc_contact $f dt="$(dt_of "$k")" $CUBE h0=0 secs=$secs vx0=$v mu=$mu "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
  echo "$arm mu $mu v $v 1/$k | $("$B" hover $f | tail -1) | $("$B" stop $f | tail -1)" >> $R
}
for arm in def ref imp both d0 direct; do
  case $arm in
    def) set -- ;;
    ref) set -- solref=0.01,1 ;;
    imp) set -- solimp=.95,.99,.0001 ;;
    both) set -- solref=0.01,1 solimp=.95,.99,.0001 ;;
    d0) set -- solimp=0,0.95,0.001,0.5,2 ;;
    direct) set -- solref=-1000,0 ;;
  esac
  for k in 1 4 16; do
    for v in 0.6 1.2 2.4; do one $arm 0.4 $v $k "$@"; done
    for mu in 0.1 0.8; do one $arm $mu 1.2 $k "$@"; done
  done
done
# step 0: the def arm against run 016's files
for f in $W/def_*.txt; do
  g=validation/run_016_sliding_lift/runs/$(basename $f)
  if cmp -s $f $g; then echo "SAME $(basename $f)"; else echo "DIFFERS $(basename $f)"; fi
done > $O/identity.txt
date -u +%FT%TZ > $O/finished.txt
