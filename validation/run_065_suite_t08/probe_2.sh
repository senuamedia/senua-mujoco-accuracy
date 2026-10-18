#!/usr/bin/env bash
# Run 065, step 2, written after step 1's readings and pushed before its plays: step 1 found T08 failing under the
# elliptic cone alone and with 10 or 100 noslip iterations alike (the same chain), and passing under MuJoCo's defaults.
# The elliptic cone makes a sliding cube hop (issue 4), which the de Saxce patch removes (Study 12). The same suite on
# Study 14's cube, under the configuration (the elliptic cone, 100 noslip iterations) and the elliptic cone alone, on
# the de Saxce patch's fourth version with its switch set (Study 12's build).
# usage: probe_2.sh <folder holding sx_contact_suite.sh> <work folder>   (repository root, on the cloud machine; the work
#        folder holds Study 12's build in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; O="$R/validation/run_065_suite_t08/step2"
mkdir -p "$O"; date -u +%FT%TZ > "$O/played_at.txt"
X="$W/p65s2"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
( cd "$X" && MUJOCO_DIR="$W/mujoco-s12-build" tools/build_rig.sh mjc_contact > /dev/null 2>&1
  export MUJOCO_DESAXCE=1
  for c in ell:cone=elliptic n100:cone=elliptic\ noslip=100; do
    cn=${c%%:*}; opts=${c#*:}
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=1.7 radius=0.0426" SUITE_H0=0.07 SUITE_VX=3.36 SUITE_VXCHAIN=1.45 SUITE_MU=0.413 \
        SUITE_VSLIDE=4.53 SUITE_MUHOLD=0.443 SUITE_HOLD=4.428228 SUITE_SLIP=8.856456 SUITE_LIFT=49.98
      tools/contact_suite.sh desaxce_$cn $opts > /dev/null )
  done )
rm -rf "${O:?}/suites"; cp -R "$X/suites" "$O/"; rm -rf "${X:?}"
for cn in ell n100; do
  SUITE_MU10K=4130 SUITE_SLIPMN=8856 bash "$M/sx_contact_suite.sh" "$O/suites/1/desaxce_$cn" "$O/suite1_desaxce_$cn.txt" > /dev/null 2>&1
done
{ for cn in ell n100; do echo "desaxce $cn: $(grep '^SUITE passed' "$O/suite1_desaxce_$cn.txt") | $(grep '^T08' "$O/suite1_desaxce_$cn.txt")"; done; } > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
