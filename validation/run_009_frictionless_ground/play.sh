#!/usr/bin/env bash
# Run 009, design probe (not registered): the first deep dive's second contact suite played on MuJoCo again, the two-
# cube rig now making the frictionless ground frictionless the way MuJoCo makes one (condim 1). Run 008 played it with
# condim 3 and friction 0, which MuJoCo raises to 1e-5, and measured exactly that friction in the "top" test. The one-
# cube plays do not use the two-cube rig: they are played again as a check that nothing else changed.
# usage: play.sh <sx_contact binary>        (from the repository root; MUJOCO_DIR set; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"; O=validation/run_009_frictionless_ground
tools/build_rig.sh mjc_pair > /dev/null
tools/contact_suite2.sh frictionless_ground_defaults > /dev/null
tools/contact_suite2.sh frictionless_ground_elliptic_noslip cone=elliptic noslip=10 > /dev/null
for pair in "frictionless_ground_defaults defaults" "frictionless_ground_elliptic_noslip elliptic_noslip"; do
  set -- $pair; d=suites/2/$1; old=suites/2/$2
  for f in $old/*.txt; do
    n=$(basename $f); [ "$n" = stats.txt ] && continue
    if cmp -s $f $d/$n; then echo "SAME $2 $n"; else echo "DIFFERS $2 $n"; fi
  done > $O/compare_$2.txt
  echo "$2: $(grep -c '^SAME' $O/compare_$2.txt) files the same as run 008's, $(grep -c '^DIFFERS' $O/compare_$2.txt) different"
  for k in 1 16; do
    echo "$2 rest 1/$k | $($B pair $d/rest_${k}_a.txt $d/rest_${k}_b.txt | tail -1)"
    echo "$2 carry 1/$k | $($B pair $d/carry_${k}_a.txt $d/carry_${k}_b.txt | tail -1)"
    echo "$2 slip A 1/$k | $($B accel $d/slip_${k}_a.txt 700 900 | tail -1)"
    echo "$2 slip B 1/$k | $($B accel $d/slip_${k}_b.txt 700 900 | tail -1)"
    echo "$2 side 1/$k | $($B pair $d/side_${k}_a.txt $d/side_${k}_b.txt | tail -1)"
    echo "$2 top 1/$k | $($B pair $d/top_${k}_a.txt $d/top_${k}_b.txt | tail -1)"
  done
done
