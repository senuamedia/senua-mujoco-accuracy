#!/usr/bin/env bash
# Run 065: a design probe, not registered: it finds where to look and decides nothing. In Study 14 (run 064) the first
# contact suite's T08 (the refinement chain falls at every step) failed under Senua AI's configuration on Study 14's
# fresh cube, released and with the patch alike: its last refinement rose. Is it the configuration's 100 noslip
# iterations (Study 13) or the configuration as Study 2 set it (10)? The first suite on Study 14's cube, on MuJoCo 3.16.0
# as released, under MuJoCo's defaults, the elliptic cone alone, and the elliptic cone with 10 and with 100 noslip
# iterations. Readings: the first deep dive's suite runner.
# usage: probe.sh <folder holding sx_contact_suite.sh> <work folder>   (repository root, on the cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; O="$R/validation/run_065_suite_t08"
date -u +%FT%TZ > "$O/played_at.txt"
X="$W/p65"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
( cd "$X" && MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_contact > /dev/null 2>&1
  for c in def: ell:cone=elliptic n10:cone=elliptic\ noslip=10 n100:cone=elliptic\ noslip=100; do
    cn=${c%%:*}; opts=${c#*:}
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=1.7 radius=0.0426" SUITE_H0=0.07 SUITE_VX=3.36 SUITE_VXCHAIN=1.45 SUITE_MU=0.413 \
        SUITE_VSLIDE=4.53 SUITE_MUHOLD=0.443 SUITE_HOLD=4.428228 SUITE_SLIP=8.856456 SUITE_LIFT=49.98
      tools/contact_suite.sh $cn $opts > /dev/null )
  done )
rm -rf "${O:?}/suites"; cp -R "$X/suites" "$O/"; rm -rf "${X:?}"
for cn in def ell n10 n100; do
  SUITE_MU10K=4130 SUITE_SLIPMN=8856 bash "$M/sx_contact_suite.sh" "$O/suites/1/$cn" "$O/suite1_$cn.txt" > /dev/null 2>&1
done
{ for cn in def ell n10 n100; do echo "$cn: $(grep '^SUITE passed' "$O/suite1_$cn.txt") | $(grep '^T08' "$O/suite1_$cn.txt")"; done; } > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
