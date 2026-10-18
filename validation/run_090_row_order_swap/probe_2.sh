#!/usr/bin/env bash
# Run 090, step 2: written after step 1's readings and pushed before its plays. Step 1 found run 022's patch moving the
# leg press as run 022 did (ratio 0.741) at MuJoCo's tolerance and at 1e-15 alike. Run 089 found the release's leg press
# and its mirror image, which in this flat scene is also the scene turned by 180 degrees and so meets both pyramid pairs
# in the other order against the slip, the same to 12 digits. Run 022 recorded the patch turning the contact by exactly
# 180 degrees on 238 of 240 contact-steps and by other angles on 2: a different pyramid on those 2, not the same rows
# reordered. This plays run 022's own trace tool (validation/run_022_pyramid_v3/legpress_trace.c) on step 1's build, the
# switch set, with the patch's sleep_tolerance (a contact turned only when its slip is at least that) at MuJoCo's default
# and at 1e-4, 1e-3, 1e-2 and 1e-1 m/s, and counts, in each play's log, the contact-steps turned by exactly 180 degrees
# and by any other angle.
# usage: probe_2.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-p90-build)
set -u
W="$(cd "${1:?usage: probe_2.sh <work folder>}" && pwd)"; R="$(pwd)"
O="$R/validation/run_090_row_order_swap"; QB="$W/mujoco-p90-build"; date -u +%FT%TZ > "$O/played_at_2.txt"
X=$(mktemp -d)
cc -O2 -std=c11 -Wall -Wextra -I"$QB/include" -o "$X/legpress_trace" "$R/validation/run_022_pyramid_v3/legpress_trace.c" -L"$QB/lib" -Wl,-rpath,"$QB/lib" -lmujoco -lm > "$O/build_trace.log" 2>&1
export MUJOCO_SLIP_ALIGNED_PYRAMID=1
{
  for st in default 1e-4 1e-3 1e-2 1e-1; do
    if [ $st = default ]; then "$X/legpress_trace" "$X/log_$st.txt" > "$X/out_$st.txt"; else "$X/legpress_trace" "$X/log_$st.txt" $st > "$X/out_$st.txt"; fi
    turned=$(awk '{ c = $(NF - 3); s = $(NF - 2) } c + 0 == -1 && s + 0 == 0 { n180++ } !(c + 0 == 1 && s + 0 == 0) && !(c + 0 == -1 && s + 0 == 0) { other++ } END { printf "turned_180 %d turned_other %d", n180, other }' "$X/log_$st.txt")
    echo "sleep_tolerance $st | $(grep LEGPRESS "$X/out_$st.txt") | contact-steps of the two discrete plays: $(wc -l < "$X/log_$st.txt" | tr -d ' ') $turned"
  done
} > "$O/reading_2.txt"
unset MUJOCO_SLIP_ALIGNED_PYRAMID
gzip -n -9 -c "$X/log_default.txt" > "$O/log_default.txt.gz"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
