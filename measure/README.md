# The measuring side

The measuring programs of the Senua AI Robotics Core read what a rig wrote and decide the registered rules. Every
measuring program this record ran is in this folder. They are written in Simplex, the language Senua AI is built in,
and published so that every right answer and every tolerance can be read line by line. They do not build outside
Senua AI: the Simplex toolchain and the Senua AI engine are not distributed. What they printed is kept in the run
folders under [`../validation/`](../validation/), beside the raw plays they read.

## The Senua AI engine: two calls, nothing more

The programs are plain arithmetic on the rigs' text files. Of the Senua AI engine each uses only two calls, both in its
file reader, `xc_ints`, and each is commented where it is made with what it asks for, why, and what the engine returns:

| Call | What it asks for | What the engine returns |
|---|---|---|
| `os_file_access(path)` | Whether the rig's file exists, so a missing file is never read | 0 when it exists, anything else when it does not |
| `os_file_read_all(path, meta)` | The whole file, read into a buffer of the engine's own | The buffer (0 when the file cannot be read), with the number of bytes read written into `meta`; the program frees it |

In these published files the engine is named by one include line, `// use "senua_engine.sx"`, which stands where the
program as run names the engine's helper files, and the comments say what the two calls do; no line of code differs
from the program as run. The registrations cite the checksum of the program as run.

## What is here

| File | Used by | sha256 as run (cited) | sha256 as published here |
|---|---|---|---|
| [`registered/sx_contact_before_correction.sx`](registered/sx_contact_before_correction.sx) | Runs 001 to 090; Studies 3 to 20 cite it (Studies 1 and 2 name no checksum) | 87e921cd4d2c03bf... | 3e05661d4ad7a8fd... |
| [`registered/sx_contact_corrected.sx`](registered/sx_contact_corrected.sx) | Runs 091 to 097, Study 21: as corrected on 17 October 2026 | 804d51e14d2ade30... | 5d5343feb56800f4... |
| [`sx_contact.sx`](sx_contact.sx) | Runs 098 on, Studies 22 to 24: as corrected, with `fastest` | b1047b84134afc4f... | 8b354cd7eff0cb65... |
| [`runners/sx_contact_suite.sh`](runners/sx_contact_suite.sh) | Studies 10 and 12 to 15 and their probes: the contact suite, every run of one label read by `sx_contact` | 553d46ecdaf2bd95... | 161586e543ba6e69... |
| [`sx_tumble.sx`](sx_tumble.sx) | Run 039 on, Studies 9, 10 and 18: one free body tumbling | 21e07a0c3c3b21dc... | 62132a6212473dd2... |

The registrations before the correction cite the measure by `87e921cd...`; the build the record ran then carried one
reading more, `pairg`, which this record does not use, and makes the same readings (see [the audit](../docs/audit.md),
the measure corrected). The correction and every reading it changed are in the audit.

`sx_contact` and its suite runner were written for the first deep dive, Meta's SuperDex Physics, and are published
there too (`measure/` in [senuamedia/senua-superdex-accuracy](https://github.com/senuamedia/senua-superdex-accuracy)),
where the same programs carry the same code. Their header comments name that record's registrations and rigs (its
`sdx_contact` and the others); this record's rigs in [`../tools/`](../tools/) write the same file format, one line a
step, so the same readings apply.

## The readings this record uses

Each takes a rig's file and holds it to an answer that does not depend on the time step:

| Reading | What it reads | The right answer |
|---|---|---|
| `creep` | A cube pushed with less than friction can hold, an arm resting on its ball, a gripped cube | Its mean speed over the second half of the play: 0, it holds |
| `stop` | A cube that slides to a stop | Where it stopped: Coulomb's distance, v^2 / (2 mu g), the same along every direction |
| `hover` | A cube set sliding along the ground | It stays on the ground: the highest it rises while it slides |
| `final` | Any play | Its last state: a position, an angle, a speed, a depth |
| `fastest` | Any play, over its last steps | The largest speed there: a body at rest has none faster than the rule's bound |
| `ends` | Two plays of the same arm | How far apart they end: a scene written two ways ends in the same place |
| `gap` | Two bodies coupled by an equality | The largest gap between their motions: a coupling keeps them together |
| `pair`, `accel` | Two cubes that both move; one decelerating | Momentum kept, a carried cube rides; the deceleration Coulomb's law gives |
| `bounce`, `impact`, `rest`, `pull` | A cube dropped, landing, set down, lifted | A rebound that does not depend on the step; Coulomb's friction over an impact; the weight carried |
| `chain`, `swing` | Two arms on two joints; one swinging | Energy and angular momentum kept with nothing doing work; the swing comes back |
| `rotvec` | A small rotation | The angle times the axis, whatever the size |
| `tumble` (`sx_tumble`) | One free body tumbling with nothing acting on it | Its rotational energy and the magnitude of its angular momentum, kept exactly |
| `rule` | One registered rule and its numbers | Whether it held |

`sx_tumble` is plain arithmetic too: every sum of products is worked out exactly, as a whole number kept in base-1000
digits, and divided only once, at the end.
