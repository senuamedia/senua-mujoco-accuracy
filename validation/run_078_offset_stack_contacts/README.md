# Run 078: the contacts of offset stacks (a probe)

17 October 2026 (02:17 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed
before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt). Each play's
contact changes are in `plays/*.events`, and its contacts trace in `plays/*.contacts.gz`.

Issue 9 (F11) says an offset stack leans. In run 075 and Study 16's dry run, a stack of 3 cubes each 1 mm over from the
one below leaned about 2.2 mrad under Senua AI's configuration, released and with the collinear patch alike, and its
contacts changed hundreds of times. Under MuJoCo's defaults it leaned 86 urad with no change. MuJoCo 3.16.0 as released
plays run 063's cube (Study 10's), traced by the stack rig's contacts setting (run 069). It plays stacks of 3 offset by
1 mm and by 17 mm a cube, 2 s, at 0.285 and 1.14 ms, under three option sets: the configuration, the elliptic cone
alone, and MuJoCo's defaults.

## What it shows

| Offset a cube | MuJoCo's defaults | The elliptic cone alone | The configuration |
|---|---|---|---|
| 1 mm: the most tilt | 86 urad | 393 and 404 urad | 2,180 and 2,262 urad |
| 17 mm: the most tilt | 1,943 urad | 9,061 and 9,267 urad | 9,363 and 9,657 urad |
| Contacts a face between two cubes, at step 1000 | 4 | 4 | 6 |
| Changes in a face's contacts after step 30 | none | none | 51 to 346 a play |
| A face's depth, cube on cube, step 1000 | 38 to 76 um | 205 to 367 um | 141 to 300 um |

Most of an offset stack's lean comes with the elliptic cone, which sinks the cubes 3 to 5 times deeper than the default
cone (run 069), so the offset load presses one edge further in. Released, that is 9.1 to 9.3 mrad at a 17 mm offset,
against 1.9 mrad under the defaults. Noslip adds the contact changes, and at a 1 mm offset more than five times the lean.

Under the configuration each face between two cubes carries 6 contacts, not 4. Some lie part way along the edges whose
ends coincide with the face below, at y = +/-42.4 mm, for example at x = -10.7 mm on the stack's middle face. Some come in
pairs 0.18 mm apart near a corner where the offset face is clipped. The count goes 6, 5, 4 and back from step to step.
Run 075 found the collinear patch reducing these changes but not removing them (279 against 346 at 1 mm, 0.285 ms) and
the lean the same. So the offset stack needs its own look: which of its points the clip makes, and why noslip moves
them.
