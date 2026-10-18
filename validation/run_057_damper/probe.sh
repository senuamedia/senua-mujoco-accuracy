#!/usr/bin/env bash
# Run 057: a design probe, not registered: it finds where to look and decides nothing. Run 055's damper scene did not play
# in any release: the actuator rig gave MuJoCo's damper an attribute it does not take (ctrllimited). The rig is
# corrected (commit after run 055), and its statistics line now prints MuJoCo's two size fields as long. This plays the
# damper scene (MuJoCo's damper actuator, kv 5, control 1, the arm released level under gravity) at 2 and 0.5 ms, under
# MuJoCo's default integrator and implicitfast, 2 s, on Google DeepMind's Linux releases 3.11.0 to 3.16.0, each
# release's files compared by cmp with 3.16.0's; and checks the correction changes no other scene: run 055's seven other
# scenes made again on 3.16.0 and compared by cmp with run 055's files.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds the releases in
#        mujoco-3.11.0 to mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; O="$R/validation/run_057_damper"
REL="3.11.0 3.12.0 3.13.0 3.14.0 3.15.0 3.16.0"; R55="$R/validation/run_055_actuators_and_box/r3.16.0/p"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
for v in $REL; do
  X="$W/p57_$v"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    MUJOCO_DIR="$W/mujoco-$v" tools/build_rig.sh mjc_act > build_mjc_act.log 2>&1
    mkdir -p p; : > p/stats.txt
    for g in def implicitfast; do
      if [ $g = def ]; then G=""; else G="integ=$g"; fi
      for dt in 0.002 0.0005; do
        # shellcheck disable=SC2086
        tools/mjc_act p/damper_${g}_$dt.txt dt=$dt scene=damper secs=2 $G 2> p/damper_${g}_$dt.err | sed "s|^STATS|STATS run damper_${g}_$dt|" >> p/stats.txt
        if [ "$v" = 3.16.0 ]; then
          mkdir -p id
          for s in position velocity motor filter fixed spatial muscle; do
            # shellcheck disable=SC2086
            tools/mjc_act id/${s}_${g}_$dt.txt dt=$dt scene=$s secs=2 $G > /dev/null 2>&1
            echo "${s}_${g}_$dt $(cmp -s id/${s}_${g}_$dt.txt "$R55/${s}_${g}_$dt.txt" && echo same || echo DIFFERS)" >> id/identity.txt
          done
        fi
      done
    done )
  rm -rf "${O:?}/r$v"; mkdir -p "$O/r$v"; cp -R "$X/p" "$X/build_mjc_act.log" "$O/r$v/"; [ -d "$X/id" ] && cp -R "$X/id" "$O/r$v/"; rm -rf "${X:?}"
  echo "$v played $(date -u +%FT%TZ)" >> "$O/progress.txt"
done
{
  echo "identity: run 055's seven other scenes made again on 3.16.0: $(grep -c ' same$' "$O/r3.16.0/id/identity.txt") of $(grep -c . "$O/r3.16.0/id/identity.txt") byte for byte"
  for v in $REL; do
    [ "$v" = 3.16.0 ] && continue
    n=0; s=0
    for f in $(cd "$O/r3.16.0/p" && ls damper_*.txt | sort); do n=$((n + 1)); cmp -s "$O/r3.16.0/p/$f" "$O/r$v/p/$f" && s=$((s + 1)); done
    echo "files $v against 3.16.0: $s of $n the same"
  done
  for v in $REL; do for g in def implicitfast; do for dt in 0.002 0.0005; do
    f="$O/r$v/p/damper_${g}_$dt.txt"
    if [ -s "$f" ]; then
      awk -v k="$v damper_${g}_$dt" 'NR > 1 { l = $0; if ($3 < m) m = $3 } END { split(l, e, " "); printf "%s end q1_urad %d qd1_urads %d force_uNm %d fastest_urads %d\n", k, e[2], e[3], e[6], m }' "$f"
    else
      echo "$v damper_${g}_$dt NOT PLAYED: $(head -c 200 "$O/r$v/p/damper_${g}_$dt.err" | tr '\n' ' ')"
    fi
  done; done; done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
