#!/usr/bin/env bash
# Run 020's comparison, from ctest's own report of each test (ctest_<arm>.txt): every test as "<number> <name> <result>",
# the name cut before "  # GetParam()", whose printed parameters include memory addresses that change from one run to
# the next. play.sh's first comparison took the JUnit file's names whole, so those addresses made tests look different
# between arms; this replaces results_*.txt and compare.txt. Plumbing: it reads ctest's words, it judges nothing.
# usage: compare.sh   (from the repository root)
set -u
O=validation/run_020_mujoco_test_suite
for a in release off on; do
  awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num)
         rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st)
         }
         name = rest
         p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ...."); if (p > 0) name = substr(name, 1, p - 1)
         sub(/ +$/, "", name)
         print num, name, st
       }' "$O/ctest_$a.txt" | sort -n > "$O/results_$a.txt"
done
{
  for a in release off on; do
    echo "$a: $(wc -l < "$O/results_$a.txt" | tr -d ' ') tests; $(awk '{ print $NF }' "$O/results_$a.txt" | sort | uniq -c | awk '{ printf "%s %s; ", $2, $1 }')"
  done
  echo "== off against release"
  if diff "$O/results_release.txt" "$O/results_off.txt"; then echo "every test the same"; fi
  echo "== on against off"
  if diff "$O/results_off.txt" "$O/results_on.txt"; then echo "every test the same"; fi
} > "$O/compare.txt"
cat "$O/compare.txt"
