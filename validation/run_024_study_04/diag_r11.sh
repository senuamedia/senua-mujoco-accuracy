#!/usr/bin/env bash
# Run 024, a diagnostic after the study (not a rule, and it changes no verdict): R11 failed, the free cube under the
# aligned pyramid sliding within 1.23% of its slide along 0 where the rule allowed 1%, and drifting up to 1,176 um where
# it allowed 1,000. Does MuJoCo's own elliptic cone, which has no direction, keep the same free cube within those bounds?
# Study 4's free cube (1.15 kg, half-size 0.038 m, friction 0.62, a free joint, 0.85 m/s along 0, 25, 50, 70 and 85
# degrees, 1 s, at 1.5 ms), under the release's elliptic cone; each read by sx_contact stop (how far it slid) and the
# rig's STATS line (how far it went across its line).
# usage: diag_r11.sh <sx_contact binary> <release folder>   (repository root, on the cloud machine)
set -u
B="${1:?usage: diag_r11.sh <sx_contact> <release folder>}"; REL="${2:?}"; O=validation/run_024_study_04
X=$(mktemp -d); cp -R tools "$X/"
( cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_contact > /dev/null && mkdir -p runs && C="mass=1.15 radius=0.038"
  for dir in 0 25 50 70 85; do
    st=$(tools/mjc_contact runs/free_elliptic_$dir.txt dt=0.0015 h0=0 vx0=0.85 mu=0.62 $C secs=1 lock=0 dir=$dir cone=elliptic)
    echo "elliptic free cube along $dir | $("$B" stop runs/free_elliptic_$dir.txt | tail -1) | side_um $(awk '{ for (i = 1; i < NF; i++) if ($i == "side_um") print $(i + 1) }' <<< "$st")"
  done ) > "$O/diag_r11.txt"
mkdir -p "$O/diag_r11_runs" && cp "$X"/runs/*.txt "$O/diag_r11_runs/"; rm -rf "$X"
cat "$O/diag_r11.txt"
