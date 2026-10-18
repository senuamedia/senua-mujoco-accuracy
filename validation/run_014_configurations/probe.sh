#!/usr/bin/env bash
# Run 014, design probe (not registered): which of MuJoCo's own options, taken together, pass every known-answer test
# this record plays, and at what cost? Runs 001, 003, 007 and 008 found the elliptic cone with noslip removes the creep
# and the direction, and RK4 keeps a free chain's energy; nothing has played them together. Three configurations:
#   A  cone=elliptic noslip=10                     (MuJoCo's default Euler integrator)
#   B  cone=elliptic noslip=10 integ=RK4
#   C  cone=elliptic noslip=10 integ=implicitfast
# each playing both of the first deep dive's contact suites, the hold (0.6 and 0.8 of the limit) and the slide along
# 0, 22.5 and 45 degrees at 2 ms, and the chain of run 007 (free and swinging) at 10 ms over 1, 4 and 16. The release,
# MuJoCo's defaults, is run 008's and run 007's. Read by the first deep dive's runner and Senua AI's measures.
# usage: probe.sh <sx_contact binary> <folder holding sx_contact_suite.sh>   (repository root, rigs built)
set -u
B="${1:?usage: probe.sh <sx_contact binary> <runner folder>}"; M="$(cd "${2:?runner folder}" && pwd)"
O=validation/run_014_configurations; mkdir -p $O
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
: > $O/reading.txt
for name in A B C; do
  case $name in
    A) cfg="cone=elliptic noslip=10" ;;
    B) cfg="cone=elliptic noslip=10 integ=RK4" ;;
    C) cfg="cone=elliptic noslip=10 integ=implicitfast" ;;
  esac
  W=$O/runs_$name; mkdir -p $W; S=$W/stats.txt; : > $S
  # shellcheck disable=SC2086
  tools/contact_suite.sh cfg_$name $cfg > /dev/null && tools/contact_suite2.sh cfg_$name $cfg > /dev/null
  bash "$M/sx_contact_suite.sh" suites/1/cfg_$name $W/suite1.txt > /dev/null 2>&1
  for dir in 0 22.5 45; do
    # shellcheck disable=SC2086
    tools/mjc_contact $W/slide_$dir.txt dt=0.002 h0=0 vx0=1 mu=0.4 secs=1 dir=$dir $cfg >> $S
    for frac in 0.6 0.8; do
      p=$(awk -v f=$frac 'BEGIN { printf "%.6f", f * 0.5 * 9.8 }')
      # shellcheck disable=SC2086
      tools/mjc_contact $W/hold_${dir}_$frac.txt dt=0.002 h0=0 mu=0.5 push=$p pushat=0.5 secs=2 dir=$dir $cfg >> $S
    done
  done
  integ=$(echo "$cfg" | grep -o 'integ=[A-Za-z0-9]*' || true)  # corrected after the run: [A-Za-z]* cut RK4 to RK
  for k in 1 4 16; do
    # shellcheck disable=SC2086
    tools/mjc_chain $W/free_$k.txt dt=$(dt_of $k) mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2 $integ >> $S
    # shellcheck disable=SC2086
    tools/mjc_chain $W/swing_$k.txt dt=$(dt_of $k) mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=1 angle1=0.4 angle2=-0.7 secs=2 $integ >> $S
  done
  {
    echo "== $name: $cfg"
    grep '^T[01][0-9]\|^SUITE' $W/suite1.txt
    for dir in 0 22.5 45; do
      echo "slide $dir | $($B stop $W/slide_$dir.txt | tail -1)"
      for frac in 0.6 0.8; do echo "hold $dir $frac | $($B creep $W/hold_${dir}_$frac.txt | tail -1)"; done
    done
    for k in 1 4 16; do
      echo "free chain 1/$k | $($B chain $W/free_$k.txt | tail -1)"
      echo "swinging chain 1/$k | $($B chain $W/swing_$k.txt | tail -1)"
    done
    for s in suites/1/cfg_$name/stats.txt suites/2/cfg_$name/stats.txt $S; do
      echo "solver over $(basename $(dirname $s))/$(basename $s): most iterations $(grep -o 'most_iterations [0-9]*' $s | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'), at the limit $(grep -o 'at_iteration_limit [0-9]*' $s | awk '{ n += $2 } END { print n + 0 }'), warnings $(grep -o 'warnings [0-9]*' $s | awk '{ n += $2 } END { print n + 0 }')"
    done
  } >> $O/reading.txt
done
