#!/usr/bin/env bash
# Run 090: a design probe, not registered: it finds where to look and decides nothing. Issue 13 (F9): run 022 found the
# discrete integrator's leg press moved by 0.8 mm when the slip-aligned pyramid's second version turned its contact by
# 180 degrees, which gives the solver the same four pyramid rows with each pair swapped. Run 089 found the release's leg
# press the same to 12 digits in its mirror image, which swaps only the first pair against the slip. This builds MuJoCo
# from its source at UPSTREAM_COMMIT with patches/in_design/slip_aligned_pyramid_v2.diff alone, as run 022 did, and plays
# the leg press (run 089's legpress_order_2.c, as written, floor not turned) with the patch's switch unset and set, at
# MuJoCo's default solver tolerance and at 1e-15 with 1,000 iterations. If the swap's effect stays at 1e-15, the
# dependence is in the problem the solver is given, not in where it stops.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src)
set -u
W="$(cd "${1:?usage: probe.sh <work folder>}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_090_row_order_swap"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
P="$R/patches/in_design/slip_aligned_pyramid_v2.diff"; QB="$W/mujoco-p90-build"
rm -rf "${W:?}/mujoco-p90-src" "$W/p90-lib" "$QB" && mkdir -p "$W/mujoco-p90-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p90-src"
(cd "$W/mujoco-p90-src" && patch -p1 -s < "$P")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$P" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p90-src" -B "$W/p90-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p90-lib" -j"$J" && cmake --install "$W/p90-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
X=$(mktemp -d)
cc -O2 -std=c11 -Wall -Wextra -I"$QB/include" -o "$X/legpress_order_2" "$R/validation/run_089_order_free_cube_stacks/legpress_order_2.c" -L"$QB/lib" -Wl,-rpath,"$QB/lib" -lmujoco -lm > "$O/build_legpress.log" 2>&1
{
  for sw in unset 1; do
    for t in default:"1e-8 100" 1e-15:"1e-15 1000"; do
      tn=${t%%:*}; ta=${t#*:}
      if [ $sw = 1 ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=1; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
      echo "switch $sw tolerance $tn"
      # shellcheck disable=SC2086
      "$X/legpress_order_2" 0 $ta
    done
  done
  unset MUJOCO_SLIP_ALIGNED_PYRAMID
} > "$O/reading.txt"
rm -rf "${X:?}" "${W:?}/mujoco-p90-src" "$W/p90-lib"
date -u +%FT%TZ > "$O/finished.txt"
