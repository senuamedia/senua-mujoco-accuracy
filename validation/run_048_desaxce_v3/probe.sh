#!/usr/bin/env bash
# Run 048: a design probe of the de Saxce patch's third version, patches/in_design/desaxce_elliptic_v3.diff (switch
# MUJOCO_DESAXCE=1). Not registered: it finds where to look and decides nothing. Run 047 found seven of MuJoCo's own
# tests changed by the second version, from three causes: the shift acted on contacts at rest (de Saxce's term is
# friction times the slip, zero at stick), the dual solver's accelerations were read before mj_dualFinish, and the
# constraint problem was solved whole in place of MuJoCo's islands. This version shifts only sliding contacts (the
# primal cost's middle zone), reads the dual solver's result, solves islands as MuJoCo does, and stops when no shift
# moves by more than the solver's own tolerance; it only adds lines. The question: does it remove the lift and the
# direction as before, and what does it change across the record's other scenes and MuJoCo's own test suite?
# Arms, all under Senua AI's configuration (the elliptic cone with 10 noslip iterations) unless a play names another:
#   rel, MuJoCo 3.16.0 as released; off, the third version with its switch unset; on, with it set
# Plays: run 046's (the lift, the free cube, holds and grips); and Study 10's other scenes on Study 10's numbers
# (parameters.txt of run 042): the first deep dive's two contact suites, stacks of 5 and 9 and an offset stack of 3, a
# cube sliding on the ground and on a box face, the arm on contact (set down and dropped, written three ways), the arm
# swinging on its elbow limit, held by joint friction, by a connect and by a weld (written three ways), at 1.14 and
# 0.285 ms; and MuJoCo's own test suite on the third version, the switch unset and set.
# Readings: Senua AI's measures (sx_contact hover, stop, creep, rest, final; the first deep dive's suite runner), file
# comparison by cmp, and the rigs' STATS fields.
# usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>   (repository root, cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_048_desaxce_v3"; REL="$W/mujoco-3.16.0"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
build() {  # <name> <patch file> <with tests 0|1>
  local n=$1 pf=$2 t=$3
  rm -rf "${W:?}/mujoco-p48$n-src" "$W/p48$n-lib" "$W/mujoco-p48$n-build" "$W/t48$n" && mkdir -p "$W/mujoco-p48$n-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p48$n-src"
  (cd "$W/mujoco-p48$n-src" && patch -p1 -s < "$pf")
  echo "$n source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$pf" | cut -c1-16)" >> "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-p48$n-src" -B "$W/p48$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-p48$n-build" && cmake --build "$W/p48$n-lib" -j"$J" && cmake --install "$W/p48$n-lib" ) > "$O/build_lib_$n.log" 2>&1
  log "build lib $n exit $?"
  if [ "$t" = 1 ]; then
    ( cmake -S "$W/mujoco-p48$n-src" -B "$W/t48$n" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
        -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t48$n" -j"$J" ) > "$O/build_tests_$n.log" 2>&1
    log "build tests $n exit $?"
  fi
}
: > "$O/patch_check.txt"
build v3 "$R/patches/in_design/desaxce_elliptic_v3.diff" 1
REC="cone=elliptic noslip=10"; CUBE="mass=1.861 radius=0.0434 mu=0.39"; LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; FOLD=0,2.463
for arm in rel: off: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj="$W/mujoco-p48v3-build" ;; esac
  X="$W/p48$a"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_grip mjc_stack mjc_arm mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    for c in rec:"$REC" ell:"cone=elliptic"; do
      cn=${c%%:*}; opts=${c#*:}
      for dt in 0.01 0.0025 0.000625; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/lift16_${cn}_$dt.txt dt=$dt h0=0 vx0=1.2 mu=0.4 mass=1 radius=0.05 secs=1 lock=1 $opts trace=p/lift16_${cn}_$dt.trace | sed "s|^STATS|STATS run lift16_${cn}_$dt|" >> $S
      done
      for dt in 0.00114 0.000285; do
        for dir in 0 11.25 22.5 33.75 45; do
          # shellcheck disable=SC2086
          tools/mjc_contact p/free_${cn}_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $opts trace=p/free_${cn}_${dir}_$dt.trace | sed "s|^STATS|STATS run free_${cn}_${dir}_$dt|" >> $S
        done
      done
    done
    for dt in 0.00114 0.000285; do
      for dir in 0 22.5 45; do
        for fr in 0.5 0.75 0.95; do
          p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $REC | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> $S
        done
        # shellcheck disable=SC2086
        tools/mjc_contact p/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=$dir $REC | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> $S
      done
      # shellcheck disable=SC2086
      for n in 5 9; do tools/mjc_stack p/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $REC | sed "s|^STATS|STATS run stack${n}_$dt|" >> $S; done
      # shellcheck disable=SC2086
      tools/mjc_stack p/offset3_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC | sed "s|^STATS|STATS run offset3_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_stack p/slide_ground_$dt dt=$dt n=1 vx=1.16 secs=1 base=0 $KCUBE $REC | sed "s|^STATS|STATS run slide_ground_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_stack p/slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $REC | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
      k=0
      for PS in 0.604,1.158 1.149,-0.545; do
        k=$((k + 1))
        for scene in rest drop; do
          if [ $scene = rest ]; then SC="h0=0.00059 secs=2"; else SC="h0=0.0121 secs=1"; fi
          for wr in native straight folded; do
            case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
            # shellcheck disable=SC2086
            tools/mjc_arm p/arm_pose${k}_${scene}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 $ARM $SC $REC | sed "s|^STATS|STATS run arm_pose${k}_${scene}_${dt}_$wr|" >> $S
          done
        done
      done
      set -- -2.026 -2.003
      k=0
      for PS in 0.245,0.831 0.223,0.993; do
        k=$((k + 1)); lo=$1; shift; hi=${PS#*,}
        for wr in native straight folded; do
          case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
          for sc in swing hold connect weld; do
            case $sc in swing) H="elbowlimit=$lo,$hi" ;; hold) H="jointfriction=5.96" ;; connect) H="tipconnect=1" ;; weld) H="tipweld=1" ;; esac
            # shellcheck disable=SC2086
            tools/mjc_arm p/${sc}_pose${k}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 $H h0=1 secs=2 $ARM $REC | sed "s|^STATS|STATS run ${sc}_pose${k}_${dt}_$wr|" >> $S
          done
        done
      done
    done
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=0.881 radius=0.0392" SUITE_H0=0.096 SUITE_VX=3.24 SUITE_VXCHAIN=1.47 SUITE_MU=0.371 SUITE_VSLIDE=3.67 \
        SUITE_MUHOLD=0.421 SUITE_HOLD=2.180898 SUITE_SLIP=4.361796 SUITE_LIFT=25.9014
      tools/contact_suite.sh fresh $REC > /dev/null )
    # shellcheck disable=SC2086
    tools/contact_suite2.sh registered $REC > /dev/null )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$X/suites" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_DESAXCE
# MuJoCo's own test suite on the third version, the switch unset and set. the two memory-heavy reader tests alone
for s in off: on:1; do
  n=${s%%:*}; sw=${s#*:}
  ( cd "$W/t48v3" && if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
for n in off on; do grep -E '^ *[0-9]+/[0-9]+ Test +#' "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" | sed -E 's/^[^:]*://; s/^ *[0-9]+\/[0-9]+ Test +#[0-9]+: //; s/ +\.+ */ /; s/ +[0-9.]+ sec$//; s/\*\*\*//' | awk '{ st = $NF; $NF = ""; sub(/ +$/, ""); gsub(/ /, "_"); print $0, st }' | LC_ALL=C sort > "$O/suite_results_$n.txt"; done
LC_ALL=C join "$O/suite_results_off.txt" "$O/suite_results_on.txt" | awk '$2 != $3 { print "changed with the switch set: " $1 " " $2 " -> " $3 }' > "$O/suite_changed.txt"
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for a in rel off on; do
    P="$O/$a/p"
    for c in rec ell; do
      for dt in 0.01 0.0025 0.000625; do n="lift16_${c}_$dt"; echo "$a $n highest_um $(fld "$("$B" hover "$P/$n.txt" | tail -1)" highest_um) slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um)"; done
      for dt in 0.00114 0.000285; do for dir in 0 11.25 22.5 33.75 45; do
        n="free_${c}_${dir}_$dt"; s=$(grep "^STATS run $n " "$P/stats.txt")
        echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) steps_under_4_contacts $(fld "$s" steps_under_4_contacts)"
      done; done
    done
    for dt in 0.00114 0.000285; do
      for dir in 0 22.5 45; do
        for fr in 0.5 0.75 0.95; do echo "$a hold_${dir}_${fr}_$dt creep_ums $(fld "$("$B" creep "$P/hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums)"; done
        echo "$a slide_${dir}_$dt slid_um $(fld "$("$B" stop "$P/slide_${dir}_$dt.txt" | tail -1)" slid_um)"
      done
      for g in "$P"/grip_*_"$dt".txt; do echo "$a $(basename "$g" .txt) creep_ums $(fld "$("$B" creep "$g" | tail -1)" mean_speed_ums)"; done
    done
    SUITE_MU10K=3710 SUITE_SLIPMN=4361 bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh" "$O/$a/suite1.txt" > /dev/null 2>&1
    echo "$a suite1 passed $(grep '^SUITE passed' "$O/$a/suite1.txt" | awk '{ print $3 }')"
    echo "$a solver most_iterations $(grep -oh 'most_iterations [0-9]*' "$P/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -oh 'at_iteration_limit [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -oh 'warnings [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  for pair in rel:off rel:on; do
    x=${pair%%:*}; y=${pair#*:}; n=0; s=0; dl=""
    for f in $(cd "$O/$x" && find p suites -type f ! -name stats.txt | sort); do n=$((n + 1)); if cmp -s "$O/$x/$f" "$O/$y/$f"; then s=$((s + 1)); else dl="$dl $f"; fi; done
    echo "files $x against $y: $s of $n the same"
    [ "$pair" = rel:on ] && echo "differ rel against on:$dl" | tr ' ' '\n' | sed -n '2,$p' | sed 's/^/  /' > "$O/differ_rel_on.txt"
  done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with the switch set: $(wc -l < "$O/suite_changed.txt" | tr -d ' ')"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
