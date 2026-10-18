#!/usr/bin/env bash
# measure/runners/sx_contact_suite.sh -- the contact suite's measuring: every run of one
# configuration (the public rig's tools/contact_suite.sh, suites/1/<label>/), each against its right answer.
# usage: sx_contact_suite.sh <suite dir of one label> <out file>      (sx_contact built beside this script)
# exit 0 = every line was written (PASS or FAIL of each test is in the file)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="${1:?usage: sx_contact_suite.sh <suite dir> <out file>}"; OUT="${2:?out file}"
B="$HERE/sx_contact"; BASE=10000000
MU10K="${SUITE_MU10K:-4000}"     # friction of the oblique impact and the slide, per 10,000
SLIPMN="${SUITE_SLIPMN:-11760}"   # the slip push, mN
: > "$OUT"
[ -f "$D/CONFIG" ] && sed 's/^/CONFIG /' "$D/CONFIG" >> "$OUT"
bad=0
m() {  # m <label> <measure> <args...>: one measured line, labelled; echoes the line
  local label="$1"; shift
  local line; line="$("$B" "$@")"; [ $? -eq 42 ] || { echo "failed: $*" >&2; bad=1; }   # a Simplex program exits 42 when it ran
  echo "$label | $line" >> "$OUT"; echo "$line"
}
f() { echo "$1" | awk -v n="$2" '{print $n}'; }
ks="1 2 4 8 16 32 64"
chain() { local s="$1" out=""; for k in 1 2 4 8 16 32; do out="$out $(f "$(m "$s 1/$k against 1/$((k*2))" gap $BASE "$D/${s}_$k.txt" "$D/${s}_$((k*2)).txt")" 12)"; done; echo "$out"; }
gf="$(chain free)"
sl="$(f "$(m "slide 1/1" creep "$D/slide_1.txt")" 9) $(f "$(m "slide 1/16" creep "$D/slide_16.txt")" 9)"
l="$(m "rest 1/1" rest "$D/rest_1.txt")"; rs="$(f "$l" 5)"; w="$(f "$l" 7)"; rs="$rs $(f "$(m "rest 1/16" rest "$D/rest_16.txt")" 5)"
reb=""; for k in $ks; do reb="$reb $(f "$(m "drop 1/$k" bounce "$D/drop_$k.txt")" 13)"; done
imp=""; slidemin=""
for k in $ks; do l="$(m "oblique 1/$k" impact "$D/oblique_$k.txt")"; imp="$imp $(f "$l" 11)"; v="$(f "$l" 15)"; if [ -z "$slidemin" ] || [ "$v" -lt "$slidemin" ]; then slidemin="$v"; fi; done
st=""; for k in $ks; do st="$st $(f "$(m "settle 1/$k" settle "$D/oblique_$k.txt")" 11)"; done
hd="$(f "$(m "hold 1/1" creep "$D/hold_1.txt")" 7) $(f "$(m "hold 1/16" creep "$D/hold_16.txt")" 7)"
l="$(m "slip 1/1" slip "$D/slip_1.txt" "$SLIPMN")"; sp="$(f "$l" 5)"; pred="$(f "$l" 7)"; sp="$sp $(f "$(m "slip 1/16" slip "$D/slip_16.txt" "$SLIPMN")" 5)"
gc="$(chain chain)"
pl="$(f "$(m "lift 1/1" pull "$D/lift_1.txt")" 5) $(f "$(m "lift 1/16" pull "$D/lift_16.txt")" 5) $(f "$(m "rebound 1/16" pull "$D/rebound_16.txt")" 5)"
if [ $bad -ne 0 ]; then echo "measuring incomplete" >&2; exit 1; fi
# shellcheck disable=SC2086
"$B" suite "$MU10K" $gf $sl $rs $w $reb $imp $slidemin $hd $sp $pred $gc $pl $st >> "$OUT"
[ $? -eq 42 ] || exit 1
exit 0
