# Run 033: the inverse weight in the current pose, second version

15 October 2026. Not registered: a patch in design, held to the five checks and MuJoCo's own test suite, every check
stated in [`play.sh`](play.sh) before any play. Played on the second cloud machine (4 virtual CPUs), with MuJoCo's
source at the pinned commit and its release test build made there (run 031).

**The result: 74 of 74 check lines held.** The second version ends the same arm in the same place whatever pose its
file was written in, for contacts as the first version did and now for a joint limit too, changes nothing else in this
record's plays or in MuJoCo's own suite, and is the release when off.

## The patch

[`patches/in_design/invweight_at_pose_v2.diff`](../../patches/in_design/invweight_at_pose_v2.diff) (sha256
0141e9bc36ff5bfc...), the first version (validated by Study 5 for contacts) with the joint weights of joint limits and
joint friction, `dof_invweight0`, also taken in the current pose, by the formula `mj_setConst` uses at `qpos0` (for a
hinge or slide joint, the joint's diagonal of inv(M); for a ball or free joint, the average over its directions; for a
body that only slides, 1/mass). Run 032 and run 034 found the written pose moving a swing on a joint limit by up to 1.24
mm and an arm held by joint friction by up to 32 mm. The stock lines are kept, and the at-pose value is assigned after
them only with the switch set: 90 lines added to `engine_core_constraint.c`, none removed. Both builds compiled with no
warning from the patched file (`patch_warnings.txt`, empty); `patch_check.txt`: the release's source with the patch.

## The five checks (`checks.txt`, every line a `sx_contact rule`)

Run 029's plays and checks, with run 032's swing on an elbow limit added, and the creep check's bound set at the
measure's resolution, both before any play.

| Check | Result |
|---|---|
| 1 Required | **Held.** Released, the arm on contact ends 13 to 65 um from its own writing when written straight; the swing on a limit 348 to 838 um |
| 2 Correct | **Held**, every line. On: every writing of the arm on contact within 2 nm and 1 um/s of the native, creeping within 1 um/s (852 and 851, 607 and 606 um/s); every writing of the swing on a limit **0 nm** and 0 um/s apart, where the release is 139 to 1,240 um apart |
| 3 Nothing else gets worse | **Held.** On: 171 of 171 files of both suites, the stacks, the slides and the grips byte-identical to the release; MuJoCo's suite, switch set against unset: no test changes |
| 4 Safe when off | **Held.** Off: 232 of 232 files byte-identical to the release; MuJoCo's whole suite test for test as the release |
| 5 The solver keeps converging | **Held.** On: no step at the iteration limit, no warning |

MuJoCo's suite passed all 3,492 tests in all three arms on this machine (15 GB of memory), the memory-hungry
`XMLReaderTest.LargeTextureAddressTest` included.

## Two more readings

- **On contacts the second version is the first.** With the switch on, every measured line of the arm on contact is
  the same as run 029's under the first version, and the release's lines are the same as run 029's, played on the other
  machine.
- **Joint friction** (run 034) is in the patch's scope but was not one of these plays; it is the next scene to hold the
  second version to, in a registered study.

## Next

A registered study on fresh numbers, with contacts, a joint limit and joint friction.
