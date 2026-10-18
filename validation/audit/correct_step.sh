#!/usr/bin/env bash
# correct_step.sh: the corrected readings of Senua AI's stop, accel and swing measures (the step read in nanoseconds,
# the distance slid added up exactly; 17 October 2026) written beside the record's outputs, from remeasure_step.sh's
# lines. An output stays as it was printed; where a correction changes it, the corrected copy is written beside it as
# <name>_corrected.txt. Two kinds of place, each only where the play file it came from is known:
#   - a whole reading line (STOP, ACCEL, SWING, SWINGQ ...) kept in an output: replaced by the corrected line, where
#     that old line comes from one corrected line in the run (else listed as AMBIGUOUS, and left);
#   - a measured line "<arm> <kind> <a> <b> ... slid_um N ..." whose label names its play file, <output's folder>/
#     <arm>/.../<kind>_<a>_<b>.txt: its slid_um and came_back_um from that file's corrected reading (a label and old
#     value that two of the folder's files give different corrections is listed as CLASH, and left).
# Prints "LINE <output>: <old> -> <new>", "FIELD <output>: <label> <field> <old> -> <new>", "CORRECTED <output>"; then,
# for the hand, every output line that still holds a changed play's old slid_um ("UNPLACED"), and every README line
# that quotes one ("PAGE").
# usage: correct_step.sh <record root> <remeasure_step.sh output>
set -u
R="$(cd "${1:?usage: correct_step.sh <record root> <remeasure output>}" && pwd)"; M="${2:?}"
T=$(mktemp -d)
awk -F' [|] ' '/^CHANGED / { split($1, h, " "); print h[2] "\t" h[3] "\t" h[4] "\t" $2 "\t" $3 }' "$M" > "$T/all.tsv"
cut -f1 "$T/all.tsv" | sort -u > "$T/runs"
while read -r run; do
  d="$R/$run"; [ -d "$d" ] || continue
  awk -F'\t' -v r="$run" '$1 == r' "$T/all.tsv" > "$T/run.tsv"
  find "$d" -type f -name "*.txt" ! -name "*_corrected.txt" -size -2000k | sort | while read -r o; do
    head -c 16 "$o" | grep -q "^CONTACT dt_ns" && continue
    grep -qaE "slid_um|came_back_um|STOP dt_ns|ACCEL dt_ns|SWING dt_ns|SWINGQ dt_ns" "$o" && echo "$o"
  done > "$T/outs"
  awk -F'\t' '{ k = $4; if (!(k in v)) v[k] = $5; else if (v[k] != $5) bad[k] = 1 }
    END { for (k in v) if (!(k in bad)) print k "\t" v[k]; for (k in bad) print k > "/dev/stderr" }' "$T/run.tsv" > "$T/lines.tsv" 2> "$T/ambig_lines"
  awk -F'\t' '{ no = split($4, x, " "); split($5, y, " ")
      for (i = 2; i <= no; i++) if (x[i] != y[i] && (x[i-1] == "slid_um" || x[i-1] == "came_back_um")) print $2 "\t" x[i-1] "\t" x[i] "\t" y[i] }' \
    "$T/run.tsv" | sort -u > "$T/fields.tsv"
  while read -r o; do
    rel="${o#$d/}"; dir="$(dirname "$rel")"; if [ "$dir" = . ]; then dir=""; else dir="$dir/"; fi
    awk -v DIR="$dir" -v FN="$run/$rel" -v LINES="$T/lines.tsv" -v FIELDS="$T/fields.tsv" '
      BEGIN { while ((getline l < LINES) > 0) { t = index(l, "\t"); old[substr(l, 1, t - 1)] = substr(l, t + 1) }
        # the field corrections, read here (not as a first input, which an empty table would make the output itself)
        while ((getline l < FIELDS) > 0) { split(l, a, "\t"); p = a[1]; if (index(p, DIR) != 1) continue
          p = substr(p, length(DIR) + 1); sub(/\.gz$/, "", p); sub(/\.txt$/, "", p)
          n = split(p, c, "/"); if (n < 2) continue; m = split(c[n], b, "_"); lab = c[1]; for (i = 1; i <= m; i++) lab = lab " " b[i]
          k = lab SUBSEP a[2] SUBSEP a[3]; if ((k in key) && key[k] != a[4]) clash[k] = 1; key[k] = a[4]; labs[lab] = 1 } }
      { line = $0
        # whole reading lines: each "STOP dt_ns ... <number>" (or ACCEL, SWING, SWINGQ) up to the next " | " or the end
        out = ""; s = line
        while (match(s, /(STOP|ACCEL|SWINGQ|SWING) dt_ns [^|]*[0-9]/)) {
          cand = substr(s, RSTART, RLENGTH)
          if (cand in old) { printf "LINE %s: %s -> %s\n", FN, cand, old[cand] > "/dev/stderr"; out = out substr(s, 1, RSTART - 1) old[cand] }
          else out = out substr(s, 1, RSTART + RLENGTH - 1)
          s = substr(s, RSTART + RLENGTH) }
        line = out s
        done = 0
        for (l in labs) if (index(line, l " ") == 1) {
          n = split(line, w, " ")
          for (i = 1; i < n; i++) { f = w[i]
            if (f == "slid_um" || f == "came_back_um") { k = l SUBSEP f SUBSEP w[i+1]
              if (k in clash) printf "CLASH %s: %s %s %s\n", FN, l, f, w[i+1] > "/dev/stderr"
              else if (k in key) { printf "FIELD %s: %s %s %s -> %s\n", FN, l, f, w[i+1], key[k] > "/dev/stderr"; w[i+1] = key[k]; done = 1 } } }
          if (done) { line = w[1]; for (i = 2; i <= n; i++) line = line " " w[i] }
          break }
        print line }' "$o" > "$T/o2" 2>> "$T/log"
    if ! cmp -s "$T/o2" "$o"; then c="${o%.txt}_corrected.txt"; cp "$T/o2" "$c"; echo "CORRECTED $run/$rel" >> "$T/log"; fi
  done < "$T/outs"
  cat "$T/log" 2>/dev/null; rm -f "$T/log"
  awk -F'\t' '$2 == "slid_um" { print "slid_um " $3 }' "$T/fields.tsv" | sort -u > "$T/oldvals"
  if [ -s "$T/oldvals" ]; then
    while read -r o; do c="${o%.txt}_corrected.txt"; [ -f "$c" ] || c="$o"
      grep -nwFf "$T/oldvals" "$c" 2>/dev/null | cut -c1-200 | sed "s|^|UNPLACED ${c#$R/}:|"
    done < "$T/outs"
    find "$d" -name "*.md" | while read -r p; do
      awk '{ print $2 }' "$T/oldvals" | while read -r v; do
        cv=$(echo "$v" | awk '{ s = $0; o = ""; while (length(s) > 3) { o = "," substr(s, length(s) - 2) o; s = substr(s, 1, length(s) - 3) } print s o }')
        grep -nwF -- "$cv" "$p" 2>/dev/null | cut -c1-160 | sed "s|^|PAGE ${p#$R/} ($v):|"
      done
    done
  fi
  while read -r a; do echo "AMBIGUOUS LINE $run: $a"; done < "$T/ambig_lines"
done < "$T/runs"
rm -rf "${T:?}"
