#!/usr/bin/env bash
# Builds a complete OneFit-Engine tree from real GitHub refs, at the
# commit this bundle's NAG-eigensolver replacement was measured
# against, so run-comparison.sh can fit the same three real Florence
# models and report timing/accuracy.
#
# This public package only builds the NAG-free (post-replacement)
# tree: the original NAG-derived code lives in a separate, private
# repository this package deliberately does not reference (see this
# directory's README for why, and for how to run the full old-vs-new
# comparison if you separately have access to that private repo).
#
# Requires: git, go (1.21+), gfortran, gcc, make, ar - the same
# prerequisites onefite-go's own `doctor` check already verifies.
#
# Usage:
#   ./setup-comparison.sh [OUTDIR]
# OUTDIR defaults to ./comparison-workdir (created if missing).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$HERE/comparison-workdir}"
mkdir -p "$OUTDIR"

# Pinned refs - the exact commits this comparison was originally run
# and reported against. onefite-c-code and minuit have no per-tree
# pinning flag in `doctor -install` (they always track their own
# default branch), which is fine here: the SHAs below are recorded for
# the record, in case you want to check whether their default branch
# has since diverged from what this comparison was run against.
ONEFITE_C_CODE_REF_RECORDED=6633911acb2c376267c202e43dc64ed9e2b709df
MINUIT_REF_RECORDED=b842e5b02052f598f3f14606bcc01f78e95d8fd5
ONEFITE_NATIVE_REF=fd6d3de18f6e8d3f7ff2b82f96caa55ab3de06d4
EXTENSIONS_NEW_REF=4e8acf36c174b0e4778dd022c02a3e755787ff4d

echo "=== onefite-c-code recorded at: $ONEFITE_C_CODE_REF_RECORDED"
echo "=== minuit recorded at:         $MINUIT_REF_RECORDED"
echo "=== extensions (this fix):      $EXTENSIONS_NEW_REF"
echo

echo "== building onefite-go ($ONEFITE_NATIVE_REF) =="
if [ ! -d "$OUTDIR/onefite-native" ]; then
  git clone https://github.com/fitteia/OneFit-Engine-go.git "$OUTDIR/onefite-native"
fi
git -C "$OUTDIR/onefite-native" fetch origin
git -C "$OUTDIR/onefite-native" checkout --force "$ONEFITE_NATIVE_REF"
( cd "$OUTDIR/onefite-native" && go build -o "$OUTDIR/onefite-go" ./cmd/onefite )
ONEFITE_GO="$OUTDIR/onefite-go"
echo "built: $ONEFITE_GO"
echo

echo "== building tree (extensions @ $EXTENSIONS_NEW_REF) =="
"$ONEFITE_GO" doctor -install -ofe-path="$OUTDIR/ofe-new" \
  -enable-extensions -extensions-ref="$EXTENSIONS_NEW_REF"
echo

echo "Setup complete. This builds only the NAG-free tree - see README.md"
echo "for how to add an OLD (NAG-derived) tree if you separately have"
echo "access to that private repository, or just use the recorded"
echo "numbers in NOTICE/README.md for the reference comparison."
echo
echo "To time-check this tree on its own:"
echo
echo "  ONEFITE_GO=\"$ONEFITE_GO\" \\"
echo "  OLD_OFE_PATH=\"$OUTDIR/ofe-new\" \\"
echo "  NEW_OFE_PATH=\"$OUTDIR/ofe-new\" \\"
echo "  \"$HERE/run-comparison.sh\" \\"
echo "    \"$HERE/florenceN_fH_SS_test.json\" \\"
echo "    \"$HERE/florenceN4LS_fH_R1OSabh_test.json\" \\"
echo "    \"$HERE/florenceN_fH_test.json\""
