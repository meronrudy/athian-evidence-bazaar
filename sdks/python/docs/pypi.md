# Agevidence

Portable evidence primitives for agricultural software.

Agevidence helps agricultural systems turn native records into structured,
provenance-bearing evidence that can be inspected, verified locally, replayed,
and interpreted by downstream systems.

```bash
pip install agevidence
agevidence demo
```

No account required for local use.

## Core Idea

Agevidence separates evidence from interpretation. A measurement, intervention,
source record, machine operation, or model execution is preserved independently
from the program, methodology, claim, verifier, or institution that later
interprets it.

## Local First

These commands work without an Agevidence account, API key, hosted service, or
network request:

```bash
agevidence demo
agevidence fixture write livestock-weight --out ./livestock-weight.json
agevidence ingest ./livestock-weight.json --format table
agevidence explain ./livestock-weight.json --format table
```

Local `PASS` means the SDK checked structure, provenance, lineage, deterministic
representation, and Agevidence contract compatibility. It does not establish
regulatory eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.

## Python

```python
from agevidence.primitives import Observation
from agevidence.provenance import check

observation = Observation(
    subject="animal:982000001234",
    observable="liveweight",
    value=481.4,
    unit="kg",
    observed_at="2026-08-12T14:05:11Z",
)

report = check(observation)
print(report.structural_validity)
print(report.provenance_completeness)
```

## Source Adapters

```python
from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MySensorAdapter(Adapter):
    def map(self, record):
        return Observation(
            subject=f"animal:{record['eid']}",
            observable="methane_concentration",
            value=record["ppm"],
            unit="ppm",
            observed_at=record["timestamp"],
        )
```

```bash
agevidence adapter test my_adapter.py fixtures/
```

## Optional Hosted Services

The SDK can also connect to hosted Agevidence infrastructure through `Client`
and `AsyncClient` for private evidence graphs, program workflows, review,
retention, audit, and institutional APIs.

Receipt signing, canonical commitments, dCBOR, and bundle verification remain
delegated to the Rust trust boundary.
