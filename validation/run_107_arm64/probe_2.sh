#!/usr/bin/env bash
# Run 107, step 2, written after step 1's comparison and pushed before its plays: the cause. Step 1: MuJoCo built from
# its source with gcc on arm64 makes the Intel release's bytes in all 108 plays; Google DeepMind's arm64 release departs
# in 47 (stacks and Study 19's box under the elliptic cone with noslip). Google's releases record clang as their compiler
# (run 002), and clang fuses a multiply and an add into one rounding on arm64 by default (-ffp-contract=on), where gcc
# in MuJoCo's ISO C build does not. Builds on the arm64 machine: clangA, MuJoCo from its source with clang, MuJoCo's own
# options; clangAnc, the same with -ffp-contract=off. The same list, each twice, into arm/.
# usage: probe_2.sh <work folder>   (repository root on the arm64 machine, after probe.sh arm)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_107_arm64/arm"; log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
command -v clang > /dev/null || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq clang > "$O/apt_clang.log" 2>&1
clang --version | head -1 > "$O/clang.txt"
# the plays and the build of step 1, unchanged: the functions of probe.sh, read from it
eval "$(sed -n '/^build() {/,/^}/p; /^lim() {/p; /^plays() {/,/^}/p' "$R/validation/run_107_arm64/probe.sh")"
eval "$(grep -E '^(CFG|ARMS|SWING|SCN|PS)=' "$R/validation/run_107_arm64/probe.sh")"
build clangA 0 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
build clangAnc 0 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_FLAGS=-ffp-contract=off -DCMAKE_CXX_FLAGS=-ffp-contract=off
for n in clangA clangAnc; do
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" && for r in mjc_contact mjc_chain mjc_tumble mjc_stack mjc_scene mjc_arm mjc_grip; do MUJOCO_DIR=$W/mujoco-$n-build tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED for $n"; done ) >> "$O/progress.txt"
  rm -rf "${O:?}/$n" "$O/${n}_2"
  plays "$X/tools" "$O/$n"; plays "$X/tools" "$O/${n}_2"; rm -rf "${X:?}"
  log "$n played twice"
done
find "$O" -name 'build_clang*.log' -exec sed -i "s|$HOME|~|g" {} + ; find "$O/clangA" "$O/clangA_2" "$O/clangAnc" "$O/clangAnc_2" -name stats.txt -exec sed -i "s|$HOME|~|g" {} +
date -u +%FT%TZ > "$O/finished_2.txt"
