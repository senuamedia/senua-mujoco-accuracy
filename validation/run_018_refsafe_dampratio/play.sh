#!/usr/bin/env bash
# Run 018, a patch in design (not registered): patches/in_design/refsafe_dampratio.diff, MuJoCo 3.16.0 with its
# stiffness guard under Euler (refsafe: time constant at least two steps) extended to the spring's own time constant,
# the time constant times the damping ratio, keeping the authored damping ratio (switch: MUJOCO_REFSAFE_DAMPRATIO=1).
# Finding F8 (run 017): under Euler a bouncy contact creates energy, and every play that does has the time constant
# times the damping ratio under the step. Three arms, each in its own scratch copy of the repository, the rigs built
# against:
#   release   Google DeepMind's Linux release (run 002's)
#   off       the patched build, switch unset
#   on        the patched build, MUJOCO_REFSAFE_DAMPRATIO=1
# each playing both of the first deep dive's contact suites under MuJoCo's defaults (and suite 1's ten verdicts), run
# 016's lift probe (120 slides), and run 017's two steps (28 drops under Euler with damping ratios 1, 0.5, 0.2, 0.1 at
# seven steps; the same 28 under the discrete integrator).
# The five checks, fixed before any play:
#   1 required     run 017: the release creates energy (a rebound above the drop) under Euler
#   2 correct      with the switch on, under Euler (run 017's step 1 drops), each judged by sx_contact rule:
#                    C1  no rebound above the drop, at any step, for damping ratios 0.5, 0.2 and 0.1
#                        (rule all_le 10000 over the seven rebounds, in parts of 10,000 of the drop)
#                    C2  MuJoCo's default damping ratio 1 still gives no bounce at any step (rule all_eq 0)
#                    C3  the bounce does not depend on the step, the first deep dive's T04: for each damping ratio the
#                        seven rebounds spread by at most 500 parts of 10,000 (rule le <spread> 500; the spread, the
#                        largest less the smallest, is plumbing)
#   3 nothing else gets worse   with the switch on, every play that is not one of the 21 Euler drops with a damping
#                  ratio under 1 is byte-identical to the release: both suites, run 016's 120 slides, run 017's
#                  discrete drops, and the damping ratio 1 drops
#   4 safe when off   the off arm plays every file byte for byte as the release
#   5 the solver keeps converging   with the switch on, no play at the iteration limit and no warning
# The patch passes only if all five hold.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh>   (repository root; RELEASE and PATCHED set
#        to the two MuJoCo install folders)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <runner folder>}")" && pwd)/$(basename "$1")"
M="$(cd "${2:?runner folder}" && pwd)"
O=validation/run_018_refsafe_dampratio; mkdir -p $O
ROOT=$(pwd)
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R tools $X/
  mkdir -p $X/validation/run_016_sliding_lift $X/validation/run_017_bounce_setting
  cp validation/run_016_sliding_lift/probe.sh $X/validation/run_016_sliding_lift/
  cp validation/run_017_bounce_setting/probe.sh validation/run_017_bounce_setting/probe_discrete.sh $X/validation/run_017_bounce_setting/
  (cd $X && for n in mjc_contact mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
   if [ -n "$sw" ]; then export MUJOCO_REFSAFE_DAMPRATIO=$sw; else unset MUJOCO_REFSAFE_DAMPRATIO; fi
   tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
   bash "$M/sx_contact_suite.sh" suites/1/defaults suites/1/defaults/verdicts.txt > /dev/null 2>&1
   bash validation/run_016_sliding_lift/probe.sh "$B"
   bash validation/run_017_bounce_setting/probe.sh "$B"
   bash validation/run_017_bounce_setting/probe_discrete.sh "$B")
  rm -rf $ROOT/$O/$name; mkdir -p $ROOT/$O/$name
  cp -R $X/validation/run_016_sliding_lift $X/validation/run_017_bounce_setting $X/suites $ROOT/$O/$name/
  rm -rf $X
  echo "arm $name played $(date -u +%FT%TZ)" >> $ROOT/$O/progress.txt
}
: > $O/progress.txt
arm release "$RELEASE"
arm off "$PATCHED"
arm on "$PATCHED" 1
# checks 3 and 4: every file of the off and on arms against the release arm's (the probes' finish times, finished*.txt,
# are clock readings and are not compared)
for a in off on; do
  ( cd $O && find release -type f ! -name 'finished*.txt' | sort | while read -r f; do
      g=$a/${f#release/}
      if [ ! -f "$g" ]; then echo "MISSING $g"; elif cmp -s "$f" "$g"; then echo "SAME ${f#release/}"; else echo "DIFFERS ${f#release/}"; fi
    done ) > $O/identity_$a.txt
done
# the rebounds of run 017's step 1 in one arm, for one damping ratio, in step order (plumbing)
rebounds() { grep "^solref 0.02 $2 1/" $O/$1/run_017_bounce_setting/reading.txt | sed 's/.*rebound_per_10000 //'; }
spread() { rebounds "$1" "$2" | awk 'NR == 1 { lo = $1; hi = $1 } { if ($1 < lo) lo = $1; if ($1 > hi) hi = $1 } END { print hi - lo }'; }
{
  for a in release on; do
    echo "== $a"
    for d in 0.5 0.2 0.1; do
      # shellcheck disable=SC2046
      "$B" rule "C1_$d" all_le 10000 $(rebounds $a $d) | tail -1
    done
    # shellcheck disable=SC2046
    "$B" rule C2_1 all_eq 0 $(rebounds $a 1) | tail -1
    for d in 1 0.5 0.2 0.1; do "$B" rule "C3_$d" le "$(spread $a $d)" 500 | tail -1; done
  done
  echo "== check 3: on against release, the files outside the 21 Euler drops with a damping ratio under 1"
  outside=$(grep -v -E 'run_017_bounce_setting/(runs/d0\.(5|2|1)_[0-9]+\.txt|runs/stats\.txt|reading\.txt)$' $O/identity_on.txt)
  echo "$outside" | awk '{ print $1 }' | sort | uniq -c
  "$B" rule check3 eq "$(echo "$outside" | grep -c -v '^SAME')" 0 | tail -1
  echo "== check 4: off against release, every file"
  awk '{ print $1 }' $O/identity_off.txt | sort | uniq -c
  "$B" rule check4 eq "$(grep -c -v '^SAME' $O/identity_off.txt)" 0 | tail -1
  echo "== check 5: the on arm's plays at the iteration limit, and its warnings"
  lim=$(cat $(find $O/on -name stats.txt) | grep -o 'at_iteration_limit [0-9]*' | awk '{ s += $2 } END { print s + 0 }')
  wrn=$(cat $(find $O/on -name stats.txt) | grep -o 'warnings [0-9]*' | awk '{ s += $2 } END { print s + 0 }')
  "$B" rule check5_limit eq "$lim" 0 | tail -1
  "$B" rule check5_warnings eq "$wrn" 0 | tail -1
} > $O/checks.txt
cat $O/checks.txt
