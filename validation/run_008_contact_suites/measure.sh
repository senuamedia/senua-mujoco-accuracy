#!/usr/bin/env bash
# Run 008's measuring: both of the first deep dive's contact suites, played on MuJoCo under two configurations.
#   suite 1: the first deep dive's own runner (senua-superdex-accuracy measure/runners/sx_contact_suite.sh, with Senua
#            AI's sx_contact beside it): the ten T-numbered tests and their verdicts, unchanged;
#   suite 2: the measures the first deep dive's seventh ledger used on it (stop, pair, accel), each line as measured.
# usage: measure.sh <folder holding sx_contact and sx_contact_suite.sh> <label ...>   (from the repository root)
set -u
M="${1:?usage: measure.sh <folder holding sx_contact and sx_contact_suite.sh> <label ...>}"; shift
B="$M/sx_contact"; O=validation/run_008_contact_suites
for l in "$@"; do
  bash "$M/sx_contact_suite.sh" suites/1/$l $O/suite1_$l.txt || echo "suite 1 $l: measuring incomplete"
  d=suites/2/$l
  {
    for run in stop land; do for k in 1 4 16 64; do echo "$run 1/$k | $($B stop $d/${run}_$k.txt | tail -1)"; done; done
    for k in 1 16; do
      echo "rest 1/$k | $($B pair $d/rest_${k}_a.txt $d/rest_${k}_b.txt | tail -1)"
      echo "carry 1/$k | $($B pair $d/carry_${k}_a.txt $d/carry_${k}_b.txt | tail -1)"
      echo "slip A 1/$k | $($B accel $d/slip_${k}_a.txt 700 900 | tail -1)"
      echo "slip B 1/$k | $($B accel $d/slip_${k}_b.txt 700 900 | tail -1)"
      echo "side 1/$k | $($B pair $d/side_${k}_a.txt $d/side_${k}_b.txt | tail -1)"
      echo "top 1/$k | $($B pair $d/top_${k}_a.txt $d/top_${k}_b.txt | tail -1)"
    done
  } > $O/suite2_$l.txt
done
