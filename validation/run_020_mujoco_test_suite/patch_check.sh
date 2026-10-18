#!/usr/bin/env bash
# Run 020, step 0 corrected: play.sh's check compared the two source trees with their in-tree build/ folders (left by
# earlier builds on this machine), so it listed build artefacts. This compares the trees without them: the release
# source with patches/slip_aligned_pyramid.diff applied against the patched source the patched arms are built from.
# usage: patch_check.sh <folder holding mujoco-src and mujoco-patched-src>   (repository root, on the cloud machine)
set -u
W="$(cd "${1:?usage: patch_check.sh <work folder>}" && pwd)"; R="$(pwd)"; O="$R/validation/run_020_mujoco_test_suite"
rm -rf "$W/t20-check2" && mkdir -p "$W/t20-check2"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/t20-check2"
(cd "$W/t20-check2" && patch -p1 -s < "$R/patches/slip_aligned_pyramid.diff")
{
  echo "release source commit $(git -C "$W/mujoco-src" rev-parse HEAD), UPSTREAM_COMMIT $(cat "$R/UPSTREAM_COMMIT")"
  echo "release source tracked files changed: $(git -C "$W/mujoco-src" status --porcelain --untracked-files=no | wc -l)"
  echo "patched source tracked files changed: $(git -C "$W/mujoco-patched-src" status --porcelain --untracked-files=no | tr '\n' ' ')"
  if diff -r -x .git -x build "$W/t20-check2" "$W/mujoco-patched-src" > "$O/patch_check_diff.txt"; then
    echo "SAME the patched source is the release source with patches/slip_aligned_pyramid.diff applied (build folders aside)"
  else
    echo "DIFFERS (patch_check_diff.txt)"
  fi
} > "$O/patch_check.txt"
rm -rf "$W/t20-check2"
cat "$O/patch_check.txt"
