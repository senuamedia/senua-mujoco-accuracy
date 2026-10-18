#!/usr/bin/env bash
# every relative link on the record's pages points at a file or folder that exists (anchors and web links set aside)
# usage: check_links.sh   (from the repository root)
set -u
n=0; bad=0
for p in README.md docs/*.md docs/studies/*.md patches/README.md measure/README.md preregistrations/*.md validation/run_*/README.md validation/audit/*.md; do
  [ -f "$p" ] || continue
  d=$(dirname "$p")
  grep -oE '\]\([^)]+\)' "$p" | sed -E 's/^\]\(//; s/\)$//' | while read -r l; do
    case "$l" in http*|mailto:*|\#*) continue ;; esac
    t=${l%%#*}; [ -z "$t" ] && continue
    if [ -e "$d/$t" ]; then echo "OK"; else echo "BROKEN $p -> $l"; fi
  done
done > /tmp/links.txt
echo "links: $(grep -c '^OK' /tmp/links.txt) resolve, $(grep -c '^BROKEN' /tmp/links.txt) broken"
grep '^BROKEN' /tmp/links.txt | head -40
