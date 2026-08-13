# Agevidence

Portable evidence primitives for agricultural software.

Agevidence helps developers convert operational records into structured,
provenance-bearing evidence that can be inspected, verified locally, replayed,
and interpreted by multiple downstream systems.

```bash
pip install agevidence
agevidence demo
```

No account required for local use.

## Architectural Promise

Agevidence separates evidence from interpretation. A measurement,
intervention, source record, machine operation, or model execution is preserved
independently from the program, methodology, claim, verifier, or institution
that later interprets it.

Updating a methodology or program profile should not mutate historical
evidence. The same evidence bundle can be inspected by a model, a verifier,
internal analytics, or a hosted institutional workflow without turning those
downstream decisions into the evidence itself.

## What Local PASS Means

Local validation checks structure, provenance, lineage, deterministic
representation, and compatibility with Agevidence contracts.

It does not establish:

- regulatory eligibility;
- scientific validity;
- carbon-credit issuance;
- third-party verification;
- claim ownership;
- institutional reliance.

That boundary applies anywhere the SDK reports `PASS`.

## Install

From PyPI:

```bash
pip install agevidence
```

From the repository root for local development:

```bash
python3 -m pip install -e "sdks/python[test]"
```

Check the CLI:

```bash
agevidence --help
agevidence demo
agevidence doctor
```

## Local First

Core SDK operations work without a Rails app, Agevidence account, API key, or
network request:

```bash
agevidence demo
agevidence doctor
agevidence fixture list
agevidence fixture write livestock-weight --out ./livestock-weight.json
agevidence ingest ./livestock-weight.json --format table
agevidence explain ./livestock-weight.json --format table
```

## Core Primitives

```python
from agevidence.primitives import Observation

observation = Observation(
    subject="animal:982000001234",
    observable="liveweight",
    value=481.4,
    unit="kg",
    observed_at="2026-08-12T14:05:11Z",
)
```

This object says what was observed. It does not say whether the observation
satisfies a carbon methodology, financing requirement, assurance standard, or
regulatory program.

The local primitive surface is:

- `SourceRecord`
- `Observation`
- `SpatialObservation`
- `InterventionEvent`
- `OperationalEvent`
- `ModelRun`

## Bring Your Own Record

```json
{
  "animal_id": "animal:982000001234",
  "observable": "liveweight",
  "value": 481.4,
  "unit": "kg",
  "observed_at": "2026-08-12T14:05:11Z"
}
```

```bash
agevidence ingest weight.json --format table
agevidence explain weight.json --format table
```

Python:

```python
from agevidence import ingest

result = ingest({
    "animal_id": "animal:982000001234",
    "observable": "liveweight",
    "value": 481.4,
    "unit": "kg",
    "observed_at": "2026-08-12T14:05:11Z",
})

print(result.primitive_type)
print(result.provenance.provenance_completeness)
```

## Build a Source Adapter

Source adapters map native records at the edge into clean Agevidence
primitives:

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

Test it with local fixtures:

```bash
agevidence adapter test my_adapter.py fixtures/
```

`agevidence adapter test` is for source-system mapping adapters. The existing
plural `agevidence adapters ...` command group is for country/profile adapters.

## Local Verification

Bundle verification is delegated to the configured Rust verifier:

```bash
agevidence verify bundle.json
```

The Python SDK does not implement receipt signing, receipt commitments, dCBOR,
or bundle verification internally. Trust operations stay behind the Rust trust
boundary.

## CI Helpers

```python
from agevidence.testing import (
    assert_evidence_valid,
    assert_provenance_complete,
    assert_rust_conformant,
)


def test_measurement_is_evidence_ready():
    result = ingest(make_measurement_record())
    assert_evidence_valid(result.primitive)
    assert_provenance_complete(result.primitive)
```

Use `assert_rust_conformant(...)` when the local Rust CLI is available and the
test should cross-check the Python normalized payload against
`baink-agevidence`.

## Optional Hosted Services

The open SDK can be used independently.

For organizations that need managed infrastructure, `Client` and `AsyncClient`
connect to hosted Agevidence capabilities for private evidence graphs,
program/profile workflows, review workflows, retention, audit, and
institutional APIs.

```python
from agevidence import Client, AsyncClient
```

Hosted workflows are optional. They should not be the first step for a
developer who only needs local evidence primitives.

## Documentation

Start with:

- [SDK docs](docs/index.md)
- [Quickstart](docs/quickstart.md)
- [Evidence vs. Interpretation](docs/concepts/evidence-vs-interpretation.md)
- [Build a Source Adapter](docs/guides/build-source-adapter.md)
- [Compatibility](docs/reference/compatibility.md)
