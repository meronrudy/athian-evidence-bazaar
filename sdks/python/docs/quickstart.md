# Quickstart

This path uses only local SDK features.

## Install

```bash
pip install agevidence
```

For repository development:

```bash
python3 -m pip install -e "sdks/python[test]"
```

## Run the Demo

```bash
agevidence demo
```

Expected shape:

```text
Agevidence Developer Demo
Loaded: livestock-weight
Mapped: Observation
Structural validity: PASS
Provenance completeness: COMPLETE (100%)
Rust validation: PASS
No account used. No API key used. No network request used.
```

If the Rust verifier is not configured, `Rust validation` may report
`NOT_CONFIGURED`. The local primitive, ingest, and provenance path still works.

Local `PASS` does not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

## Ingest a Fixture

```bash
agevidence fixture write livestock-weight --out ./livestock-weight.json
agevidence ingest ./livestock-weight.json --format table
agevidence explain ./livestock-weight.json --format table
```

## Bring Your Own Record

Create `weight.json`:

```json
{
  "animal_id": "animal:982000001234",
  "observable": "liveweight",
  "value": 481.4,
  "unit": "kg",
  "observed_at": "2026-08-12T14:05:11Z"
}
```

Run:

```bash
agevidence ingest weight.json --format table
agevidence explain weight.json --format table
```

The adapter can be messy. The primitive should stay clean.

## Python

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
print(result.provenance.structural_validity)
print(result.provenance.provenance_completeness)
```

## Next

- [Evidence vs. Interpretation](concepts/evidence-vs-interpretation.md)
- [Build a source adapter](guides/build-source-adapter.md)
- [Use in CI](guides/use-in-ci.md)

