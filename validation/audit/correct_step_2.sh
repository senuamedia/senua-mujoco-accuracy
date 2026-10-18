#!/usr/bin/env bash
# correct_step_2.sh: the three kinds of registered measured line correct_step.sh cannot place by its label, corrected
# in each study's <name>_corrected.txt (made from the output itself where correct_step.sh made none):
#   - "off ..." lines of a study whose off arm's plays are not kept, because the study proved them byte-identical to
#     the release arm's: the release arm's line with the same label had the same old value, and gives its correction
#     (a line whose release twin had another old value is listed, and left);
#   - "axis <cone> <slip> <step> ... slid_um N" (Studies 4 and 6): the play reference/runs/axis<slip>_<cone>_<step>.txt;
#   - "elliptic free <dir> slid_um N" (Studies 4 and 6): the play reference/runs/free_elliptic_<dir>.txt.
# Prints "FIELD2 <output>: <label> slid_um <old> -> <new>" and "LEFT <output>: <line>" lines.
# usage: correct_step_2.sh <record root> <remeasure_step.sh output> <run folder>...
set -u
R="$(cd "${1:?usage: correct_step_2.sh <record root> <remeasure output> <run>...}" && pwd)"; M="${2:?}"; shift 2
for run in "$@"; do
  for o in $(find "$R/$run" -name "measured.txt" | sort); do
    rel="${o#$R/$run/}"; dir="$(dirname "$rel")"; if [ "$dir" = . ]; then dir=""; else dir="$dir/"; fi
    c="${o%.txt}_corrected.txt"; [ -f "$c" ] || cp "$o" "$c"
    # the reference plays' slid_um old -> new, for this output's folder
    awk -v run="$run" -v DIR="$dir" -F' [|] ' '/^CHANGED / { split($1, h, " "); if (h[2] != run || h[4] != "stop") next
        p = h[3]; if (index(p, DIR "reference/runs/") != 1) next; p = substr(p, length(DIR "reference/runs/") + 1); sub(/\.gz$/, "", p); sub(/\.txt$/, "", p)
        n = split($2, x, " "); split($3, y, " "); for (i = 1; i < n; i++) if (x[i] == "slid_um") print p "\t" x[i+1] "\t" y[i+1] }' "$M" > /tmp/c2ref.$$
    awk -F'\t' -v FN="$run/$rel" -v REF=/tmp/c2ref.$$ -v ORIG="$o" -v CORR="$c" '
      BEGIN { while ((getline l < REF) > 0) { split(l, a, "\t"); ref[a[1] SUBSEP a[2]] = a[3] }
              while ((getline l < ORIG) > 0) { n = split(l, w, " "); if (w[1] != "release") continue; lab = w[2]; for (i = 3; i <= n; i++) { if (w[i] == "slid_um") break; lab = lab " " w[i] }; for (i = 1; i < n; i++) if (w[i] == "slid_um") relold[lab] = w[i+1] }
              while ((getline l < CORR) > 0) { n = split(l, w, " "); if (w[1] != "release") continue; lab = w[2]; for (i = 3; i <= n; i++) { if (w[i] == "slid_um") break; lab = lab " " w[i] }; for (i = 1; i < n; i++) if (w[i] == "slid_um") relnew[lab] = w[i+1] } }
      { n = split($0, w, " "); line = $0; si = 0; for (i = 1; i < n; i++) if (w[i] == "slid_um") si = i
        if (si == 0) { print; next }
        v = w[si + 1]; nv = ""
        if (w[1] == "off") { lab = w[2]; for (i = 3; i < si; i++) lab = lab " " w[i]
          if ((lab in relold) && relold[lab] == v && (lab in relnew)) nv = relnew[lab]
          else if (lab in relold) { if (relold[lab] != v) printf "LEFT %s: %s (its release twin had %s)\n", FN, $0, relold[lab] > "/dev/stderr" } }
        else if (w[1] == "axis") { k = "axis" w[3] "_" w[2] "_" w[4] SUBSEP v; if (k in ref) nv = ref[k] }
        else if (w[1] == "elliptic" && w[2] == "free") { k = "free_elliptic_" w[3] SUBSEP v; if (k in ref) nv = ref[k] }
        if (nv != "" && nv != v) { printf "FIELD2 %s: %s slid_um %s -> %s\n", FN, w[1] " " w[2] " " w[3] " " w[4], v, nv > "/dev/stderr"; w[si + 1] = nv; line = w[1]; for (i = 2; i <= n; i++) line = line " " w[i] }
        print line }' "$c" > "$c.new" 2>> /tmp/c2log.$$
    mv "$c.new" "$c"; cmp -s "$c" "$o" && rm -f "$c"
  done
done
cat /tmp/c2log.$$ 2>/dev/null; rm -f /tmp/c2ref.$$ /tmp/c2log.$$
