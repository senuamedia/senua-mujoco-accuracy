#!/usr/bin/env bash
# Run 107, step 2b, written after step 2's rigs failed to link and pushed before its plays. MuJoCo built with clang
# calls one of clang's own runtime routines (__muloti4, a 128-bit multiply), which gcc's link does not supply, so every
# rig failed to link against clangA and clangAnc (progress.txt). Here the rigs are compiled by gcc exactly as
# tools/build_rig.sh compiles them, so a rig's own arithmetic is unchanged, and linked with clang's builtins archive
# added; then the list of probe.sh, each twice, into arm/.
# usage: probe_2b.sh <work folder>   (repository root on the arm64 machine, after probe_2.sh)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"
O="$R/validation/run_107_arm64/arm"; log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
RT=$(clang --print-libgcc-file-name --rtlib=compiler-rt); echo "$RT" | sed "s|$HOME|~|" > "$O/clang_builtins.txt"
eval "$(sed -n '/^lim() {/p; /^plays() {/,/^}/p' "$R/validation/run_107_arm64/probe.sh")"
eval "$(grep -E '^(CFG|ARMS|SWING|SCN)=' "$R/validation/run_107_arm64/probe.sh")"
for n in clangA clangAnc; do
  M="$W/mujoco-$n-build"; X=$(mktemp -d); cp -R "$R/tools" "$X/"
  for r in mjc_contact mjc_chain mjc_tumble mjc_stack mjc_scene mjc_arm mjc_grip; do
    cc -O2 -std=c11 -Wall -Wextra -I"$M/include" -o "$X/tools/$r" "$X/tools/$r.c" -L"$M/lib" -Wl,-rpath,"$M/lib" -lmujoco -lm "$RT" > /dev/null 2>&1 || echo "rig $r FAILED for $n (2b)" >> "$O/progress.txt"
  done
  rm -rf "${O:?}/$n" "$O/${n}_2"
  plays "$X/tools" "$O/$n"; plays "$X/tools" "$O/${n}_2"; rm -rf "${X:?}"
  log "$n played twice (2b)"
done
find "$O/clangA" "$O/clangA_2" "$O/clangAnc" "$O/clangAnc_2" -name stats.txt -exec sed -i "s|$HOME|~|g" {} +
date -u +%FT%TZ > "$O/finished_2b.txt"
