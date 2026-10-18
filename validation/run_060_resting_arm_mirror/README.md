# Run 060: the resting arms mirrored (a probe)

16 October 2026 (12:20 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed
before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt).

[Run 059](../run_059_resting_arm_impratio/README.md) found that the elliptic cone's noslip removes the resting arm's slide
on Study 13's arm in its first pose, where the ball slips toward +x, and not on the three other contacts, where it slips
toward -x. Each arm's poses played as written and mirrored about the vertical plane through the shoulder, (pi - q1,
-q2), the same scene with x reversed; on MuJoCo 3.16.0 as released, 2 s at 1.14 ms, under MuJoCo's defaults, the
elliptic cone alone, the configuration with 10 and 100 noslip iterations, and the pyramidal cone with 10.

**Every mirrored play is the play as written with x reversed**, to the micrometre a second: the same creep and slip, the
other way. Noslip under the elliptic cone removes the slide of Study 13's first pose both ways, and leaves the other three
poses sliding both ways; the pyramidal cone with noslip holds all eight at 0.

**What it shows.** The direction of the slip does not decide it: run 059's pattern by direction was a coincidence of the
four poses. The pose does; why is not traced.
