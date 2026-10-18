#!/usr/bin/env bash
# Run 006: the contact rig's height column, corrected. Until this run the rig read the cube's position after mj_step,
# which MuJoCo leaves at the step's start, so the height ran one step behind the velocity and force columns (the
# first deep dive's rig and the Newton rig report the state the step ended in). The rig now recomputes the positions
# after each step (mj_kinematics), which changes nothing in the play. This plays runs 001, 003 and 005 again, unchanged
# but for the rig, in one scratch copy of the repository, and checks every run file against the one in the record:
#   SAME     byte-identical (expected: the joint plays, and the solver statistics without a direction)
#   SHIFTED  the header and every step's columns 1 and 3 to 6 byte-identical, and each step's height the height the
#            record has on the next line (expected: every contact play)
#   DIFFERS  anything else
# and every reading line against the record's.
# usage: MUJOCO_DIR=<release folder> validation/run_006_height_column/replay.sh <sx_contact binary>  (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: replay.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
R=validation/run_006_height_column
RUNS="run_001_design_probes run_003_cone_and_large_steps run_005_past_refsafe_and_free"
for n in mjc_contact mjc_joint; do tools/build_rig.sh $n; done
X=$(mktemp -d); mkdir -p $X/tools; cp tools/mjc_contact tools/mjc_joint $X/tools/
for run in $RUNS; do mkdir -p $X/validation/$run/runs; cp validation/$run/*.sh $X/validation/$run/; done
(cd $X && O=validation/run_001_design_probes &&
  bash $O/probe_01.sh "$B" > $O/reading.txt && for p in 02 03 04 04c; do bash $O/probe_$p.sh "$B" > $O/reading_$p.txt; done &&
  bash validation/run_003_cone_and_large_steps/probe.sh "$B" > validation/run_003_cone_and_large_steps/reading.txt &&
  bash validation/run_005_past_refsafe_and_free/probe.sh "$B" > validation/run_005_past_refsafe_and_free/reading.txt)
shifted() {  # <record's file> <new file>: SHIFTED or DIFFERS
  if [ "$(head -1 "$1")" != "$(head -1 "$2")" ] || [ "$(wc -l < "$1")" != "$(wc -l < "$2")" ]; then echo DIFFERS; return; fi
  awk 'NR == FNR { if (FNR > 1) { h[FNR] = $2; rest[FNR] = $1 " " $3 " " $4 " " $5 " " $6 } next }
       FNR > 1 { if (rest[FNR] != $1 " " $3 " " $4 " " $5 " " $6) bad++; if ((FNR + 1) in h && h[FNR + 1] != $2) bad++ }
       END { print (bad ? "DIFFERS" : "SHIFTED") }' "$1" "$2"
}
rm -rf $R/runs; mkdir -p $R/runs
{
  for run in $RUNS; do
    for f in validation/$run/runs/*.txt; do
      n=$(basename $f); g=$X/validation/$run/runs/$n
      if [ ! -f $g ]; then echo "MISSING $run $n"; continue; fi
      if cmp -s $f $g; then echo "SAME $run $n"; continue; fi
      case $n in stats*) echo "DIFFERS $run $n";; *) echo "$(shifted $f $g) $run $n";; esac
    done
    for r in $(cd validation/$run && ls reading*.txt | grep -v before_fix); do
      if cmp -s validation/$run/$r $X/validation/$run/$r; then echo "SAME $run $r"; else echo "DIFFERS $run $r"; fi
    done
    mkdir -p $R/runs/$run; cp -R $X/validation/$run/. $R/runs/$run/
  done
} > $R/compare.txt
rm -rf $X
for k in SAME SHIFTED DIFFERS MISSING; do echo "$k $(grep -c "^$k " $R/compare.txt)"; done
grep '^DIFFERS\|^MISSING' $R/compare.txt || true
