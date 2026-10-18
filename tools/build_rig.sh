#!/usr/bin/env bash
# Builds one rig against MuJoCo. usage (from the repository root; for example: tools/build_rig.sh mjc_contact):
#   macOS: MUJOCO_FRAMEWORK_DIR=<folder holding mujoco.framework> tools/build_rig.sh <rig name>
#   Linux: MUJOCO_DIR=<the release's folder, holding include/ and lib/> tools/build_rig.sh <rig name>
# The first probes use Google DeepMind's prebuilt 3.16.0 releases (macOS: mujoco-3.16.0-macos-universal2.dmg, sha256
# e31ab79c0a5e4280...; Linux: mujoco-3.16.0-linux-x86_64.tar.gz, sha256 139577c541d43716...); a build from source at
# the commit in UPSTREAM_COMMIT replaces them once patches are built.
set -eu
N="${1:?usage: tools/build_rig.sh <rig name>}"
if [ "$(uname)" = Darwin ]; then
  F="${MUJOCO_FRAMEWORK_DIR:?set MUJOCO_FRAMEWORK_DIR to the folder holding mujoco.framework}"
  cc -O2 -std=c11 -Wall -Wextra -F"$F" -framework mujoco -Wl,-rpath,"$F" -o "tools/$N" "tools/$N.c" -lm
  echo "built tools/$N against $F"
else
  M="${MUJOCO_DIR:?set MUJOCO_DIR to the MuJoCo release folder holding include/ and lib/}"
  cc -O2 -std=c11 -Wall -Wextra -I"$M/include" -o "tools/$N" "tools/$N.c" -L"$M/lib" -Wl,-rpath,"$M/lib" -lmujoco -lm
  echo "built tools/$N against $M"
fi
