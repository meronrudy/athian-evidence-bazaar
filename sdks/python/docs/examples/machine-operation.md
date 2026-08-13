# Machine Operation

```python
from agevidence.primitives import OperationalEvent, SourceRecord
from agevidence.provenance import check

source = SourceRecord(
    source_system="synthetic-machine-controller",
    record_id="operation-0001",
    observed_at="2026-08-12T17:18:00Z",
    controlled_uri="evidence://source/operation-0001",
    commitment="sha256:fixture-operation",
)

event = OperationalEvent(
    machine="swarmbot:demo-1",
    operation="spot_spray",
    started_at="2026-08-12T17:00:00Z",
    completed_at="2026-08-12T17:18:00Z",
    location={"field": "field:west-4"},
    source_records=[source],
)

report = check(event)
print(report.structural_validity)
print(report.provenance_completeness)
```

Operational events can feed analytics, review, or verification workflows later.
The primitive itself records the operation.

