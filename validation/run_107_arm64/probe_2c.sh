#!/usr/bin/env bash
# Run 107, step 2c, written after step 2b and pushed before its plays. Step 2b's link failed too: clang's builtins
# archive keeps __muloti4 hidden, so an executable cannot supply it to libmujoco.so. Here MuJoCo is built with clang
# and its library linked against clang's own runtime (-rtlib=compiler-rt), as a clang toolchain links it, so the library
# carries the routine itself; the rigs are then built by tools/build_rig.sh unchanged (gcc), and the list of probe.sh
# played, each build twice, into arm/: clangA (MuJoCo's own options), clangAnc (and -ffp-contract=off).
# usage: probe_2c.sh <work folder>   (repository root on the arm64 machine, after probe_2b.sh)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_107_arm64/arm"; log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
eval "$(sed -n '/^build() {/,/^}/p; /^lim() {/p; /^plays() {/,/^}/p' "$R/validation/run_107_arm64/probe.sh")"
eval "$(grep -E '^(CFG|ARMS|SWING|SCN|PS)=' "$R/validation/run_107_arm64/probe.sh")"
RTL="-DCMAKE_SHARED_LINKER_FLAGS=-rtlib=compiler-rt -DCMAKE_EXE_LINKER_FLAGS=-rtlib=compiler-rt"
# shellcheck disable=SC2086
build clangA 0 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ $RTL
# shellcheck disable=SC2086
build clangAnc 0 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_FLAGS=-ffp-contract=off -DCMAKE_CXX_FLAGS=-ffp-contract=off $RTL
for n in clangA clangAnc; do
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" && for r in mjc_contact mjc_chain mjc_tumble mjc_stack mjc_scene mjc_arm mjc_grip; do MUJOCO_DIR=$W/mujoco-$n-build tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED for $n (2c)"; done ) >> "$O/progress.txt"
  rm -rf "${O:?}/$n" "$O/${n}_2"
  plays "$X/tools" "$O/$n"; plays "$X/tools" "$O/${n}_2"; rm -rf "${X:?}"
  log "$n played twice (2c)"
done
find "$O" -name 'build_clang*.log' -exec sed -i "s|$HOME|~|g" {} + ; find "$O/clangA" "$O/clangA_2" "$O/clangAnc" "$O/clangAnc_2" -name stats.txt -exec sed -i "s|$HOME|~|g" {} +
date -u +%FT%TZ > "$O/finished_2c.txt"
