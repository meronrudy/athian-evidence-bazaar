# Python API Reference

This page summarizes the public SDK surfaces.

## Stable Contract Candidates

`agevidence.primitives`

- `SourceRecord`
- `Observation`
- `SpatialObservation`
- `InterventionEvent`
- `OperationalEvent`
- `ModelRun`
- `EvidencePrimitive`
- `canonical_json`
- `local_digest`

These objects represent evidence. They do not represent downstream eligibility,
verification, claim ownership, or reliance decisions.

## Local Ingest

```python
from agevidence import ingest

result = ingest(record)
```

`result` includes:

- `primitive_type`
- `confidence`
- `primitive`
- `provenance`
- `candidates`
- `local_digest`
- `committed`

`local_digest` is a deterministic local digest for developer checks. It is not
a receipt commitment.

## Provenance

```python
from agevidence.provenance import check

report = check(primitive)
```

`report` separates:

- `structural_validity`
- `provenance_completeness`
- `program_eligibility`
- `verification_status`
- `institutional_reliance`

Local checks do not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

## Source Adapters

Experimental source-system mapping API:

```python
from agevidence.adapters import Adapter


class MyAdapter(Adapter):
    def map(self, record):
        ...
```

Test helpers:

```python
from agevidence.adapters import load_source_adapter, test_source_adapter

adapter = load_source_adapter("my_adapter.py")
report = test_source_adapter(adapter, "fixtures/")
```

## Country/Profile Adapters

Profile-specific country adapter APIs live under `agevidence.adapters` and
`agevidence.countries`.

Use `CountryAdapter` for country/profile interpretation. Use `Adapter` for
source-system mapping.

## Hosted-only Clients

```python
from agevidence import Client, AsyncClient
```

`Client` and `AsyncClient` are for hosted Agevidence workflows. They are not
required for local primitives, ingest, provenance checks, or source adapter
tests.

