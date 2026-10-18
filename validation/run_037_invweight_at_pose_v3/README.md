# Run 037: the inverse weight in the current pose, third version

15 October 2026. Not registered: a patch in design, held to the five checks and MuJoCo's own test suite, every check
stated in [`play.sh`](play.sh) before any play. Played on the second cloud machine (4 virtual CPUs).

**The result: 94 of 94 check lines held.** The third version ends the same arm in the same place whatever pose its
file was written in, on contact, swinging on a joint limit and now held by a `connect` equality too, changes nothing
else in this record's plays or in MuJoCo's own suite, and is the release when off.

## The patch

[`patches/in_design/invweight_at_pose_v3.diff`](../../patches/in_design/invweight_at_pose_v3.diff) (sha256
d3fd45cc3d3ecfb0...): the second version (validated by Study 7 for contacts, joint limits and joint friction), with the
body weights of `connect` and `weld` equalities also taken in the current pose, by the first version's helper, the
stock lines kept. Run 036 found a ball held by a `connect` sagging 209 to 310 um by writing. 104 lines added to
`engine_core_constraint.c`, none removed. Both builds compiled with no warning from the patched file
(`patch_warnings.txt`, empty).

## The five checks (`checks.txt`, every line a `sx_contact rule`)

Run 033's plays and checks, with run 036's held ball (the arm's ball held by a `connect` to where it starts, poses E
and F, written three ways, 2 and 0.5 ms) added to checks 1 and 2 with the same bounds, before any play.

| Check | Result |
|---|---|
| 1 Required | **Held.** Released, written straight: the arm on contact 13 to 65 um from its own writing, the swing on a limit 348 to 838 um, the held ball 52.6 and 100.7 um |
| 2 Correct | **Held**, every line. On: every writing of the arm on contact within 2 nm and 1 um/s of the native, creeping within 1 um/s; the swing on a limit and the held ball **0 nm** and 0 um/s apart |
| 3 Nothing else gets worse | **Held.** On: 171 of 171 files of both suites, the stacks, the slides and the grips byte-identical to the release; MuJoCo's suite, switch set against unset: no test changes |
| 4 Safe when off | **Held.** Off: 244 of 244 files byte-identical to the release; MuJoCo's whole suite test for test as the release |
| 5 The solver keeps converging | **Held.** On: no step at the iteration limit, no warning |

MuJoCo's suite passed all 3,492 tests in all three arms. With the switch on, every measured line of the arm on contact,
of its creep and of the swing on a limit is the same as run 033's under the second version: the third version changes
only what it adds.

## Next

A registered study on fresh numbers, with contacts, a joint limit, joint friction and an equality. A `weld` is changed
by the patch but no rig of this record plays one; such a study would state that it is not asked.
