# Use in CI

Agevidence includes pytest-friendly helpers.

```python
from agevidence import ingest
from agevidence.testing import (
    assert_evidence_valid,
    assert_provenance_complete,
    assert_rust_conformant,
)


def test_weight_record_is_evidence_ready():
    result = ingest({
        "animal_id": "animal:982000001234",
        "observable": "liveweight",
        "value": 481.4,
        "unit": "kg",
        "observed_at": "2026-08-12T14:05:11Z",
    })

    assert_evidence_valid(result.primitive)
```

Require complete local provenance when the source system is expected to provide
it:

```python
def test_export_preserves_provenance():
    result = ingest(make_complete_record())
    assert_provenance_complete(result.primitive)
```

Cross-check against Rust when available:

```python
def test_rust_contract_accepts_payload():
    result = ingest(make_complete_record())
    assert_rust_conformant(result.primitive, schema="observation")
```

CI failures mean local structure or provenance expectations were not met. They
do not establish or deny regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

