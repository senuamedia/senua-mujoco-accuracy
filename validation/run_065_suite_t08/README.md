# Run 065: the first suite's refinement chain on Study 14's cube (a probe)

16 October 2026 (13:23 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh) and
[`probe_2.sh`](probe_2.sh), each pushed before its plays. It finds where to look and decides nothing.

In Study 14 the first contact suite's T08 (the refinement chain falls at every step) failed under Senua AI's
configuration on Study 14's suite cube, released and patched alike. The suite on that cube, on MuJoCo 3.16.0 as released
([`measured.txt`](measured.txt)), and on the de Saxce patch's fourth version with its switch set
([`step2/measured.txt`](step2/measured.txt)). T08's chain, um:

| | The ten tests | T08's chain | T08 |
|---|---|---|---|
| MuJoCo's defaults | 9 of 10 (T06, the hold) | 89,444, 22,157, 16,406, 7,985, 3,143, 3,041 | passes |
| The elliptic cone alone | 8 of 10 | 83,213, 25,898, 11,754, 6,154, 2,928, 3,469 | fails |
| The elliptic cone, 10 noslip iterations | 9 of 10 | the same | fails |
| The elliptic cone, 100 noslip iterations | 9 of 10 | the same | fails |
| The de Saxce patch, the elliptic cone alone | 9 of 10 | 34,526, 16,517, 8,197, 3,811, 2,013, 1,737 | passes |
| The de Saxce patch, the configuration (100 noslip iterations) | **10 of 10** | the same | passes |

**What it shows.** T08's failure is the elliptic cone's, whatever noslip does, and the de Saxce patch removes it: the
sliding cube's hop (issue 4) shows in the chain on this cube. Senua AI's configuration with the de Saxce patch passes all
ten tests here.
