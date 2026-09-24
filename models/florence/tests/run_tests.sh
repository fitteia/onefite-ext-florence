#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== building Florence extension =="
gfortran -c -ffixed-form -std=legacy "$MODEL/Florence_f.f" -o "$WORK/f.o"
gcc -c -I"$MODEL" "$MODEL/Florence_c.c" -o "$WORK/c.o"
gcc -I"$MODEL" "$HERE/test_driver.c" "$WORK/f.o" "$WORK/c.o" -lgfortran -lm -o "$WORK/driver"
gcc -I"$MODEL" "$HERE/staleness_demo.c" "$WORK/f.o" "$WORK/c.o" -lgfortran -lm -o "$WORK/staleness_demo"
gfortran -c -ffixed-form -std=legacy "$HERE/test_eigensolver.f" -o "$WORK/test_eigensolver.o"
gfortran "$WORK/test_eigensolver.o" "$WORK/f.o" -o "$WORK/test_eigensolver"

echo "== eigensolver known-answer regression =="
"$WORK/test_eigensolver"

echo "== Householder+QL eigensolver internals regression =="
gfortran -O2 -ffixed-form -std=legacy "$HERE/test_cheevhqr.f" -llapack -lblas -o "$WORK/test_cheevhqr"
"$WORK/test_cheevhqr"

echo "== golden regression =="
: > "$WORK/actual.txt"
for freq in 1e3 1e4 1e5 1e6 2.5e6 1e7 5e7 1e8 1e9 5e9; do
  for flag in 1 2; do
    { echo "=== freq=$freq flag=$flag ==="; "$WORK/driver" "$freq" "$flag"; } >> "$WORK/actual.txt"
  done
done
diff -u "$HERE/golden_output.txt" "$WORK/actual.txt"
echo "PASS: Florence golden output"

echo "== stale-cache regression =="
"$WORK/staleness_demo" | tee "$WORK/stale.txt"
grep -q 'MATCH: yes' "$WORK/stale.txt"
echo "PASS: Florence cache regression"
