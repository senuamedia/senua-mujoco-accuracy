# Run 004: MuJoCo built from source gives the release's bytes

15 October 2026. Not registered: a check before any patch. Corrections to MuJoCo will be built from its source, so
the first question is whether a build from source, unchanged, plays exactly as Google DeepMind's release does. If it
does, every patched build can be checked against the release with its corrections off.

MuJoCo was built on run 002's Linux machine from the commit in [`UPSTREAM_COMMIT`](../../UPSTREAM_COMMIT)
(a892750516336d8358949f4518fcc4fbbd85beae, tag 3.16.0), with gcc 13.3.0, CMake 3.28.3 and Ninja, a Release build, its
own build files unchanged (examples, simulate and tests left out):

```
git clone --branch 3.16.0 --depth 1 https://github.com/google-deepmind/mujoco.git mujoco-src
cmake -S mujoco-src -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
  -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF -DCMAKE_INSTALL_PREFIX=<folder>
cmake --build build -j2 && cmake --install build
```

The rigs were built against it (`MUJOCO_DIR=<folder> tools/build_rig.sh`), run 002's
[`replay.sh`](../run_002_linux_replay/replay.sh) played run 001's probe scripts, and every file was compared with run
001's. Then the rigs were built against the release again.

## The result

**95 of 95 files are byte-identical** (`compare.txt`): the build from source plays as the release does on every
scene and step of run 001.

## After run 006

Run 006 corrected the contact rig (its height column had run one step behind the other columns). This run was played
with the rig as it stood; played today with the corrected rig, `replay.sh` would find the contact files shifted by one
line in that column against run 001's.
