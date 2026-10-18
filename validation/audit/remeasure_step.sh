#!/usr/bin/env bash
# remeasure_step.sh: every play file of the record read again by Senua AI's stop, accel and swing measures as they were
# (sx_contact before 17 October 2026) and as corrected (the step read in nanoseconds, and stop's distance added up
# exactly), in every run whose scripts call them. Prints one line a reading that the correction changes:
#   CHANGED <run folder> <play file> <measure> | <reading before> | <reading after>
# and, at the end, how many play files and readings were read and how many changed. Reads only; writes nothing in the
# record.
# usage: remeasure_step.sh <record root> <sx_contact before> <sx_contact corrected>
set -u
R="$(cd "${1:?usage: remeasure_step.sh <record root> <before> <after>}" && pwd)"; OLD="${2:?}"; NEW="${3:?}"
T=$(mktemp -d); nf=0; nr=0; nc=0
for d in "$R"/validation/run_*; do
  [ -d "$d" ] || continue
  # the measures this run's scripts call, and the windows accel was asked for
  uses=$(find "$d/" -name "*.sh" -exec cat {} + 2>/dev/null)
  st=0; ac=0; sw=0
  case "$uses" in *" stop "*) st=1 ;; esac
  case "$uses" in *" accel "*) ac=1 ;; esac
  case "$uses" in *" swing "*) sw=1 ;; esac
  [ $((st + ac + sw)) -eq 0 ] && continue
  wins=$(printf '%s\n' "$uses" | grep -oE 'accel [^ |]+ [0-9]+ [0-9]+' | awk '{ print $3 ":" $4 }' | sort -u)
  find "$d/" -type f \( -name "*.txt" -o -name "*.txt.gz" \) | sort | while read -r f; do
    case "$f" in *.gz) gzip -dc "$f" > "$T/p.txt" 2>/dev/null || continue ;; *) cp "$f" "$T/p.txt" ;; esac
    head -c 16 "$T/p.txt" | grep -q "^CONTACT dt_ns" || continue
    echo "FILE" >> "$T/count"
    m=""
    [ $st = 1 ] && m="$m stop"
    [ $sw = 1 ] && m="$m swing"
    for k in $m; do
      a=$("$OLD" $k "$T/p.txt" 2>&1 | tail -1); b=$("$NEW" $k "$T/p.txt" 2>&1 | tail -1); echo "R" >> "$T/count"
      [ "$a" != "$b" ] && echo "CHANGED ${d#$R/} ${f#$d/} $k | $a | $b"
    done
    if [ $ac = 1 ]; then
      for w in $wins; do
        a=$("$OLD" accel "$T/p.txt" "${w%:*}" "${w#*:}" 2>&1 | tail -1); b=$("$NEW" accel "$T/p.txt" "${w%:*}" "${w#*:}" 2>&1 | tail -1); echo "R" >> "$T/count"
        [ "$a" != "$b" ] && echo "CHANGED ${d#$R/} ${f#$d/} accel_${w%:*}_${w#*:} | $a | $b"
      done
    fi
  done
done
echo "play files read $(grep -c FILE "$T/count" 2>/dev/null || echo 0), readings $(grep -c '^R$' "$T/count" 2>/dev/null || echo 0)"
rm -rf "${T:?}"
