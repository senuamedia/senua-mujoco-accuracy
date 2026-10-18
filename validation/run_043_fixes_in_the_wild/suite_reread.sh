#!/usr/bin/env bash
# Run 043's MuJoCo test suites re-read after the run: the probe's own comparison (the last line of measured.txt) kept
# the "  # GetParam() = ..." suffix of parametrised test names, which holds spaces, so it compared the wrong fields. This
# re-reads ctest_june.txt and ctest_pr.txt with Study 10's parser (the suffix stripped), then drops the position index
# MuJoCo appends to its whole-model tests (the pull request adds two scene files, which shifts every later index;
# tests of scene files that share a name keep their order, numbered ~1, ~2, ...), and compares the two builds test by
# test. Plumbing only: it reads the test results and measures nothing.
# usage: suite_reread.sh   (from this folder; writes suite_results_june.txt, suite_results_pr.txt, suite_compare.txt)
set -u
for n in june pr; do
  awk 'match($0, /Test +#[0-9]+: /) {
         rest = substr($0, RSTART + RLENGTH); st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ...."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name); gsub(/ /, "_", name)
         print name, st }' ctest_$n.txt \
    | awk '{ base = $1; idx = 0; if (base ~ /^AllModels\/.*_[0-9]+$/) { k = base; sub(/_[0-9]+$/, "", base); idx = substr(k, length(base) + 2) + 0 } print base, idx, $2 }' \
    | LC_ALL=C sort -k1,1 -k2,2n | awk '{ c[$1]++; print $1 "~" c[$1], $3 }' | LC_ALL=C sort > suite_results_$n.txt
done
{
  echo "june: $(wc -l < suite_results_june.txt | tr -d ' ') tests; the pull request's head: $(wc -l < suite_results_pr.txt | tr -d ' ') tests"
  echo "shared: $(LC_ALL=C join suite_results_june.txt suite_results_pr.txt | wc -l | tr -d ' '); read differently: $(LC_ALL=C join suite_results_june.txt suite_results_pr.txt | awk '$2 != $3' | wc -l | tr -d ' ')"
  LC_ALL=C join suite_results_june.txt suite_results_pr.txt | awk '$2 != $3 { print "  differs: " $1 " june " $2 ", pull request " $3 }'
  echo "only on the pull request: $(LC_ALL=C join -v2 suite_results_june.txt suite_results_pr.txt | wc -l | tr -d ' ')"
  LC_ALL=C join -v2 suite_results_june.txt suite_results_pr.txt | sed 's/^/  /'
  echo "only on june: $(LC_ALL=C join -v1 suite_results_june.txt suite_results_pr.txt | wc -l | tr -d ' ')"
} > suite_compare.txt
