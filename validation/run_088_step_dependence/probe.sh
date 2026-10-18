#!/usr/bin/env bash
# Run 088: a design probe, not registered: it finds where to look and decides nothing. One probe for the three issues
# that move with the step (docs/issues.md 7, 8 and 10), played on Google DeepMind's Linux release of MuJoCo 3.16.0 with
# the one-cube rig, MuJoCo's own options unless a line says otherwise.
#
# Issue 7, sliding friction moves with the step (run 001: 3,880 mm/s2 at 2 ms to 3,957 at 1/64, Coulomb's 3,920). The
# slide started from the plane's surface, so the contact may still have been settling inside the window read (50 to
# 200 ms; the default time constant is 20 ms). Part 1 plays run 001's slide at its four steps from the surface and from
# the depths the same step rests at, set down from the surface and from 20 mm, by MuJoCo's default options and by Senua
# AI's configuration, and reads, over the window, the deceleration, the normal force against the weight and the friction
# against the normal.
#
# Issue 8, the contact softens past its stiffness guard (runs 003, 005, 006: 17 um at rest up to 10 ms, 68 at 20, 269 at
# 40, set down from 20 mm). MuJoCo's guard holds the time constant to at least twice the step. Part 2 plays the rest at 5 to 40 ms by the
# default, with the guard off, and at 1 ms with the time constant the guard gives each step set by hand, and, for time
# constants of 10 and 40 ms, at steps of a sixteenth, a quarter and a half of the time constant and at the time constant.
#
# Issue 10, a bounce depends on the step and can create energy (run 017: under Euler, energy only where the time
# constant times the damping ratio is under the step). MuJoCo's own discrete integrator treats such a spring as one the
# step cannot resolve. Part 3 plays run 017's drop for time constants of 10, 20 and 40 ms, damping ratios 0.5, 0.2 and
# 0.1, at run 017's seven steps, under Euler, for 1 s, and reads each bounce and its deepest point on landing.
#
# Readings: Senua AI's measures (sx_contact accel, stop, bounce), and the rig's own columns averaged over a window.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_088_step_dependence"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
X=$(mktemp -d); cp -R "$R/tools" "$X/"; cp "$O/mjc_contact_before.c" "$X/tools/mjc_contact_before.c"
cd "$X" || exit 2
MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_contact > /dev/null
MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_contact_before > /dev/null
mkdir -p p; S=p/stats.txt; : > $S
play() { local f=$1; shift; tools/mjc_contact "p/$f.txt" "$@" | sed "s|^STATS|STATS run $f|" >> $S; }
# the rig as it was before refsafe= and the rig now, refsafe unset: a slide and a drop, byte for byte
tools/mjc_contact_before p/id_before_slide.txt dt=0.002 h0=0 vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 > /dev/null
tools/mjc_contact p/id_now_slide.txt dt=0.002 h0=0 vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 > /dev/null
tools/mjc_contact_before p/id_before_drop.txt dt=0.005 mass=2 radius=0.04 h0=0.08 secs=1 solref=0.02,0.2 > /dev/null
tools/mjc_contact p/id_now_drop.txt dt=0.005 mass=2 radius=0.04 h0=0.08 secs=1 solref=0.02,0.2 > /dev/null
{ cmp -s p/id_before_slide.txt p/id_now_slide.txt && echo "identity slide: the same bytes" || echo "identity slide: DIFFERENT"
  cmp -s p/id_before_drop.txt p/id_now_drop.txt && echo "identity drop: the same bytes" || echo "identity drop: DIFFERENT"; } > "$O/identity.txt"
# a window of the rig's own columns: mean normal force over the weight, mean friction over the normal (ppm), from ms to ms
win() { awk -v a="$2" -v b="$3" -v w="$4" 'NR == 1 { for (i = 1; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1); next }
  { t = $1 * dt / 1e6; if (t >= a && t <= b && $5 > 0) { n++; sn += $5; sf += ($6 < 0 ? -$6 : $6) / $5 } }
  END { if (n == 0) { print "normal_over_weight_ppm missing friction_over_normal_ppm missing"; exit }
        printf "normal_over_weight_ppm %d friction_over_normal_ppm %d", 1e6 * sn / n / w, 1e6 * sf / n }' "$1"; }
depth() { awk -v a="$2" 'NR == 1 { for (i = 1; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1); next }
  { t = $1 * dt / 1e9; if (t >= a) { n++; s += $2; v = $4 < 0 ? -$4 : $4; if (v > vm) vm = v } }
  END { if (n == 0) { print "depth_nm missing fastest_vz_ums missing"; exit } printf "depth_nm %d fastest_vz_ums %d", s / n, vm }' "$1"; }
lowest() { awk 'NR > 1 && (lo == "" || $2 < lo) { lo = $2 } END { printf "lowest_nm %d", lo }' "$1"; }
REC="cone=elliptic noslip=100"
# ---- part 1: issue 7, the slide
{
  for cfg in default:"" rec:"$REC"; do
    cn=${cfg%%:*}; co=${cfg#*:}
    for dt in 0.002 0.0005 0.000125 0.00003125; do
      # the depth the cube rests at, set down from the surface and from 20 mm (as runs 003 and 005 set it down)
      # shellcheck disable=SC2086
      play rest_${cn}_surface_$dt dt=$dt h0=0 mu=0.4 mass=1 radius=0.05 secs=1 $co
      # shellcheck disable=SC2086
      play rest_${cn}_20mm_$dt dt=$dt h0=0.02 mu=0.4 mass=1 radius=0.05 secs=1 $co
      hs=$(depth "p/rest_${cn}_surface_$dt.txt" 0.8 | awk '{ printf "%.9f", $2 / 1e9 }')
      hd=$(depth "p/rest_${cn}_20mm_$dt.txt" 0.8 | awk '{ printf "%.9f", $2 / 1e9 }')
      echo "rest $cn $dt from the surface $(depth "p/rest_${cn}_surface_$dt.txt" 0.8) | from 20 mm $(depth "p/rest_${cn}_20mm_$dt.txt" 0.8)"
      for st in surface:0 settled_surface:$hs settled_20mm:$hd; do
        sn=${st%%:*}; h=${st#*:}
        # shellcheck disable=SC2086
        play slide_${cn}_${sn}_$dt dt=$dt h0=$h vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 $co
        f=p/slide_${cn}_${sn}_$dt.txt
        echo "slide $cn $sn $dt start_h0_m $h | $("$B" accel $f 50 200 | tail -1) | $(win $f 50 200 9800) | $("$B" stop $f | tail -1)"
      done
    done
  done
} > "$O/reading_slide.txt"
log "part 1 played"
# ---- part 2: issue 8, the rest: set down from 20 mm with friction 0.5, as runs 003 and 005, for 2 s
RS="h0=0.02 mu=0.5 secs=2"
{
  for dt in 0.005 0.01 0.02 0.04; do
    # shellcheck disable=SC2086
    play rest8_default_$dt dt=$dt $RS; echo "rest default $dt | $(depth p/rest8_default_$dt.txt 1.5)"
    play rest8_surface_$dt dt=$dt h0=0 mu=0.5 secs=2; echo "rest default from the surface $dt | $(depth p/rest8_surface_$dt.txt 1.5)"
    # shellcheck disable=SC2086
    play rest8_noguard_$dt dt=$dt $RS refsafe=0; echo "rest guard off $dt | $(depth p/rest8_noguard_$dt.txt 1.5)"
    # shellcheck disable=SC2086
    play rest8_noguard_implicit_$dt dt=$dt $RS refsafe=0 integ=implicit; echo "rest guard off implicit $dt | $(depth p/rest8_noguard_implicit_$dt.txt 1.5)"
    tc=$(awk -v d="$dt" 'BEGIN { t = 2 * d; if (t < 0.02) t = 0.02; printf "%.6g", t }')
    # shellcheck disable=SC2086
    play rest8_fine_tc${tc}_$dt dt=0.001 $RS solref=$tc,1; echo "rest at 1 ms with the time constant the guard gives $dt, $tc | $(depth p/rest8_fine_tc${tc}_$dt.txt 1.5)"
  done
  for tc in 0.01 0.04; do
    for k in 16 4 2 1; do
      dt=$(awk -v t="$tc" -v k="$k" 'BEGIN { printf "%.6g", t / k }')
      # shellcheck disable=SC2086
      play rest8_tc${tc}_k$k dt=$dt $RS solref=$tc,1; echo "rest time constant $tc step 1/$k of it, $dt | $(depth p/rest8_tc${tc}_k$k.txt 1.5)"
    done
  done
} > "$O/reading_rest.txt"
log "part 2 played"
# ---- part 3: issue 10, the bounce
{
  for tc in 0.01 0.02 0.04; do for dr in 0.5 0.2 0.1; do
    for k in 1 2 4 8 16 32 64; do
      dt=$(awk -v k="$k" 'BEGIN { printf "%.6g", 0.01 / k }')
      play drop_tc${tc}_d${dr}_k$k dt=$dt mass=2 radius=0.04 h0=0.08 secs=1 solref=$tc,$dr
      res=$(awk -v t="$tc" -v d="$dr" -v s="$dt" 'BEGIN { print (t * d >= 2 * s) ? "resolved" : "unresolved" }')
      echo "bounce tc $tc damping $dr step $dt $res | $("$B" bounce p/drop_tc${tc}_d${dr}_k$k.txt | tail -1) | $(lowest p/drop_tc${tc}_d${dr}_k$k.txt)"
    done
  done; done
} > "$O/reading_bounce.txt"
log "part 3 played"
cd "$R" || exit 2
for f in "$X"/p/*.txt; do [ "$(wc -c < "$f")" -gt 200000 ] && gzip -n "$f"; done
rm -rf "$O/p"; cp -R "$X/p" "$O/p"; rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
