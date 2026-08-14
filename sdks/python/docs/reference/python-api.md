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

- `native`
- `primitive_type`
- `confidence`
- `primitive`
- `provenance`
- `mapping`
- `unmapped`
- `findings`
- `warnings`
- `errors`
- `candidates`
- `local_digest`
- `committed`
- `ok`

`local_digest` is a deterministic local digest for developer checks. It is not
a receipt commitment.

Batch and file helpers:

```python
from agevidence import ingest_many, ingest_stream, ingest_async, ingest_file, ingest_dataframe

dataset = ingest_file("records.jsonl")
dataset.count
dataset.valid
dataset.invalid
dataset.primitive_types
dataset.coverage
dataset.to_primitives()
```

`ingest_file` supports JSON object/list, JSONL/NDJSON, CSV, paths, and
file-like objects. CSV values remain strings by default; pass `coerce=True` to
coerce JSON-like booleans, numbers, and nulls. `ingest_dataframe` accepts
pandas- and Polars-like objects when optional dataframe dependencies are
installed.

Unmapped native fields are preserved on `result.unmapped`. When an extension
namespace is supplied, unmapped fields are also copied into
`primitive["metadata"]["extensions"][namespace]`.

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

Developer tooling:

```python
from agevidence.adapters import init_source_adapter, adapter_coverage, compare_fixture_sets
```

`adapter_coverage` reports path-aware mapped fields, vendor-extension
preservation, explicitly ignored fields, and silent field loss.

## Evidence Operations

Additive primitives:

- `CalibrationRecord`
- `ProductLot`
- `AssetState`
- `DerivedObservation`
- `Transformation`
- `Attachment`
- `ExternalObject`

Local workflow helpers:

```python
from agevidence import Bundle, frame, series, lineage
from agevidence.units import Quantity
from agevidence.offline import Queue
```

These helpers orchestrate local evidence quality, continuity, lineage, bundles,
and offline capture. Bundle verification still delegates to Rust.

`EvidenceFrame.aggregate(value, by=..., reducer=...)` supports `count`, `sum`,
`min`, `max`, and `mean`. `Bundle.validate_manifest()` validates local manifest
determinism and primitive consistency; cryptographic bundle verification still
delegates to Rust.

## Optional Modules

- `agevidence.geo` requires `agevidence[geo]`.
- `agevidence.otel` requires `agevidence[otel]`.
- `agevidence.viz` requires `agevidence[viz]`.
- `agevidence.pytest_plugin` is exposed by `agevidence[pytest]`.

## Local Assessments

```python
assessment = result.assess("au.livestock.water-dosing.v1")
```

Local assessments report evidence suitability only. They do not establish
regulatory eligibility, scientific validity, issuance, or institutional
reliance.

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
