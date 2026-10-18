#!/usr/bin/env bash
# Run 011, a patch in design (not registered): patches/in_design/slip_aligned_pyramid.diff, MuJoCo 3.16.0 with each
# slipping pyramidal contact's frame turned about its normal so the first tangent lies along the slip (switch:
# MUJOCO_SLIP_ALIGNED_PYRAMID=1). Three arms, each in its own scratch copy of the repository, the rigs built against:
#   release   Google DeepMind's Linux release (run 002's)
#   off       the patched build, switch unset
#   on        the patched build, MUJOCO_SLIP_ALIGNED_PYRAMID=1
# each playing run 003's probe (the slide and the hold along three directions; the drop and set-down at large steps),
# run 005's probe (past refsafe; the hold along 22.5 degrees; a cube free to turn) and both of the first deep dive's
# contact suites under MuJoCo's defaults. Then: off against release byte for byte (safe when off), and the readings of
# all three. The pyramid is MuJoCo's default cone, so every play here uses it unless it names another.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh>   (repository root; RELEASE and PATCHED set
#        to the two MuJoCo install folders)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <runner folder>}")" && pwd)/$(basename "$1")"
M="$(cd "${2:?runner folder}" && pwd)"
O=validation/run_011_slip_aligned_pyramid; mkdir -p $O
ROOT=$(pwd)
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R tools $X/; mkdir -p $X/validation
  for r in run_001_design_probes run_003_cone_and_large_steps run_005_past_refsafe_and_free; do
    mkdir -p $X/validation/$r; cp validation/$r/*.sh $X/validation/$r/
  done
  (cd $X && for n in mjc_contact mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
   export MUJOCO_SLIP_ALIGNED_PYRAMID=$sw
   [ -z "$sw" ] && unset MUJOCO_SLIP_ALIGNED_PYRAMID
   mkdir -p validation/run_001_design_probes/runs
   tools/mjc_contact validation/run_001_design_probes/runs/slide_0.002.txt dt=0.002 h0=0 vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 > /dev/null
   bash validation/run_003_cone_and_large_steps/probe.sh "$B" > validation/run_003_cone_and_large_steps/reading.txt
   bash validation/run_005_past_refsafe_and_free/probe.sh "$B" > validation/run_005_past_refsafe_and_free/reading.txt
   tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
   bash "$M/sx_contact_suite.sh" suites/1/defaults suites/1/defaults/verdicts.txt)
  rm -rf $ROOT/$O/$name; mkdir -p $ROOT/$O/$name
  cp -R $X/validation/run_003_cone_and_large_steps $X/validation/run_005_past_refsafe_and_free $X/suites $ROOT/$O/$name/
  rm -rf $X
}
arm release "$RELEASE"
arm off "$PATCHED"
arm on "$PATCHED" 1
# safe when off: every file the off arm wrote against the release arm's
( cd $O && find release -type f | sort | while read f; do
    g=off/${f#release/}
    if [ ! -f $g ]; then echo "MISSING $g"; elif cmp -s $f $g; then echo "SAME ${f#release/}"; else echo "DIFFERS ${f#release/}"; fi
  done ) > $O/identity_off.txt
echo "off against release: $(grep -c '^SAME' $O/identity_off.txt) the same, $(grep -c '^DIFFERS\|^MISSING' $O/identity_off.txt) not"
