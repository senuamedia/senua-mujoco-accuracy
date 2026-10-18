#!/usr/bin/env bash
# Run 021, a diagnostic after the checks (not a check, and not registered): check C4 failed, version 2's belt plays
# stopping 1 to 6 steps before their references. Is a moving floor equivalent to a still one for MuJoCo's own isotropic
# friction? The same belt plays and references under the elliptic cone, which has no direction, on the release; if
# they too stop before their references, the reference is not an exact equivalent of the belt play in MuJoCo, and C4
# measured that as well as the patch.
# usage: diag_belt.sh <sx_contact binary> <release folder>   (repository root, on the cloud machine)
set -u
B="${1:?usage: diag_belt.sh <sx_contact> <release folder>}"; REL="${2:?}"; O=validation/run_021_pyramid_v2
X=$(mktemp -d); cp -R tools "$X/"; R=$(pwd)
( cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_contact > /dev/null && mkdir -p runs && C="mass=1 radius=0.05"
  for dt in 0.002 0.0005; do
    tools/mjc_contact runs/belt45_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,1 cone=elliptic > /dev/null
    tools/mjc_contact runs/ref45_$dt.txt dt=$dt h0=0 vx0=1.4142135623730951 mu=0.4 $C secs=1 cone=elliptic > /dev/null
    tools/mjc_contact runs/belt30_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,0.5773502691896258 cone=elliptic > /dev/null
    tools/mjc_contact runs/ref30_$dt.txt dt=$dt h0=0 vx0=1.1547005383792515 mu=0.4 $C secs=1 cone=elliptic > /dev/null
  done
  for dt in 0.002 0.0005; do for b in belt45 ref45 belt30 ref30; do
    echo "elliptic release $b $dt | $("$B" stop runs/${b}_$dt.txt | tail -1)"
  done; done ) > "$O/diag_belt.txt"
mkdir -p "$O/diag_belt_runs" && cp "$X"/runs/*.txt "$O/diag_belt_runs/"; rm -rf "$X"
cat "$O/diag_belt.txt"
