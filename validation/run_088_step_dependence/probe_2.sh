#!/usr/bin/env bash
# Run 088, step 2: written after step 1's readings and pushed before its plays. Step 1 found run 001's slide hopping at
# every step, started from the surface or settled, by MuJoCo's default options and by Senua AI's configuration alike
# (while touching, the normal force averages 2.5 to 2.8 times the weight; the friction is 0.4 of it), which is issue 4,
# the hop de Saxce's correction removes in Senua AI's set. This plays step 1's slides again on Study 20's build of Senua
# AI's patch files with the second friction solve (mujoco-s20v2-build), the five switches set, under Senua AI's
# configuration, and reads them as step 1 did, with the highest the cube rises.
# usage: probe_2.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_088_step_dependence"; MJ="$W/mujoco-s20v2-build"
date -u +%FT%TZ > "$O/played_at_2.txt"
X=$(mktemp -d); cp -R "$R/tools" "$X/"
cd "$X" || exit 2
MUJOCO_DIR="$MJ" tools/build_rig.sh mjc_contact > /dev/null
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1
mkdir -p p2; S=p2/stats.txt; : > $S
play() { local f=$1; shift; tools/mjc_contact "p2/$f.txt" "$@" | sed "s|^STATS|STATS run $f|" >> $S; }
win() { awk -v a="$2" -v b="$3" -v w="$4" 'NR == 1 { for (i = 1; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1); next }
  { t = $1 * dt / 1e6; if (t >= a && t <= b && $5 > 0) { n++; sn += $5; sf += ($6 < 0 ? -$6 : $6) / $5 } }
  END { if (n == 0) { print "normal_over_weight_ppm missing friction_over_normal_ppm missing"; exit }
        printf "normal_over_weight_ppm %d friction_over_normal_ppm %d", 1e6 * sn / n / w, 1e6 * sf / n }' "$1"; }
depth() { awk -v a="$2" 'NR == 1 { for (i = 1; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1); next }
  { t = $1 * dt / 1e9; if (t >= a) { n++; s += $2; v = $4 < 0 ? -$4 : $4; if (v > vm) vm = v } }
  END { if (n == 0) { print "depth_nm missing fastest_vz_ums missing"; exit } printf "depth_nm %d fastest_vz_ums %d", s / n, vm }' "$1"; }
highest() { awk 'NR > 1 && (hi == "" || $2 > hi) { hi = $2 } END { printf "highest_nm %d", hi }' "$1"; }
REC="cone=elliptic noslip=100"
{
  for dt in 0.002 0.0005 0.000125 0.00003125; do
    # shellcheck disable=SC2086
    play rest_set_surface_$dt dt=$dt h0=0 mu=0.4 mass=1 radius=0.05 secs=1 $REC
    hs=$(depth "p2/rest_set_surface_$dt.txt" 0.8 | awk '{ printf "%.9f", $2 / 1e9 }')
    echo "rest set $dt from the surface $(depth "p2/rest_set_surface_$dt.txt" 0.8)"
    for st in surface:0 settled_surface:$hs; do
      sn=${st%%:*}; h=${st#*:}
      # shellcheck disable=SC2086
      play slide_set_${sn}_$dt dt=$dt h0=$h vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 $REC
      f=p2/slide_set_${sn}_$dt.txt
      echo "slide set $sn $dt start_h0_m $h | $("$B" accel $f 50 200 | tail -1) | $(win $f 50 200 9800) | $("$B" stop $f | tail -1) | $(highest $f)"
    done
  done
} > "$O/reading_slide_set.txt"
cd "$R" || exit 2
for f in "$X"/p2/*.txt; do [ "$(wc -c < "$f")" -gt 200000 ] && gzip -n "$f"; done
rm -rf "$O/p2"; cp -R "$X/p2" "$O/p2"; rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
