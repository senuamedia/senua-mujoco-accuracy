#!/usr/bin/env bash
# Run 022, step 1: the cause of ForwardTest.DiscreteStiffLegPress failing with the slip-aligned pyramid switched on
# (runs 020 and 021). legpress_trace.c plays the test's scene as the test does, against version 2's build; four plays:
#   off      switch unset (the test passes)
#   on       switch set (the test fails)
#   never    switch set, the model's sleep_tolerance 1e9, so the patch turns no contact
#   always   switch set, sleep_tolerance 1e-12, so the patch turns every contact that slips at all (as version 1 did)
# A diagnostic, not a check: sleep_tolerance is changed here only to see which contacts matter, never as a fix.
# usage: trace.sh <version 2 install folder>   (repository root, on the cloud machine)
set -u
MJ="${1:?usage: trace.sh <install folder>}"; O=validation/run_022_pyramid_v3; T=$O/trace; mkdir -p $T
cc -O2 -std=c11 -Wall -Wextra -I"$MJ/include" -o $T/legpress_trace $O/legpress_trace.c -L"$MJ/lib" -Wl,-rpath,"$MJ/lib" -lmujoco -lm
{
  env -u MUJOCO_SLIP_ALIGNED_PYRAMID $T/legpress_trace $T/log_off.txt
  MUJOCO_SLIP_ALIGNED_PYRAMID=1 $T/legpress_trace $T/log_on.txt
  MUJOCO_SLIP_ALIGNED_PYRAMID=1 $T/legpress_trace $T/log_never.txt 1e9
  MUJOCO_SLIP_ALIGNED_PYRAMID=1 $T/legpress_trace $T/log_always.txt 1e-12
} > $T/result.txt 2>&1
rm -f $T/legpress_trace
cat $T/result.txt
