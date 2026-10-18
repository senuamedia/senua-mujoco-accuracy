#!/usr/bin/env bash
# Run 070, step 2, written after step 1's readings and pushed before its plays. Step 1's first part looped over its two
# option sets as "for os in rec:$REC def:", which split the configuration's two options into two passes: its "rec"
# plays are under the elliptic cone alone, a further pass ("noslip=100") under MuJoCo's default pyramidal cone with 100
# noslip iterations, and "def" under MuJoCo's defaults, as intended. Its grid passed the options whole and is as
# registered in its header. This replays the first part as its header states it, under the configuration (the elliptic
# cone, 100 noslip iterations), on step 1's build of the same patch file (mujoco-p70-build), into step2/: the stacks of
# 5 and 9 and the offset stack of 3 with their contacts traced, the slide on a box's face, the holds and the grips, at
# 1.14 and 0.285 ms; released (rel) and with the switch unset (off) and set (on).
# usage: probe_2.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_070_boxbox_clip/step2"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p70-build"; mkdir -p "$O"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
REC="cone=elliptic noslip=100"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
CHG='{ if ($1 != cs) { if (cs != "") fl(cs); cs = $1 } p = $2 "-" $3; seen[p] = 1; cnt[p]++ }
function fl(st,   p) { for (p in seen) { if (st > 30 && cnt[p] != pc[p]) n++; pc[p] = cnt[p]; cnt[p] = 0 } }
END { fl(cs); print n + 0 }'
stack() {
  local p=$1; shift
  tools/mjc_stack "$p" "$@" contacts="$p.contacts" | sed "s|^STATS|STATS run $(basename "$p")|" >> "$S"
  echo "$(basename "$p") $(awk "$CHG" "$p.contacts")" >> "$C"
  rm -f "$p.contacts"
}
for arm in rel: off: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$QB ;; esac
  X="$W/p70s2$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_BOXBOX_CLIPTOL=$sw; else unset MUJOCO_BOXBOX_CLIPTOL; fi
    mkdir -p p; S=p/stats.txt; C=p/changes.txt; : > $S; : > $C
    for dt in 0.00114 0.000285; do
      # shellcheck disable=SC2086
      for n in 5 9; do stack p/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $REC; done
      # shellcheck disable=SC2086
      stack p/offset3_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC
      # shellcheck disable=SC2086
      tools/mjc_stack p/slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $REC | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        tools/mjc_contact p/hold_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 $REC | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> $S
      done
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; rm -rf "${X:?}"
  echo "$a played $(date -u +%FT%TZ)" >> "$O/progress.txt"
done
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {
  local p=$1 t s
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s"
}
{
  for y in off on; do
    n=0; s=0
    for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/$y/$f" && s=$((s + 1)); done
    echo "files rel against $y: $s of $n the same"
  done
  for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do cmp -s "$O/rel/$f" "$O/on/$f" || echo "differ rel against on: $f"; done
  for a in rel on; do
    for dt in 0.00114 0.000285; do
      for s in stack5 stack9 offset3; do echo "$a ${s}_$dt $(stk "$O/$a/p/${s}_$dt") contact_count_changes $(grep "^${s}_$dt " "$O/$a/p/changes.txt" | awk '{ print $2 }')"; done
      echo "$a slide_box_$dt slid_um $(fld "$("$B" stop "$O/$a/p/slide_box_${dt}_1.txt" | tail -1)" slid_um) $(stk "$O/$a/p/slide_box_$dt")"
      echo "$a holds_$dt creep_ums $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')"
      echo "$a grips_$dt creep_ums $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/p/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
