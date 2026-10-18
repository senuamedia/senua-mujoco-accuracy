#!/usr/bin/env bash
# Run 045, step 2, written after step 1's readings and pushed before its plays. Step 1 found the free cube rattling on
# its corners while it slides (0 to 2 contacts on many steps, where the friction's moment needs a tilt of about 150
# urad and leaves all four corners loaded), each contact at its full friction, but the friction along the slide short of
# mu off the axes (0.38332 along 22.5 degrees, 0.39000 along 0); with turning locked, every direction is the same. The
# question: which of MuJoCo's own contact settings stops the rattle, and does the direction go with it?
# Under Senua AI's configuration (the elliptic cone with 10 noslip iterations), the cube free to turn, along 0, 22.5 and
# 45 degrees at 1.14 and 0.285 ms, with MuJoCo's contact reference (solref: time constant, damping ratio) and impratio:
#   base (MuJoCo's default, 0.02 s and 1), dr2 (0.02, 2), dr4 (0.02, 4), tc01 (0.01, 1), tc005 (0.005, 1),
#   tc005dr2 (0.005, 2), imp10 (impratio 10); and the same cube kept from turning (locked) under base and tc005.
# Readings: the distance (sx_contact stop), the highest the cube rises while sliding (sx_contact hover), and the rig's
# STATS fields (side drift, tilt, steps with fewer than 4 contacts); the friction along the slide over the normal force,
# summed over the sliding steps (friction_ratio), is read from the play file's force columns by awk, a diagnostic.
# usage: probe_2.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_045_f12_free_cube_direction"; REL="$W/mujoco-3.16.0"
X="$W/p45b"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/" && (cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_contact > /dev/null 2>&1) || exit 1
CUBE="h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2 cone=elliptic noslip=10"
mkdir -p "$O/plays_2"; : > "$O/plays_2/stats.txt"
for v in base: dr2:"solref=0.02,2" dr4:"solref=0.02,4" tc01:"solref=0.01,1" tc005:"solref=0.005,1" tc005dr2:"solref=0.005,2" imp10:"impratio=10" \
         locked_base:"lock=1" locked_tc005:"lock=1 solref=0.005,1"; do
  c=${v%%:*}; opts=${v#*:}
  case $c in locked*) fr="" ;; *) fr="lock=0" ;; esac
  for dt in 0.00114 0.000285; do for dir in 0 22.5 45; do
    n="${c}_${dir}_$dt"
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$O/plays_2/$n.txt" dt=$dt $CUBE $fr dir=$dir $opts trace="$O/plays_2/$n.trace" | sed "s|^STATS|STATS run $n|" >> "$O/plays_2/stats.txt"
  done; done
done
rm -rf "$X"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for c in base dr2 dr4 tc01 tc005 tc005dr2 imp10 locked_base locked_tc005; do for dt in 0.00114 0.000285; do for dir in 0 22.5 45; do
    n="${c}_${dir}_$dt"; s=$(grep "^STATS run $n " "$O/plays_2/stats.txt")
    fr=$(awk 'NR == 1 { next } $3 > 50000 { fz += $5; fx += $6 } END { printf "%.5f", (fz > 0) ? -fx / fz : 0 }' "$O/plays_2/$n.txt")
    echo "$c $dt $dir slid_um $(fld "$("$B" stop "$O/plays_2/$n.txt" | tail -1)" slid_um) highest_um $(fld "$("$B" hover "$O/plays_2/$n.txt" | tail -1)" highest_um) friction_ratio $fr side_um $(fld "$s" side_um) most_tilt_urad $(fld "$s" most_tilt_urad) steps_under_4_contacts $(fld "$s" steps_under_4_contacts) most_iterations $(fld "$s" most_iterations) warnings $(fld "$s" warnings)"
  done; done; done
} > "$O/measured_2.txt"
