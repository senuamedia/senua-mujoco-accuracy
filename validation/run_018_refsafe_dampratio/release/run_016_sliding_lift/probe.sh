#!/usr/bin/env bash
# Run 016, design probe (not registered): the lift of a sliding cube against its law. Run 008 found a cube set sliding
# on the ground leaves it while it slides (finding F3, known issue M5): 10.8 mm at 10 ms, rising at close to friction
# times speed. The relaxation of the friction cone that convex contact solvers make (Anitescu 2006; Le Lidec et al.
# 2024, arXiv 2304.06372) lets a sliding contact separate at friction times the sliding speed, so the law to test is:
# the fastest upward speed against mu v, and the highest lift against dt mu v (a contact that acts at a distance of
# about dt mu v, as M5 records). Each play is run 008's slide that ends (a locked cube, 1 kg, half-size 0.05 m, set
# down touching the ground, h0=0, and set sliding), over:
#   grid      friction 0.1, 0.2, 0.4, 0.8; starting speed 0.3, 0.6, 1.2, 2.4 m/s; steps 10 ms, 2.5 ms, 0.625 ms;
#             under MuJoCo's defaults (def) and under the elliptic cone with noslip (ell: cone=elliptic noslip=10)
#   control   condim=1 (no friction at all) at 1.2 m/s, under both: if friction makes the lift, it is gone here
#   impratio  MuJoCo's own option for how hard friction is relative to the normal: 1 (its default), 10 and 100, at
#             friction 0.4 and 1.2 m/s, under both cones (pyramidal with no noslip, elliptic with noslip 10)
# Step 0: with condim unset the rig plays exactly as before: run 008's slide at 10 ms is made again and compared byte
# for byte with suites/2/defaults/stop_1.txt.
# Each play is read by Senua AI's measure: sx_contact hover (while sliding: the highest the lowest face rises above the
# ground, the fastest it moves up) and stop. Beside each line, the law's numbers from the play's own settings: mu v in
# um/s and dt mu v in um.
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_contact built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_016_sliding_lift; W=$O/runs; mkdir -p $W
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
CUBE="mass=1 radius=0.05"
# step 0: the rig as before
tools/mjc_contact $W/identity_stop_1.txt dt="$(dt_of 1)" $CUBE h0=0 secs=1.5 vx0=1.2 mu=0.4 > $W/identity_stats.txt
if cmp -s $W/identity_stop_1.txt suites/2/defaults/stop_1.txt; then echo "SAME run 008 stop_1 made again" > $O/identity.txt
else echo "DIFFERS run 008 stop_1 made again: $(cmp $W/identity_stop_1.txt suites/2/defaults/stop_1.txt)" > $O/identity.txt; fi
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
law() { awk -v m="$1" -v v="$2" -v k="$3" 'BEGIN { printf "mu_v_ums %d dt_mu_v_um %d", m * v * 1e6 + 0.5, 0.01 / k * m * v * 1e6 + 0.5 }'; }
one() {  # one <label> <mu> <v> <k> <settings...>
  local lab="$1" mu="$2" v="$3" k="$4"; shift 4
  local f=$W/${lab}_mu${mu}_v${v}_$k.txt secs
  secs=$(awk -v m="$mu" -v v="$v" 'BEGIN { s = v / (m * 9.8) + 0.5; if (s > 3.5) s = 3.5; printf "%.2f", s }')
  # shellcheck disable=SC2086
  tools/mjc_contact $f dt="$(dt_of "$k")" $CUBE h0=0 secs=$secs vx0=$v mu=$mu "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
  echo "$lab mu $mu v $v 1/$k | $(law "$mu" "$v" "$k") | $("$B" hover $f | tail -1) | $("$B" stop $f | tail -1)" >> $R
}
for cfg in def ell; do
  case $cfg in def) set -- ;; ell) set -- cone=elliptic noslip=10 ;; esac
  for mu in 0.1 0.2 0.4 0.8; do for v in 0.3 0.6 1.2 2.4; do for k in 1 4 16; do one $cfg $mu $v $k "$@"; done; done; done
  for k in 1 4 16; do one ${cfg}_condim1 0.4 1.2 $k "$@" condim=1; done
  for ir in 1 10 100; do for k in 1 4 16; do one ${cfg}_impratio$ir 0.4 1.2 $k "$@" impratio=$ir; done; done
done
date -u +%FT%TZ > $O/finished.txt
