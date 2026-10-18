#!/usr/bin/env bash
# Run 020: MuJoCo's own test suite, the check a maintainer would run before merging the slip-aligned pyramid
# (patches/slip_aligned_pyramid.diff, validated by Study 1). MuJoCo's googletest suite is built from its source at the
# commit in UPSTREAM_COMMIT, with its own build files and options (tests on; examples, simulate and the Python test
# utility off, as in run 004), twice: from the release source, and from the same source with the patch applied. ctest
# then runs every test three times:
#   release   the release source's build
#   off       the patched build, MUJOCO_SLIP_ALIGNED_PYRAMID unset
#   on        the patched build, MUJOCO_SLIP_ALIGNED_PYRAMID=1
# Each test's result is taken from ctest's own report (its JUnit file). Expected: off as release, test for test; with
# the switch on, any test that pins the default pyramid's frame along the contact's own tangents may change, and any
# other change is a finding.
# Step 0: the patched source tree is the release tree with exactly the patch applied (patch_check.txt).
# usage: play.sh <folder holding mujoco-src and mujoco-patched-src>   (repository root, on the cloud machine)
set -u
W="$(cd "${1:?usage: play.sh <work folder>}" && pwd)"; R="$(pwd)"; O="$R/validation/run_020_mujoco_test_suite"
mkdir -p "$O"; J=$(nproc)
# step 0: the release source at the pinned commit, and the patched source as that plus exactly the patch, compared
# without the in-tree build folders an earlier build left (the first start compared them too; patch_check.sh)
rm -rf "$W/t20-check" && mkdir -p "$W/t20-check" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/t20-check"
(cd "$W/t20-check" && patch -p1 -s < "$R/patches/slip_aligned_pyramid.diff")
{
  echo "release source commit $(git -C "$W/mujoco-src" rev-parse HEAD), UPSTREAM_COMMIT $(cat "$R/UPSTREAM_COMMIT")"
  if [ -n "$(git -C "$W/mujoco-src" status --porcelain)" ]; then echo "DIFFERS the release source has local changes"; fi
  if diff -r -x .git -x build "$W/t20-check" "$W/mujoco-patched-src" > "$O/patch_check_diff.txt"; then
    echo "SAME the patched source is the release source with patches/slip_aligned_pyramid.diff applied"
  else
    echo "DIFFERS the patched source is not the release source plus the patch (patch_check_diff.txt)"
  fi
} > "$O/patch_check.txt"
rm -rf "$W/t20-check"
build() {  # <source> <build folder> <label>
  local t0 t1
  t0=$(date +%s)
  cmake -S "$1" -B "$2" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_SIMULATE=OFF \
    -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF > "$O/build_$3.log" 2>&1 && cmake --build "$2" -j"$J" >> "$O/build_$3.log" 2>&1
  local rc=$?; t1=$(date +%s)
  echo "build $3 exit $rc seconds $((t1 - t0)) warnings $(grep -c 'warning:' "$O/build_$3.log")" >> "$O/progress.txt"
}
suite() {  # <build folder> <label> [switch]
  local t0 t1 rc
  t0=$(date +%s)
  ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$3; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
    ctest --timeout 900 -j"$J" --output-junit "$O/junit_$2.xml" > "$O/ctest_$2.txt" 2>&1 )
  rc=$?; t1=$(date +%s)
  echo "suite $2 exit $rc seconds $((t1 - t0)) $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1)" >> "$O/progress.txt"
}
: > "$O/progress.txt"
build "$W/mujoco-src" "$W/t20-release" release
build "$W/mujoco-patched-src" "$W/t20-patched" patched
suite "$W/t20-release" release
suite "$W/t20-patched" off
suite "$W/t20-patched" on 1
# each test's result in each arm, from ctest's JUnit report: "<name> <passed|failed|skipped|...>" (plumbing)
for a in release off on; do
  sed -n 's/.*<testcase name="\([^"]*\)".*status="\([a-z]*\)".*/\1 \2/p' "$O/junit_$a.xml" | sort > "$O/results_$a.txt"
done
{
  for a in release off on; do echo "$a: $(wc -l < "$O/results_$a.txt") tests; $(awk '{ n[$2]++ } END { for (s in n) printf "%s %d ", s, n[s] }' "$O/results_$a.txt")"; done
  echo "== off against release"; diff "$O/results_release.txt" "$O/results_off.txt" && echo "every test the same"
  echo "== on against off"; diff "$O/results_off.txt" "$O/results_on.txt" && echo "every test the same"
} > "$O/compare.txt"
date -u +%FT%TZ > "$O/finished.txt"
