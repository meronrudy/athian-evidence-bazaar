# Feed Intervention

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

This event records delivery. It does not itself issue credits, approve a
methodology, allocate a claim, or create institutional reliance.

