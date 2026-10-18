#!/usr/bin/env bash
# Run 053: a design probe, not registered: it finds where to look and decides nothing. Issue 17 of docs/issues.md (M9):
# MuJoCo's collision code changes from release to release (its changelog: box-box rewritten in 3.12, plane-mesh in
# 3.13), and this record is pinned at 3.16.0. What changes in the record's contact scenes across Google DeepMind's Linux
# releases 3.11.0, 3.12.0, 3.13.0, 3.14.0, 3.15.0 and 3.16.0, and does any change break a rule the record holds?
# Each release is fetched from MuJoCo's GitHub releases and checked against the sha256 published beside it (3.16.0 is
# the one already in the work folder, sha256 139577c541d43716...). Every rig is built against each release's own headers
# and library. Plays, on Study 10's numbers, under MuJoCo's defaults (def) and under Senua AI's configuration (rec), at
# 1.14 and 0.285 ms: the cube held at 0.5, 0.75 and 0.95 of its friction limit and slid along 0, 22.5 and 45 degrees,
# kept from turning, and slid free to turn along 0, 22.5 and 45 (box on plane); stacks of 5 and 9, the offset stack of
# 3, and a cube slid on a box's face (box on box); the grip, box and mesh pads, at the centre and off it (box and mesh on
# box); the arm on contact, set down and dropped, in two poses (sphere on plane); and the first contact suite on Study
# 10's cube. Readings: file comparison by cmp against 3.16.0, Senua AI's measures (sx_contact creep, stop, hover; the
# first deep dive's suite runner), and the rigs' STATS fields.
# usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>   (repository root, on the cloud
#        machine; the work folder holds the 3.16.0 release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_053_releases"; REL="3.11.0 3.12.0 3.13.0 3.14.0 3.15.0 3.16.0"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
: > "$O/releases.txt"
for v in $REL; do
  d="$W/mujoco-$v"
  if [ "$v" != 3.16.0 ]; then
    t="$W/mujoco-$v-linux-x86_64.tar.gz"; u="https://github.com/google-deepmind/mujoco/releases/download/$v"
    curl -fsSL -o "$t" "$u/mujoco-$v-linux-x86_64.tar.gz" && curl -fsSL -o "$t.sha256" "$u/mujoco-$v-linux-x86_64.tar.gz.sha256"
    want=$(awk '{ print $1 }' "$t.sha256"); got=$(sha256sum "$t" | awk '{ print $1 }')
    if [ "$want" = "$got" ]; then rm -rf "$d"; tar xzf "$t" -C "$W"; ok=matches; else ok="DOES NOT MATCH ($want)"; fi
    echo "$v sha256 $got; the published sha256 $ok" >> "$O/releases.txt"
  else
    echo "$v already in the work folder (Study 10's release)" >> "$O/releases.txt"
  fi
done
log "fetched"
REC="cone=elliptic noslip=10"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434"; MU=0.39
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"
for v in $REL; do
  mj="$W/mujoco-$v"; X="$W/p53_$v"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > "build_$n.log" 2>&1 || echo "$v rig $n did not build" >> "$O/progress.txt"; done
    unset MUJOCO_DESAXCE
    mkdir -p p; S=p/stats.txt; : > $S
    for c in def: rec:"$REC"; do
      cn=${c%%:*}; opts=${c#*:}
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.75 0.95; do
            pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
            # shellcheck disable=SC2086
            tools/mjc_contact p/${cn}_hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 mu=$MU $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $opts | sed "s|^STATS|STATS run ${cn}_hold_${dir}_${fr}_$dt|" >> $S
          done
          # shellcheck disable=SC2086
          tools/mjc_contact p/${cn}_slide_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 mu=$MU $CUBE secs=1.2 dir=$dir $opts | sed "s|^STATS|STATS run ${cn}_slide_${dir}_$dt|" >> $S
          # shellcheck disable=SC2086
          tools/mjc_contact p/${cn}_free_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 mu=$MU $CUBE secs=1.2 lock=0 dir=$dir $opts | sed "s|^STATS|STATS run ${cn}_free_${dir}_$dt|" >> $S
        done
        # shellcheck disable=SC2086
        for n in 5 9; do tools/mjc_stack p/${cn}_stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_stack${n}_$dt|" >> $S; done
        # shellcheck disable=SC2086
        tools/mjc_stack p/${cn}_offset3_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_offset3_$dt|" >> $S
        # shellcheck disable=SC2086
        tools/mjc_stack p/${cn}_slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_slide_box_$dt|" >> $S
        for off in 0 0.0093; do for pad in box mesh; do
          # shellcheck disable=SC2086
          tools/mjc_grip p/${cn}_grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $opts | sed "s|^STATS|STATS run ${cn}_grip_${pad}_off${off}_$dt|" >> $S
        done; done
        k=0
        for PS in 0.604,1.158 1.149,-0.545; do
          k=$((k + 1))
          for sc in rest drop; do
            if [ $sc = rest ]; then SC="h0=0.00059 secs=2"; else SC="h0=0.0121 secs=1"; fi
            # shellcheck disable=SC2086
            tools/mjc_arm p/${cn}_arm_pose${k}_${sc}_$dt.txt dt=$dt pose=$PS pose0=$PS $ARM $SC $opts | sed "s|^STATS|STATS run ${cn}_arm_pose${k}_${sc}_$dt|" >> $S
          done
        done
      done
      # shellcheck disable=SC2086
      ( export SUITE_CUBE="mass=0.881 radius=0.0392" SUITE_H0=0.096 SUITE_VX=3.24 SUITE_VXCHAIN=1.47 SUITE_MU=0.371 SUITE_VSLIDE=3.67 \
          SUITE_MUHOLD=0.421 SUITE_HOLD=2.180898 SUITE_SLIP=4.361796 SUITE_LIFT=25.9014
        tools/contact_suite.sh $cn $opts > /dev/null )
    done )
  rm -rf "${O:?}/r$v"; mkdir -p "$O/r$v"; cp -R "$X/p" "$X/suites" "$O/r$v/"; cp "$X"/build_*.log "$O/r$v/" 2>/dev/null; rm -rf "${X:?}"
  log "$v played"
done
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz)
  local p=$1 t s
  t=$(cat "$p"_*_tilt.txt 2>/dev/null | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done 2>/dev/null | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s"
}
for v in $REL; do for cn in def rec; do
  SUITE_MU10K=3710 SUITE_SLIPMN=4361 bash "$M/sx_contact_suite.sh" "$O/r$v/suites/1/$cn" "$O/r$v/suite1_$cn.txt" > /dev/null 2>&1
done; done
{
  for v in $REL; do
    P="$O/r$v/p"
    for cn in def rec; do
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.75 0.95; do echo "$v $cn hold_${dir}_${fr}_$dt creep_ums $(fld "$("$B" creep "$P/${cn}_hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums)"; done
          echo "$v $cn slide_${dir}_$dt slid_um $(fld "$("$B" stop "$P/${cn}_slide_${dir}_$dt.txt" | tail -1)" slid_um) highest_um $(fld "$("$B" hover "$P/${cn}_slide_${dir}_$dt.txt" | tail -1)" highest_um)"
          echo "$v $cn free_${dir}_$dt slid_um $(fld "$("$B" stop "$P/${cn}_free_${dir}_$dt.txt" | tail -1)" slid_um) side_um $(fld "$(grep "^STATS run ${cn}_free_${dir}_$dt " "$P/stats.txt")" side_um)"
        done
        for s in stack5 stack9 offset3; do echo "$v $cn ${s}_$dt $(stk "$P/${cn}_${s}_$dt")"; done
        echo "$v $cn slide_box_$dt slid_um $(fld "$("$B" stop "$P/${cn}_slide_box_${dt}_1.txt" | tail -1)" slid_um)"
        for off in 0 0.0093; do for pad in box mesh; do
          echo "$v $cn grip_${pad}_off${off}_$dt creep_ums $(fld "$("$B" creep "$P/${cn}_grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums)"
        done; done
        for k in 1 2; do echo "$v $cn arm_pose${k}_rest_$dt creep_ums $(fld "$("$B" creep "$P/${cn}_arm_pose${k}_rest_$dt.txt" | tail -1)" mean_speed_ums)"; done
      done
      echo "$v $cn suite1 passed $(grep '^SUITE passed' "$O/r$v/suite1_$cn.txt" | awk '{ print $3 }')"
      echo "$v $cn solver most_iterations $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'at_iteration_limit [0-9]*' | awk '{ s += $2 } END { print s + 0 }') warnings $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'warnings [0-9]*' | awk '{ s += $2 } END { print s + 0 }')"
    done
  done
  # each release's files against 3.16.0's, by kind of scene
  for v in $REL; do
    [ "$v" = 3.16.0 ] && continue
    for kind in hold slide_0 slide_2 slide_4 free stack offset3 slide_box grip_box grip_mesh arm; do
      n=0; s=0
      for f in $(cd "$O/r3.16.0/p" && ls | grep -E "^(def|rec)_${kind}" | sort); do n=$((n + 1)); cmp -s "$O/r3.16.0/p/$f" "$O/r$v/p/$f" && s=$((s + 1)); done
      echo "files $v against 3.16.0, $kind: $s of $n the same"
    done
    n=0; s=0
    for f in $(cd "$O/r3.16.0" && find suites -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/r3.16.0/$f" "$O/r$v/$f" && s=$((s + 1)); done
    echo "files $v against 3.16.0, suites: $s of $n the same"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
