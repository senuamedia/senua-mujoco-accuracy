#!/bin/bash
# The first deep dive's contact suite (its tools/contact_suite.sh), played on MuJoCo: the same scenes, steps and file
# names, so the first deep dive's measuring runner (measure/runners/sx_contact_suite.sh in senua-superdex-accuracy,
# with Senua AI's sx_contact beside it) reads MuJoCo's plays unchanged and gives the same T-numbered verdicts.
# usage: tools/contact_suite.sh <label> [rig setting ...]        (from the repository root)
#   the rig settings are applied to every run (for example: cone=elliptic noslip=10)
#   RIG=<binary> selects the rig (default tools/mjc_contact)
# writes suites/1/<label>/<run>_<k>.txt, k = the 10 ms step divided by k, with stats.txt and CONFIG.
# One difference from the first deep dive's suite: its fast rebound was played under SuperDex's BDF2 integrator; here
# it is played under MuJoCo's own default (or whatever integrator the rig settings name).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${1:?usage: tools/contact_suite.sh <label> [rig setting ...]}"
shift
EXTRA="$*"
T="${RIG:-$ROOT/tools/mjc_contact}"
OUT="$ROOT/suites/1/$LABEL"
mkdir -p "$OUT"
: > "$OUT/stats.txt"
echo "rig settings: ${EXTRA:-none}" > "$OUT/CONFIG"
# The scenes, as in the first deep dive's suite.
CUBE="${SUITE_CUBE:-mass=2 radius=0.04}"
H0="${SUITE_H0:-0.08}"            # drop height, m
VX="${SUITE_VX:-4}"               # sideways speed of the oblique impact, m/s
VXCHAIN="${SUITE_VXCHAIN:-1.5}"   # sideways speed of the refinement chain, m/s
MU="${SUITE_MU:-0.4}"             # friction of the oblique impact, the chain and the steady slide
VSLIDE="${SUITE_VSLIDE:-5}"       # speed of the steady slide, m/s
MUHOLD="${SUITE_MUHOLD:-0.5}"     # friction of the hold and slip tests
HOLD="${SUITE_HOLD:-5.88}"        # the hold push, N: 0.6 of what friction can hold
SLIP="${SUITE_SLIP:-11.76}"       # the slip push, N: 1.2 of what friction can hold
LIFT="${SUITE_LIFT:-58.8}"        # the lift, N: three times the weight
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
play() {  # play <name> <k> <settings...>
  local name="$1" k="$2"; shift 2
  # shellcheck disable=SC2086
  "$T" "$OUT/${name}_$k.txt" dt="$(dt_of "$k")" $CUBE "$@" $EXTRA | sed "s/^STATS/STATS run ${name}_$k/" >> "$OUT/stats.txt"
}
for k in 1 2 4 8 16 32 64; do
  play free $k h0=10 secs=1 vx0=$VXCHAIN mu=$MU           # never reaches the ground: the chain halves
  play drop $k h0=$H0 secs=0.5                             # the bounce must not depend on the step
  play oblique $k h0=$H0 secs=0.3 vx0=$VX mu=$MU          # Coulomb at impact: lost = friction x given
  play chain $k h0=$H0 secs=1 vx0=$VXCHAIN mu=$MU        # the refinement chain is in order
done
for k in 1 16; do
  play slide $k h0=0 secs=0.5 vx0=$VSLIDE mu=$MU          # steady sliding: friction = coefficient x normal
  play rest $k h0=0 secs=2                                 # at rest: the ground carries the weight
  play hold $k h0=0 secs=2 mu=$MUHOLD push=$HOLD pushat=0.5  # pushed with 0.6 of what friction holds: it does not move
  play slip $k h0=0 secs=2 mu=$MUHOLD push=$SLIP pushat=0.5  # pushed with 1.2 of it: it accelerates at (push - friction) / mass
  play lift $k h0=0 secs=0.4 lift=$LIFT liftat=0.3         # lifted with three times its weight: the ground never pulls
done
play rebound 16 h0=0.3 secs=0.5                            # a fast rebound: the ground never pulls
echo "played $(ls "$OUT"/*_[0-9]*.txt | wc -l | tr -d ' ') files under: ${EXTRA:-the defaults}"
