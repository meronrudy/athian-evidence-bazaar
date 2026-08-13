# Build an Intervention Event

Use `InterventionEvent` for something physically applied or changed.

```python
from agevidence.primitives import InterventionEvent, SourceRecord
from agevidence.provenance import check

source = SourceRecord(
    source_system="synthetic-feed-mixer",
    record_id="dose-0001",
    observed_at="2026-08-12T16:00:00Z",
    controlled_uri="evidence://source/dose-0001",
    commitment="sha256:fixture-dose",
)

event = InterventionEvent(
    target="herd:H321",
    intervention="product:seafeed",
    quantity=2.4,
    unit="kg",
    occurred_at="2026-08-12T16:00:00Z",
    batch="SF-90231",
    source_records=[source],
)

report = check(event)
print(report.structural_validity)
print(report.provenance_completeness)
```

The event says what was applied, to what target, when, in what quantity, and
from which source record. It does not establish eligibility, issuance,
verification, claim ownership, or reliance.

