#!/usr/bin/env bash
# rejudge_step.sh: every rule line of the record whose inputs the measure's correction (17 October 2026) changes,
# judged again by sx_contact rule with the corrected inputs. The corrections are correct_step.sh's FIELD lines: within
# a run, each old slid_um or came_back_um and its corrected value (an old value given two corrections in one run is
# not used, and listed). In a rule line every argument that is a corrected value of its run is replaced (a reference
# that is itself a measured distance is corrected with the rest), except all_within's tolerance N, which is never
# measured; each change is printed for reading. Prints, for each rule line it changes, "RULE <run> <file>: <name> <old verdict> -> <new
# verdict>" and the inputs before and after; and the counts.
# usage: rejudge_step.sh <record root> <correct_step.sh output> <sx_contact>
set -u
R="$(cd "${1:?usage: rejudge_step.sh <record root> <correct output> <sx_contact>}" && pwd)"; C="${2:?}"; B="${3:?}"
T=$(mktemp -d); nr=0; nch=0; nv=0
grep -E "^FIELD2? " "$C" | awk '{ f = $2; sub(/:$/, "", f); split(f, p, "/"); run = p[1] "/" p[2]; n = NF
  print run "\t" $(n - 2) "\t" $n }' | sort -u > "$T/map.tsv"
awk -F'\t' '{ k = $1 SUBSEP $2; if ((k in v) && v[k] != $3) bad[k] = 1; v[k] = $3 }
  END { for (k in v) { split(k, p, SUBSEP); if (k in bad) print "MAPCLASH " p[1] " " p[2] > "/dev/stderr"; else print p[1] "\t" p[2] "\t" v[k] } }' \
  "$T/map.tsv" > "$T/umap.tsv" 2> "$T/clash"
cat "$T/clash"; awk '{ print $2, $3 }' "$T/clash" > "$T/clashvals"
cut -f1 "$T/umap.tsv" | sort -u | while read -r run; do
  find "$R/$run" -name "rules*.txt" ! -name "*_corrected.txt" | while read -r rf; do
    awk -F'\t' -v r="$run" '$1 == r { print $2 "\t" $3 }' "$T/umap.tsv" > "$T/m.tsv"
    grep "^RULE " "$rf" | while IFS= read -r line; do
      verdict="${line##*: }"; body="${line% : *}"
      set -- $body; shift; name=$1; kind=$2; shift 2
      skip=0; only1=0
      case "$kind" in all_within|all_le|all_ge|all_eq|ge|le|eq) ;; *) continue ;; esac
      args=("$@"); changed=0; i=0; out=()
      for a in "${args[@]}"; do
        nvv=""
        if ! { [ "$kind" = all_within ] && [ $i = 1 ]; }; then
          nvv=$(awk -F'\t' -v a="$a" '$1 == a { print $2; exit }' "$T/m.tsv")
        fi
        if [ -n "$nvv" ]; then out+=("$nvv"); changed=1; else out+=("$a"); fi
        i=$((i + 1))
      done
      clashv=""; for a in "${args[@]}"; do grep -qx -- "$run $a" "$T/clashvals" && clashv="$clashv $a"; done
      [ -n "$clashv" ] && echo "RULE CLASH $run ${rf#$R/$run/}: $name has values with two corrections:$clashv"
      [ $changed = 1 ] || continue
      new=$("$B" rule "$name" "$kind" "${out[@]}" | tail -1)
      nverdict="${new##*: }"
      echo "RULE $run ${rf#$R/$run/}: $name $verdict -> $nverdict"
      echo "  before: ${args[*]}"
      echo "  after:  ${out[*]}"
    done
  done
done
rm -rf "${T:?}"
