# Run 080: Study 17, MuJoCo's own frictionless contact

17 October 2026 (02:58 UTC). The seventeenth registered study,
[`PREREGISTRATION_17.md`](../../preregistrations/PREREGISTRATION_17.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 13220b628db1318e...), from an archive of the registration's commit
(8b79cbf). The rule lines are in [`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in
[`draw.txt`](draw.txt).

## Result: 12 of 12 rule lines held

A fresh cube (1.505 kg, half-size 43.7 mm) was set sliding at 0.91 m/s for 2 s on a ground of friction 0, at 1.74 and
0.435 ms, along 0, 22.5 and 45 degrees, kept from turning and free to turn.

| | MuJoCo's defaults | Senua AI's configuration |
|---|---|---|
| condim 1: speed lost, all 12 slides | **0 um/s** | **0 um/s** |
| condim 1: off its line; above the ground | **0 um; 0 um** | **0 um; 0 um** |
| condim 3, friction 0: speed lost along 0, 22.5 and 45 degrees | 196, 181 and 139 um/s | 196 um/s along each |
| condim 3: off its line along 22.5 degrees | 75 um | 0 um |
| The solver | never at the limit, no warning | never at the limit, no warning |

With condim 1 the cube keeps its speed, its line and its place on the ground in every play, at both steps, free to turn
or not (F1, F2, F3). With condim 3 and a friction of 0, every slide loses speed (Q1). Along an axis it loses exactly the
196 um/s that a friction of 1e-5 takes in 2 s (1e-5 times g times the time): MuJoCo's least friction, `mjMINMU`.

Reported, not ruled: under MuJoCo's default pyramidal cone, that least friction depends on the slide's direction (181
um/s at 22.5 degrees and 139 at 45, and 75 um of drift at 22.5). That is issue 2's direction-dependent friction, at a
friction of 1e-5. Under the elliptic cone it is the same along every direction.

## What it decides

As registered: **issue 12, a friction of 0 is raised to 1e-5, is fixed and validated by configuration.** A
frictionless contact is MuJoCo's own condim 1, under MuJoCo's defaults and under Senua AI's configuration. A friction of
0 under condim 3 stays 1e-5, by MuJoCo's design.

Not decided: condim 1 between two moving bodies (run 009, a probe); the patches' arms; anything against a real robot.
