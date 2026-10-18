#!/usr/bin/env bash
# Run 002: run 001's four probe scripts played again, unchanged, on another machine and operating system (Linux
# x86-64, Google DeepMind's Linux release of MuJoCo 3.16.0), in a scratch copy of the repository so run 001 is not
# touched; then every run file compared byte for byte with run 001's, and every reading line with run 001's.
# usage: MUJOCO_DIR=<release folder> validation/run_002_linux_replay/replay.sh <sx_contact binary>   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: replay.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_001_design_probes; R=validation/run_002_linux_replay
for n in mjc_contact mjc_joint; do tools/build_rig.sh $n; done
X=$(mktemp -d); mkdir -p $X/tools $X/$O/runs
cp tools/mjc_contact tools/mjc_joint $X/tools/
cp $O/probe_0*.sh $X/$O/
(cd $X && bash $O/probe_01.sh "$B" > reading.txt && for p in 02 03 04 04c; do bash $O/probe_$p.sh "$B" > reading_$p.txt; done)
rm -rf $R/runs; mv $X/$O/runs $R/runs; mv $X/reading*.txt $R/; rm -rf $X
{
  for f in $O/runs/*.txt; do
    n=$(basename $f)
    if [ ! -f $R/runs/$n ]; then echo "MISSING $n"; elif cmp -s $f $R/runs/$n; then echo "SAME $n"; else echo "DIFFERS $n"; fi
  done
  for f in $R/runs/*.txt; do [ -f $O/runs/$(basename $f) ] || echo "NEW $(basename $f)"; done
  for r in reading.txt reading_02.txt reading_03.txt reading_04.txt reading_04c.txt; do
    if cmp -s $O/$r $R/$r; then echo "SAME $r"; else echo "DIFFERS $r"; fi
  done
} > $R/compare.txt
grep -c '^SAME' $R/compare.txt | sed 's/^/same: /'; grep -v '^SAME' $R/compare.txt || true
