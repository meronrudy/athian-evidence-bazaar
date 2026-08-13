# Ingest Native JSON

Start with your application's schema. Agevidence maps it to a canonical
primitive.

## Native Record

```json
{
  "animal_id": "animal:982000001234",
  "observable": "liveweight",
  "value": 481.4,
  "unit": "kg",
  "observed_at": "2026-08-12T14:05:11Z"
}
```

## CLI

```bash
agevidence ingest weight.json --format table
```

Example output shape:

```text
Agevidence Ingest
Candidate primitive: Observation
Confidence: high
Mapped fields: subject, observable, value, unit, observed_at
Structural validity: PASS
Provenance completeness: PARTIAL
```

Local `PASS` does not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

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
print(result.primitive)
print(result.provenance.provenance_completeness)
```

## Mapping vs. Canonical Data

```text
YOUR APPLICATION
{
  "animal_id": "animal:982000001234",
  "value": 481.4,
  "timestamp": "..."
}
        |
        v
AGEVIDENCE
Observation(
  subject="animal:982000001234",
  observable="liveweight",
  value=481.4,
  unit="kg",
  observed_at="..."
)
```

The native adapter can be messy. The primitive should stay clean.

