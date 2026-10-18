#!/usr/bin/env bash
# Run 046: a design probe of a patch in design for findings F3 (a sliding body leaves the surface) and F12 (a free cube's
# direction under the elliptic cone, run 045: a consequence of F3). Not registered: it finds where to look and decides
# nothing. The patch, patches/in_design/desaxce_elliptic.diff (switch MUJOCO_DESAXCE=K), applies de Saxce's correction
# to MuJoCo's elliptic cone as a fixed point inside each step: each elliptic contact's normal reference shifted by the
# scaled norm of its tangential residual at the current solution, and the constraint problem solved again, K times.
# Arms: rel, MuJoCo 3.16.0 as released; off, the patched build with the switch unset; on1, on2, on4, the switch at 1, 2
# and 4 passes. Every arm under Senua AI's configuration (the elliptic cone with 10 noslip iterations), and the slides
# also under the elliptic cone alone. Plays:
#   lift: run 016's cube that cannot turn (1 kg, half-size 0.05 m, friction 0.4) set sliding at 1.2 m/s, at 10, 2.5 and
#     0.625 ms; and Study 10's cube (1.861 kg, 0.0434 m, friction 0.39, 1.01 m/s), kept from turning, at 1.14 and
#     0.285 ms; with no friction too (condim 1), the control
#   free: Study 10's cube free to turn, along 0, 11.25, 22.5, 33.75 and 45 degrees at 1.14 and 0.285 ms (traced)
#   hold: Study 10's cube held with 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 at 1.14 ms
#   grip: Study 10's grip (0.202 kg, 0.0312 m, friction 0.772, squeeze 2.48 N), box and mesh pads, centred and 9.3 mm off
# Readings: Senua AI's measure (sx_contact hover, stop, creep) and the rig's STATS fields; off against rel by cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at the record's upstream commit and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_046_desaxce"; REL="$W/mujoco-3.16.0"; PF="$R/patches/in_design/desaxce_elliptic.diff"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
rm -rf "${W:?}/mujoco-p46-src" "$W/p46-lib" "$W/mujoco-p46-build" && mkdir -p "$W/mujoco-p46-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p46-src"
(cd "$W/mujoco-p46-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p46-src" -B "$W/p46-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$W/mujoco-p46-build" && cmake --build "$W/p46-lib" -j"$J" && cmake --install "$W/p46-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
REC="cone=elliptic noslip=10"; CUBE="mass=1.861 radius=0.0434 mu=0.39"; LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
for arm in rel: off: on1:1 on2:2 on4:4; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj="$W/mujoco-p46-build" ;; esac
  X="$W/p46$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/" && (cd "$X" && for n in mjc_contact mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done)
  if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
  F="$O/$a"; mkdir -p "$F"; : > "$F/stats.txt"
  for cfg in rec:"$REC" ell:"cone=elliptic"; do
    c=${cfg%%:*}; opts=${cfg#*:}
    for dt in 0.01 0.0025 0.000625; do
      for fr in fric: nofric:"condim=1"; do
        f=${fr%%:*}; fo=${fr#*:}
        # shellcheck disable=SC2086
        "$X/tools/mjc_contact" "$F/lift16_${c}_${f}_$dt.txt" dt=$dt h0=0 vx0=1.2 mu=0.4 mass=1 radius=0.05 secs=1 lock=1 $opts $fo trace="$F/lift16_${c}_${f}_$dt.trace" | sed "s|^STATS|STATS run lift16_${c}_${f}_$dt|" >> "$F/stats.txt"
      done
    done
    for dt in 0.00114 0.000285; do
      # shellcheck disable=SC2086
      "$X/tools/mjc_contact" "$F/lift10_${c}_$dt.txt" dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=1 $opts trace="$F/lift10_${c}_$dt.trace" | sed "s|^STATS|STATS run lift10_${c}_$dt|" >> "$F/stats.txt"
      for dir in 0 11.25 22.5 33.75 45; do
        # shellcheck disable=SC2086
        "$X/tools/mjc_contact" "$F/free_${c}_${dir}_$dt.txt" dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $opts trace="$F/free_${c}_${dir}_$dt.trace" | sed "s|^STATS|STATS run free_${c}_${dir}_$dt|" >> "$F/stats.txt"
      done
    done
  done
  for dir in 0 22.5 45; do for fr in 0.5 0.75 0.95; do
    p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$F/hold_${dir}_$fr.txt" dt=0.00114 h0=0 $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $REC | sed "s|^STATS|STATS run hold_${dir}_$fr|" >> "$F/stats.txt"
  done; done
  for off in 0 0.0093; do for pad in box mesh; do
    # shellcheck disable=SC2086
    "$X/tools/mjc_grip" "$F/grip_${pad}_off$off" dt=0.00114 offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off$off|" >> "$F/stats.txt"
  done; done
  rm -rf "$X"; unset MUJOCO_DESAXCE
  log "$a played"
done
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
air() { awk 'NR > 1 && $4 == 0 { z++ } NR > 1 { n++ } END { printf "%d of %d", z, n }' "$1"; }
{
  for a in rel off on1 on2 on4; do
    F="$O/$a"
    for c in rec ell; do
      for dt in 0.01 0.0025 0.000625; do for f in fric nofric; do
        n="lift16_${c}_${f}_$dt"; s=$(grep "^STATS run $n " "$F/stats.txt")
        echo "$a $n highest_um $(fld "$("$B" hover "$F/$n.txt" | tail -1)" highest_um) slid_um $(fld "$("$B" stop "$F/$n.txt" | tail -1)" slid_um) steps_without_contact $(air "$F/$n.trace") most_iterations $(fld "$s" most_iterations) warnings $(fld "$s" warnings)"
      done; done
      for dt in 0.00114 0.000285; do
        n="lift10_${c}_$dt"; s=$(grep "^STATS run $n " "$F/stats.txt")
        echo "$a $n highest_um $(fld "$("$B" hover "$F/$n.txt" | tail -1)" highest_um) slid_um $(fld "$("$B" stop "$F/$n.txt" | tail -1)" slid_um) steps_without_contact $(air "$F/$n.trace") most_iterations $(fld "$s" most_iterations) warnings $(fld "$s" warnings)"
        for dir in 0 11.25 22.5 33.75 45; do
          n="free_${c}_${dir}_$dt"; s=$(grep "^STATS run $n " "$F/stats.txt")
          echo "$a $n slid_um $(fld "$("$B" stop "$F/$n.txt" | tail -1)" slid_um) highest_um $(fld "$("$B" hover "$F/$n.txt" | tail -1)" highest_um) side_um $(fld "$s" side_um) most_tilt_urad $(fld "$s" most_tilt_urad) steps_under_4_contacts $(fld "$s" steps_under_4_contacts) most_iterations $(fld "$s" most_iterations) warnings $(fld "$s" warnings)"
        done
      done
    done
    for dir in 0 22.5 45; do for fr in 0.5 0.75 0.95; do
      echo "$a hold_${dir}_$fr creep_ums $(fld "$("$B" creep "$F/hold_${dir}_$fr.txt" | tail -1)" mean_speed_ums)"
    done; done
    for g in "$F"/grip_*.txt; do
      case $g in *_tilt.txt) continue ;; esac
      echo "$a $(basename "$g" .txt) creep_ums $(fld "$("$B" creep "$g" | tail -1)" mean_speed_ums)"
    done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$F/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$F/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$F/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  n=0; s=0; for f in $(cd "$O/rel" && ls *.txt | grep -v stats.txt); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); done
  echo "safe_when_off files_same $s of $n"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
