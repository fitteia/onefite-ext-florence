# onefite-external-extensions

Optional OneFit model bundles, kept in a separate repository from the
license-clean `onefite-c-code` core so each bundle's own license and
provenance can be tracked independently. The installer places enabled
bundles under `C/extensions/<name>` and builds their sources into
separate archives, without adding them to the base repository's own
history.

This repository currently contains the **Florence** bundle (nuclear
magnetic relaxation dispersion, NMRD, model functions).

## Licensing

Licensed under the Artistic License 2.0 - see `LICENSE`. This
repository contains no NAG Library code and no other externally
sourced numerical routines whose redistribution terms were unclear:
Florence's complex Hermitian eigensolver, which previously relied on
NAG-derived Fortran, has been fully replaced with an independent,
from-scratch implementation (Householder tridiagonalization +
implicit QL with Wilkinson shifts - the same well-known, decades-old
published algorithm, not derived from NAG's, LAPACK's, or EISPACK's
source). See `models/florence/NOTICE` for the full replacement history
and verification details.

If you already hold a NAG Library license and would prefer to build
against the original NAG-derived implementation instead, that history
is preserved in a separate, private repository maintained by the
project (not linked from here, since it isn't cleared for public
redistribution). Point `onefite-go doctor -install`'s
`--extensions-ref` at that repository's own ref instead of this one's
if you have access to it; everything else about the install process
is identical.

## Installing

This bundle is built automatically as part of the normal `onefite-go`
install flow:

```bash
onefite-go doctor -install -ofe-path=<install-dir> -enable-extensions
```

No extra credentials or steps are needed - `onefite-go` clones this
repository over plain HTTPS like any other public dependency
(`onefite-c-code`, `minuit`), builds it, and aggregates its function
entries into the installed `META-C.json`.

## Layout

Each model bundle contains `META-C-model.json`, source files, public
headers, and its own `LICENSE`/`NOTICE`. Consult each
`models/*/LICENSE` and `models/*/NOTICE` for that bundle's specific
license and provenance - they may differ from this top-level notice if
a future bundle has different terms.
