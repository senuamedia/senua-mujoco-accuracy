#!/usr/bin/env bash
# The audit's number trace (docs/audit.md): every specific number on the record's pages looked for, as written in the
# files, in the runs the line cites. Plumbing only: it reads text and measures nothing. A number is "specific" when it has
# at least three significant digits (a reading, not a count or a step label). Each page line's runs are the ones it links
# or names ("run 041", "runs 016 and 019", "Study 9"); a run's own README also cites its own run; a study page cites its
# study's run. A number is FOUND when it appears as a whole token in a text file of a cited run (READMEs aside), commas
# removed, its sign dropped; ELSEWHERE when it is not there but is in another run's files or the registrations; NOWHERE
# when it is in no file of the record but the pages (a derived figure, a unit conversion, or a mistake: each read by hand).
# The audit page itself (docs/audit.md), which reports these counts, is not traced.
# usage: trace_numbers.sh   (from the repository root; writes validation/audit/trace_numbers.txt)
set -u
A=validation/audit; T=$(mktemp -d); OUT=$A/trace_numbers.txt
STUDYRUN="1:012 2:015 3:023 4:024 5:030 6:031 7:035 8:038 9:040 10:042 11:044 12:051 13:058 14:064 15:071 16:077 17:080 18:081 19:085 20:087 21:091 22:099"   # the studies' index: study -> run
NUM='-?[0-9][0-9,]*(\.[0-9]+)?([eE]-?[0-9]+)?'
# 1. every specific number on the pages, with the runs its line cites: page:line <TAB> number <TAB> runs
PAGES="README.md $(ls docs/*.md docs/studies/*.md validation/run_*/README.md | grep -v '^docs/audit.md$')"   # the audit page reports on the others
for p in $PAGES; do
  own=""; case $p in validation/run_*/README.md) own=$(echo "$p" | sed -E 's|validation/run_([0-9]+)_.*|\1|') ;; esac
  case $p in docs/studies/[0-9]*) k=$(basename "$p" | sed -E 's/^0?([0-9]+)-.*/\1/'); for m in $STUDYRUN; do [ "${m%%:*}" = "$k" ] && own="${m#*:}"; done ;; esac
  awk -v page="$p" -v own="$own" -v map="$STUDYRUN" '
    BEGIN { n = split(map, mm, " "); for (i = 1; i <= n; i++) { split(mm[i], kv, ":"); srun[kv[1]] = kv[2] } }
    /^```/ { code = !code; next }
    code { next }
    {
      line = $0; runs = own
      s = line; while (match(s, /run_[0-9][0-9][0-9]/)) { runs = runs " " substr(s, RSTART + 4, 3); s = substr(s, RSTART + RLENGTH) }
      s = line; while (match(s, /[Rr]uns? [0-9][0-9][0-9]([,]? (and |to )?[0-9][0-9][0-9])*/)) {
        t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        while (match(t, /[0-9][0-9][0-9]/)) { runs = runs " " substr(t, RSTART, 3); t = substr(t, RSTART + 3) } }
      s = line; while (match(s, /Stud(y|ies) [0-9]+/)) { k = substr(s, RSTART, RLENGTH); sub(/Stud(y|ies) /, "", k); if (k in srun) runs = runs " " srun[k]; s = substr(s, RSTART + RLENGTH) }
      gsub(/\]\([^)]*\)/, "]", line); gsub(/`[^`]*`/, "", line)   # link targets and code spans are not readings
      s = line
      while (match(s, /-?[0-9][0-9,]*(\.[0-9]+)?([eE]-?[0-9]+)?/)) {
        x = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        gsub(/,/, "", x); sub(/^-/, "", x)
        d = x; gsub(/[^0-9]/, "", d); sub(/^0+/, "", d)
        if (length(d) < 3 || x ~ /^20[0-9][0-9]$/) continue
        print page ":" NR "\t" x "\t" runs
      }
    }' "$p"
done > "$T/claims"
cut -f2 "$T/claims" | sort -u > "$T/wanted"
# 2. for each run, which wanted numbers appear in its files (READMEs aside): run <TAB> number
for d in validation/run_*; do
  r=$(basename "$d" | sed -E 's/^run_([0-9]+)_.*/\1/')
  find "$d" -type f ! -name README.md ! -name '*.gz' -print0 | xargs -0 grep -IhoE -- "$NUM" 2>/dev/null \
    | sed 's/,//g; s/^-//' | sort -u | grep -Fxf "$T/wanted" | sed "s/^/$r\t/"
done > "$T/found"
{ cut -f2 "$T/found"; grep -ohE -- "$NUM" preregistrations/*.md | sed 's/,//g; s/^-//' | sort -u | grep -Fxf "$T/wanted"; } | sort -u > "$T/anywhere"
# 3. join: FOUND in a cited run, ELSEWHERE in the record's other files, NOWHERE in any
awk -F'\t' -v F="$T/found" -v E="$T/anywhere" '
  BEGIN { while ((getline l < F) > 0) { split(l, a, "\t"); in_run[a[1] SUBSEP a[2]] = 1 } while ((getline l < E) > 0) any[l] = 1 }
  { st = "NOWHERE"; n = split($3, rr, " "); for (i = 1; i <= n; i++) if ((rr[i] SUBSEP $2) in in_run) { st = "FOUND"; break }
    if (st != "FOUND" && ($2 in any)) st = "ELSEWHERE"
    print st "\t" $1 "\t" $2 "\t[runs " $3 "]" }' "$T/claims" > "$OUT"
rm -rf "$T"
for k in FOUND ELSEWHERE NOWHERE; do echo "$k $(grep -c "^$k" "$OUT")"; done
