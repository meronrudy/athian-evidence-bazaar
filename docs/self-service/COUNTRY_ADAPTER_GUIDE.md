# Country Adapter Guide

Country adapters translate local identifiers, source records, external checks, and policy requirements into the stable AgEvidence contracts. They do not alter `ink.receipt.v2`, issue approvals, or create country-specific trust kernels.

Run local gates:

```sh
scripts/agevidence_check_all.sh
```

Inspect adapters:

```sh
agevidence adapters list
agevidence adapters show AU
agevidence adapters validate AU
```

Append a Rails determination through the Developer OS API:

```sh
agevidence country evaluate PROJECT_ID --adapter AU
```

Current classifications are produced by `scripts/agevidence_manifest_check.py`. Active packs are executable reference targets; scaffold and research packs record architecture and limitations until source contracts are validated.

