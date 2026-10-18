#!/usr/bin/env bash
# Run 045: a design probe for finding F12, a free cube's direction under the elliptic cone. Not registered: it finds
# where to look and decides nothing. In Study 10, under Senua AI's configuration (the elliptic cone with 10 noslip
# iterations), a cube slid free to turn went 136,043 um along 22.5 degrees, against 133,042 along 0 and 133,266 along
# 45 (Coulomb's distance 133,450); kept from turning, it slid the same along every direction to the micrometre. The
# question: is the turn about the vertical (yaw) what carries it further, and where does a yaw come from on a cube
# that physics says slides without turning?
#   Step 0, the rig unchanged without its new settings: Study 10's free cube under the release, its defaults and the
#     configuration, played again and compared with run 042's files with cmp; and again with trace set, the main file
#     compared the same way (the trace only adds a side file).
#   Step 1: the same cube (1.861 kg, half-size 0.0434 m, friction 0.39, slid at 1.01 m/s, 1.2 s) along 0, 11.25, 22.5,
#     33.75 and 45 degrees at 1.14 and 0.285 ms, under three configurations (rec: the elliptic cone with 10 noslip
#     iterations; ell: the elliptic cone alone; def: MuJoCo's defaults) and three freedoms (free: a free joint; noyaw:
#     free to tilt but not to turn about the vertical; locked: no turning), every play traced (the rig's trace file:
#     yaw, tilt, and each contact's place, normal force, friction force and its ratio to the limit, every step).
# Every distance is Senua AI's measure's (sx_contact stop); yaw, tilt, the side drift and the contact count are the
# rig's STATS fields. On MuJoCo 3.16.0 as released.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_045_f12_free_cube_direction"; REL="$W/mujoco-3.16.0"; REF="$R/validation/run_042_study_10"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
X="$W/p45"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/" && (cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_contact > /dev/null 2>&1) || { log "rig build failed"; exit 1; }
CUBE="h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2"
# step 0: identity
{
  for a in rel_def: rel_rec:"cone=elliptic noslip=10"; do
    name=${a%%:*}; opts=${a#*:}
    for dir in 0 22.5 45; do
      # shellcheck disable=SC2086
      "$X/tools/mjc_contact" "$X/id_${name}_$dir.txt" dt=0.00114 $CUBE lock=0 dir=$dir $opts > /dev/null
      # shellcheck disable=SC2086
      "$X/tools/mjc_contact" "$X/idt_${name}_$dir.txt" dt=0.00114 $CUBE lock=0 dir=$dir $opts trace="$X/idt_${name}_$dir.trace" > /dev/null
      echo "$name $dir without trace $(cmp -s "$X/id_${name}_$dir.txt" "$REF/$name/cubes/free_$dir.txt" && echo same || echo DIFFERS) with trace $(cmp -s "$X/idt_${name}_$dir.txt" "$REF/$name/cubes/free_$dir.txt" && echo same || echo DIFFERS)"
    done
  done
} > "$O/identity.txt"
log "identity: $(grep -c 'without trace same with trace same' "$O/identity.txt") of 6 the same"
# step 1
mkdir -p "$O/plays"; : > "$O/plays/stats.txt"
for cfg in rec:"cone=elliptic noslip=10" ell:"cone=elliptic" def:; do
  c=${cfg%%:*}; opts=${cfg#*:}
  for fr in free:"lock=0" noyaw:"lock=0 noyaw=1" locked:"lock=1"; do
    f=${fr%%:*}; fo=${fr#*:}
    for dt in 0.00114 0.000285; do for dir in 0 11.25 22.5 33.75 45; do
      n="${c}_${f}_${dir}_$dt"
      # shellcheck disable=SC2086
      "$X/tools/mjc_contact" "$O/plays/$n.txt" dt=$dt $CUBE $fo dir=$dir $opts trace="$O/plays/$n.trace" | sed "s|^STATS|STATS run $n|" >> "$O/plays/stats.txt"
    done; done
  done
  log "$c played"
done
rm -rf "$X"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for c in rec ell def; do for f in free noyaw locked; do for dt in 0.00114 0.000285; do for dir in 0 11.25 22.5 33.75 45; do
    n="${c}_${f}_${dir}_$dt"; s=$(grep "^STATS run $n " "$O/plays/stats.txt")
    echo "$c $f $dt $dir slid_um $(fld "$("$B" stop "$O/plays/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) yaw_end_urad $(fld "$s" yaw_end_urad) most_yaw_urad $(fld "$s" most_yaw_urad) most_tilt_urad $(fld "$s" most_tilt_urad) steps_under_4_contacts $(fld "$s" steps_under_4_contacts) most_iterations $(fld "$s" most_iterations) warnings $(fld "$s" warnings)"
  done; done; done; done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
