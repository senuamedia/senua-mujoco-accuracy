#!/usr/bin/env bash
# The audit's re-make (docs/audit.md): every run of the record played and measured again by its own script, in order,
# in a clean copy of the repository on the cloud machine, then every file of validation/ and suites/ compared byte for
# byte with a second clean copy, the record. Runs that need a build of MuJoCo get the one their README names:
#   the release      Google DeepMind's Linux release (runs 001 to 003, 005 to 010, 014 to 017, and the release arms)
#   the source build MuJoCo built from source, unchanged (run 004)
#   the pyramid      the slip-aligned pyramid's patched build (runs 011 to 013)
#   the guard        the guard-with-damping patched build (run 018)
# Run 001 was played on the Mac; run 002 showed Linux plays it byte for byte, so it is re-made on Linux here.
# Each run is played with the rigs as they were when it was recorded. Two rig changes alter a play: run 006 corrected
# mjc_contact's height column, and run 009 made mjc_pair's frictionless ground frictionless. So runs 001 to 005 play
# mjc_contact as of 1030574 (rigs/mjc_contact_1030574.c) and run 008 mjc_pair as of 8a36106 (rigs/mjc_pair_8a36106.c);
# every other change to the rigs only added options a play without them does not use.
# usage: remake.sh <sx_contact> <runner folder> <release> <source build> <pyramid build> <guard build> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_compare.txt and remake_log.txt)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; M="$(cd "${2:?}" && pwd)"
REL="${3:?}"; SRC="${4:?}"; PYR="${5:?}"; RSD="${6:?}"; REF="$(cd "${7:?}" && pwd)"
A=validation/audit; mkdir -p $A; L=$A/remake_log.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
rigs() { for n in mjc_contact mjc_pair mjc_chain mjc_joint mjc_rotvec; do MUJOCO_DIR=$1 tools/build_rig.sh $n > /dev/null; done; }
use() {  # use <rig> <source>: build tools/<rig> from an earlier source, the repository's own kept aside
  cp tools/$1.c $A/$1.head.c; cp "$2" tools/$1.c; MUJOCO_DIR=$REL tools/build_rig.sh $1 > /dev/null; }
unuse() { cp $A/$1.head.c tools/$1.c; rm $A/$1.head.c; MUJOCO_DIR=$REL tools/build_rig.sh $1 > /dev/null; }
export MUJOCO_DIR=$REL
rigs $REL; log "rigs built against the release"
use mjc_contact $A/rigs/mjc_contact_1030574.c; log "mjc_contact as of 1030574 for runs 001 to 005"
R=validation/run_001_design_probes
bash $R/probe_01.sh $B > $R/reading.txt
for p in 02 03 04 04c; do bash $R/probe_$p.sh $B > $R/reading_$p.txt; done; log "run 001"
bash validation/run_002_linux_replay/replay.sh $B > /dev/null 2>&1; log "run 002"
bash validation/run_003_cone_and_large_steps/probe.sh $B > validation/run_003_cone_and_large_steps/reading.txt; log "run 003"
# run 004: run 002's replay against the source build, its comparison set beside run 004's record
cp validation/run_002_linux_replay/compare.txt $A/run002_compare.keep
MUJOCO_DIR=$SRC bash validation/run_002_linux_replay/replay.sh $B > /dev/null 2>&1
cp validation/run_002_linux_replay/compare.txt $A/run004_compare_remade.txt
cp $A/run002_compare.keep validation/run_002_linux_replay/compare.txt; rm $A/run002_compare.keep
rigs $REL; log "run 004 (source build)"
bash validation/run_005_past_refsafe_and_free/probe.sh $B > validation/run_005_past_refsafe_and_free/reading.txt; log "run 005"
unuse mjc_contact; log "mjc_contact as now"
bash validation/run_006_height_column/replay.sh $B > /dev/null 2>&1; log "run 006"
bash validation/run_007_chain/probe.sh $B > validation/run_007_chain/reading.txt; log "run 007"
use mjc_pair $A/rigs/mjc_pair_8a36106.c; log "mjc_pair as of 8a36106 for run 008"
tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
tools/contact_suite.sh elliptic_noslip cone=elliptic noslip=10 > /dev/null
tools/contact_suite2.sh elliptic_noslip cone=elliptic noslip=10 > /dev/null
mkdir -p $A/m; cp $B $A/m/sx_contact; cp $M/sx_contact_suite.sh $A/m/
bash validation/run_008_contact_suites/measure.sh $A/m defaults elliptic_noslip > /dev/null 2>&1
bash validation/run_008_contact_suites/hover.sh $B; rm -rf $A/m; log "run 008"
unuse mjc_pair; log "mjc_pair as now"
bash validation/run_009_frictionless_ground/play.sh $B > validation/run_009_frictionless_ground/reading.txt 2>/dev/null; log "run 009"
bash validation/run_010_small_rotations/probe.sh $B > validation/run_010_small_rotations/reading.txt; log "run 010"
RELEASE=$REL PATCHED=$PYR bash validation/run_011_slip_aligned_pyramid/play.sh $B $M > /dev/null 2>&1; log "run 011"
RELEASE=$REL PATCHED=$PYR bash validation/run_012_study_01/play.sh $B > /dev/null 2>&1; log "run 012"
rigs $PYR
bash validation/run_013_noslip_with_aligned_pyramid/probe.sh $B > validation/run_013_noslip_with_aligned_pyramid/reading.txt
rigs $REL; log "run 013 (pyramid build)"
bash validation/run_014_configurations/probe.sh $B $M > validation/run_014_configurations/out.txt 2>&1; log "run 014"
bash validation/run_015_study_02/play.sh $B $M > /dev/null 2>&1; log "run 015"
bash validation/run_016_sliding_lift/probe.sh $B > validation/run_016_sliding_lift/out.txt 2>&1; log "run 016"
bash validation/run_017_bounce_setting/probe.sh $B > validation/run_017_bounce_setting/out.txt 2>&1
bash validation/run_017_bounce_setting/probe_discrete.sh $B > validation/run_017_bounce_setting/out_discrete.txt 2>&1; log "run 017"
RELEASE=$REL PATCHED=$RSD bash validation/run_018_refsafe_dampratio/play.sh $B $M > validation/run_018_refsafe_dampratio/out.txt 2>&1; log "run 018"
# every file of the record's validation/ and suites/ against the re-made copy; a file only the re-make wrote is NEW
{
  ( cd "$REF" && find validation suites -type f | sort ) | while read -r f; do
    case $f in validation/audit/*) continue ;; esac
    if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
  done
  find validation suites -type f | sort | while read -r f; do
    case $f in validation/audit/*) continue ;; esac
    [ -f "$REF/$f" ] || echo "NEW $f"
  done
} > $A/remake_compare.txt
log "compared: $(grep -c '^SAME' $A/remake_compare.txt) same, $(grep -c '^DIFFERS' $A/remake_compare.txt) differ, $(grep -c '^MISSING' $A/remake_compare.txt) missing, $(grep -c '^NEW' $A/remake_compare.txt) new"
