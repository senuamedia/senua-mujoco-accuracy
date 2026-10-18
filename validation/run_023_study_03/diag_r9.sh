#!/usr/bin/env bash
# Run 023, a diagnostic after the study (not a rule, and it changes no verdict): R9 failed at 0.375 ms, the aligned
# pyramid stopping 2 steps after MuJoCo's elliptic cone on the moving floor. Do MuJoCo's two cones already differ by that
# much with no direction in it? Study 3's cube slid on a still floor along x, the pyramid's own axis, at the two slip
# speeds of the moving-floor plays (0.9 / cos 35 and 0.9 / cos 55 degrees), under the release's pyramid and its
# elliptic cone, at 1.5 ms and 0.375 ms.
# usage: diag_r9.sh <sx_contact binary> <release folder>   (repository root, on the cloud machine)
set -u
B="${1:?usage: diag_r9.sh <sx_contact> <release folder>}"; REL="${2:?}"; O=validation/run_023_study_03
X=$(mktemp -d); cp -R tools "$X/"
( cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_contact > /dev/null && mkdir -p runs && C="mass=1.3 radius=0.035"
  for dt in 0.0015 0.000375; do for v in 1.0986841134678098 1.5690838789861106; do for cone in pyramidal elliptic; do
    tools/mjc_contact runs/axis_${v}_${cone}_$dt.txt dt=$dt h0=0 vx0=$v mu=0.55 $C secs=0.8 cone=$cone > /dev/null
    echo "$cone still floor along x, $v m/s, $dt | $("$B" stop runs/axis_${v}_${cone}_$dt.txt | tail -1)"
  done; done; done ) > "$O/diag_r9.txt"
mkdir -p "$O/diag_r9_runs" && cp "$X"/runs/*.txt "$O/diag_r9_runs/"; rm -rf "$X"
cat "$O/diag_r9.txt"
