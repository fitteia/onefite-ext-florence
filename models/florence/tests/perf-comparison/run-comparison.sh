#!/usr/bin/env bash
# Runs each fit file NTRIALS times against both engine trees (OLD =
# original NAG-derived Florence eigensolver, NEW = the hand-rolled
# Householder+QL replacement, no NAG/LAPACK dependency), records
# wall-clock time and the reported total chi2/tnpts/nfps line for
# each run, and writes a summary report.
#
# Expects ONEFITE_GO, OLD_OFE_PATH, NEW_OFE_PATH already set (see
# setup-comparison.sh, which builds those two trees) and one or more
# florenceN*.json fixtures passed as arguments.
set -euo pipefail

ONEFITE_GO="${ONEFITE_GO:?set ONEFITE_GO to the onefite-go binary}"
OLD_OFE_PATH="${OLD_OFE_PATH:?set OLD_OFE_PATH to the tree built from the original NAG code}"
NEW_OFE_PATH="${NEW_OFE_PATH:?set NEW_OFE_PATH to the tree built with the LAPACK replacement}"
NTRIALS="${NTRIALS:-5}"
OUTDIR="${OUTDIR:-$(mktemp -d)}"
FIT_FILES=("$@")

if [ "${#FIT_FILES[@]}" -eq 0 ]; then
  echo "usage: $0 file1.json file2.json file3.json ..." >&2
  exit 1
fi

mkdir -p "$OUTDIR"
REPORT="$OUTDIR/report.txt"
: > "$REPORT"

run_one() {
  local label="$1" ofepath="$2" fitfile="$3" trial="$4"
  local runpath
  runpath="$OUTDIR/${label}/$(basename "$fitfile" .json)/trial-$trial"
  mkdir -p "$runpath"
  local t0 t1 elapsed
  t0=$(date +%s.%N)
  "$ONEFITE_GO" fit -ofe-path="$ofepath" -path="$runpath" "$fitfile" \
    > "$runpath/stdout.txt" 2> "$runpath/stderr.txt"
  t1=$(date +%s.%N)
  elapsed=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.4f", b-a}')
  local tail_line
  tail_line=$(grep -m1 "tchi2 =" "$runpath/stdout.txt" || echo "NO TCHI2 LINE FOUND")
  printf '%-4s %-40s trial=%-2s time=%-10s %s\n' \
    "$label" "$(basename "$fitfile")" "$trial" "${elapsed}s" "$tail_line" | tee -a "$REPORT"
}

echo "=== Comparison run: $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" | tee -a "$REPORT"
echo "OLD_OFE_PATH=$OLD_OFE_PATH" | tee -a "$REPORT"
echo "NEW_OFE_PATH=$NEW_OFE_PATH" | tee -a "$REPORT"
echo "NTRIALS=$NTRIALS" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"

for fitfile in "${FIT_FILES[@]}"; do
  for trial in $(seq 1 "$NTRIALS"); do
    run_one old "$OLD_OFE_PATH" "$fitfile" "$trial"
  done
  for trial in $(seq 1 "$NTRIALS"); do
    run_one new "$NEW_OFE_PATH" "$fitfile" "$trial"
  done
  echo "" | tee -a "$REPORT"
done

echo "Full results and per-run fit.out/fit.log under: $OUTDIR" | tee -a "$REPORT"
echo "Report: $REPORT"
