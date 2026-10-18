#!/usr/bin/env bash
# Run 050: a design probe, not registered: it finds where to look and decides nothing. Three questions, on the release
# (MuJoCo 3.16.0 as released) and on the de Saxce patch's fourth version with its switch set (MUJOCO_DESAXCE=1):
#   1. Finding F14 (issue 21): under Senua AI's configuration at 0.285 ms, straight stacks of 5 and 9 cubes tilt and
#      keep moving (run 049). Which part of the configuration, and which step, does it follow? The stacks on Study 10's
#      numbers under the configuration, the elliptic cone alone, the pyramidal cone with noslip, MuJoCo's defaults,
#      more noslip iterations, a solver run to a tighter tolerance, cubes that cannot turn, the implicitfast
#      integrator, and the configuration at steps from 0.1425 to 1.14 ms.
#   2. Finding F13 (issue 20): MuJoCo's DiscreteImplicitRowNoslip scene never comes to rest (run 049, step 2). Does the
#      cycle follow the noslip iterations, the impratio, the rolling friction (condim 4 in place of 6) or the cone, and
#      does it last? The scene as written and with each changed, played 1,000 steps (5 times the test's 200).
#   3. The fourth version's known limits, asked before Study 12: the pyramidal cone (the patch acts on elliptic
#      contacts only, so the plays should be byte for byte as released), a bounce (run 017's drop at the step ladder,
#      under the configuration, and with a damping ratio of 0.1), and the free cube under RK4 and implicitfast.
# Plays under the configuration (the elliptic cone with 10 noslip iterations) unless a play names another option set.
# Readings: Senua AI's measures (sx_contact hover, stop, bounce), file comparison by cmp, the rigs' STATS fields, and
# for the stacks and the scene the rigs' own columns, read by the awk lines below.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_050_stacks_box_and_limits"; REL="$W/mujoco-3.16.0"; V4="$W/mujoco-p50v4-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
# the fourth version, built from its patch file on MuJoCo's source at UPSTREAM_COMMIT (no tests)
PF="$R/patches/in_design/desaxce_elliptic_v4.diff"
rm -rf "${W:?}/mujoco-p50v4-src" "$W/p50v4-lib" "$V4" && mkdir -p "$W/mujoco-p50v4-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p50v4-src"
(cd "$W/mujoco-p50v4-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p50v4-src" -B "$W/p50v4-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$V4" && cmake --build "$W/p50v4-lib" -j"$J" && cmake --install "$W/p50v4-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
REC="cone=elliptic noslip=10"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
SC="$R/validation/run_049_desaxce_v4/step2/scene.xml"
for arm in rel: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$V4 ;; esac
  X="$W/p50$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_scene; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    # 1. the stacks
    for v in "rec:$REC" "ell:cone=elliptic" "pyr10:cone=pyramidal noslip=10" "def:" "ns30:cone=elliptic noslip=30" \
             "ns100:cone=elliptic noslip=100" "tight:$REC iterations=1000 tolerance=1e-12" "lock:$REC lock=1" \
             "ifast:$REC integ=implicitfast"; do
      vn=${v%%:*}; opts=${v#*:}
      for n in 5 9; do
        # shellcheck disable=SC2086
        tools/mjc_stack p/stack${n}_${vn}_0.000285 dt=0.000285 n=$n secs=2 $KCUBE $opts | sed "s|^STATS|STATS run stack${n}_${vn}_0.000285|" >> $S
      done
    done
    for dt in 0.0001425 0.00057 0.000855 0.00114; do
      for n in 5 9; do
        # shellcheck disable=SC2086
        tools/mjc_stack p/stack${n}_rec_$dt dt=$dt n=$n secs=2 $KCUBE $REC | sed "s|^STATS|STATS run stack${n}_rec_$dt|" >> $S
      done
    done
    # 2. the scene of DiscreteImplicitRowNoslip, from its keyframe, 1,000 steps
    sed 's|condim="6"|condim="4"|' "$SC" > p/scene_condim4.xml
    for v in "asis:" "ns5:noslip=5" "ns10:noslip=10" "ns50:noslip=50" "imp1:impratio=1" "pyr:cone=pyramidal"; do
      vn=${v%%:*}; opts=${v#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene p/box_$vn.txt scene="$SC" body=box axis=1,0,0 secs=16 key=0 $opts | sed "s|^STATS|STATS run box_$vn|" >> $S
    done
    tools/mjc_scene p/box_condim4.txt scene=p/scene_condim4.xml body=box axis=1,0,0 secs=16 key=0 | sed "s|^STATS|STATS run box_condim4|" >> $S
    # 3. the known limits: the pyramidal cone; the bounce; the free cube under RK4 and implicitfast
    for c in "pyr10:cone=pyramidal noslip=10" "pyr:"; do
      cn=${c%%:*}; opts=${c#*:}
      for dt in 0.01 0.0025 0.000625; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/lift16_${cn}_$dt.txt dt=$dt h0=0 vx0=1.2 mu=0.4 mass=1 radius=0.05 secs=1 lock=1 $opts | sed "s|^STATS|STATS run lift16_${cn}_$dt|" >> $S
      done
      for dir in 0 22.5 45; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/free_${cn}_${dir}.txt dt=0.00114 h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $opts trace=p/free_${cn}_${dir}.trace | sed "s|^STATS|STATS run free_${cn}_${dir}|" >> $S
        for fr in 0.5 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_${cn}_${dir}_$fr.txt dt=0.00114 h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $opts | sed "s|^STATS|STATS run hold_${cn}_${dir}_$fr|" >> $S
        done
      done
    done
    for d in 1 0.1; do
      for k in 1 4 16 64; do
        dt=$(awk -v k="$k" 'BEGIN { printf "%.12f", 0.01 / k }')
        # shellcheck disable=SC2086
        tools/mjc_contact p/bounce_d${d}_$k.txt dt="$dt" mass=2 radius=0.04 h0=0.08 secs=0.5 solref=0.02,$d $REC | sed "s|^STATS|STATS run bounce_d${d}_$k|" >> $S
      done
    done
    for g in RK4 implicitfast; do
      for dir in 0 22.5 45; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/free_${g}_${dir}.txt dt=0.00114 h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir integ=$g $REC trace=p/free_${g}_${dir}.trace | sed "s|^STATS|STATS run free_${g}_${dir}|" >> $S
      done
      for dt in 0.01 0.0025; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/lift16_${g}_$dt.txt dt=$dt h0=0 vx0=1.2 mu=0.4 mass=1 radius=0.05 secs=1 lock=1 integ=$g $REC | sed "s|^STATS|STATS run lift16_${g}_$dt|" >> $S
      done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_DESAXCE
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz) and spin
  local p=$1 t s w
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  w=$(for f in "$p"_*_tilt.txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s end_spin_urads $w"
}
box() {  # <file>: along x, the last 160 of the first 200 steps and of all 1,000: steps faster than 1 mm/s, the fastest
  awk 'NR > 1 { v = $3 < 0 ? -$3 : $3; s = $1
         if (s >= 40 && s < 200) { if (v > 1000) a++; if (v > am) am = v } if (s == 199) e200 = $3
         if (s >= 840) { if (v > 1000) b++; if (v > bm) bm = v } last = $3; mv = $2 }
       END { printf "steps_40_199_over_1mms %d fastest_ums %d speed_at_200 %d steps_840_999_over_1mms %d fastest_ums %d speed_at_1000 %d moved_nm %d\n", a, am, e200, b, bm, last, mv }' "$1"
}
{
  for a in rel on; do
    P="$O/$a/p"
    for v in rec ell pyr10 def ns30 ns100 tight lock ifast; do for n in 5 9; do
      echo "$a stack${n}_${v}_0.000285 $(stk "$P/stack${n}_${v}_0.000285") $(fld "$(grep "^STATS run stack${n}_${v}_0.000285 " "$P/stats.txt")" most_iterations | sed 's/^/most_iterations /')"
    done; done
    for dt in 0.0001425 0.00057 0.000855 0.00114; do for n in 5 9; do
      echo "$a stack${n}_rec_$dt $(stk "$P/stack${n}_rec_$dt") $(fld "$(grep "^STATS run stack${n}_rec_$dt " "$P/stats.txt")" most_iterations | sed 's/^/most_iterations /')"
    done; done
    for v in asis ns5 ns10 ns50 imp1 pyr condim4; do echo "$a box_$v $(box "$P/box_$v.txt")"; done
    for c in pyr10 pyr; do
      for dt in 0.01 0.0025 0.000625; do n="lift16_${c}_$dt"; echo "$a $n highest_um $(fld "$("$B" hover "$P/$n.txt" | tail -1)" highest_um) slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um)"; done
      for dir in 0 22.5 45; do
        n="free_${c}_$dir"; s=$(grep "^STATS run $n " "$P/stats.txt")
        echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) most_tilt_urad $(fld "$s" most_tilt_urad)"
        for fr in 0.5 0.95; do echo "$a hold_${c}_${dir}_$fr creep_ums $(fld "$("$B" creep "$P/hold_${c}_${dir}_$fr.txt" | tail -1)" mean_speed_ums)"; done
      done
    done
    for d in 1 0.1; do for k in 1 4 16 64; do echo "$a bounce_d${d}_$k $("$B" bounce "$P/bounce_d${d}_$k.txt" | tail -1)"; done; done
    for g in RK4 implicitfast; do
      for dir in 0 22.5 45; do
        n="free_${g}_$dir"; s=$(grep "^STATS run $n " "$P/stats.txt")
        echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) most_tilt_urad $(fld "$s" most_tilt_urad)"
      done
      for dt in 0.01 0.0025; do n="lift16_${g}_$dt"; echo "$a $n highest_um $(fld "$("$B" hover "$P/$n.txt" | tail -1)" highest_um)"; done
    done
    echo "$a solver most_iterations $(grep -oh 'most_iterations [0-9]*' "$P/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -oh 'at_iteration_limit [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -oh 'warnings [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  n=0; s=0; dl=""
  for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); if cmp -s "$O/rel/$f" "$O/on/$f"; then s=$((s + 1)); else dl="$dl $f"; fi; done
  echo "files rel against on: $s of $n the same"
  echo "differ rel against on:$dl" | tr ' ' '\n' | sed -n '2,$p' | sed 's/^/  /' > "$O/differ_rel_on.txt"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
