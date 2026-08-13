# Build an Observation

Use `Observation` for a measurement or physical assertion about a subject.

```python
from agevidence.primitives import Observation, SourceRecord
from agevidence.provenance import check

source = SourceRecord(
    source_system="synthetic-scale",
    record_id="weight-0001",
    observed_at="2026-08-12T14:05:11Z",
    controlled_uri="evidence://source/weight-0001",
    commitment="sha256:fixture-weight",
)

observation = Observation(
    subject="animal:982000001234",
    observable="liveweight",
    value=481.4,
    unit="kg",
    observed_at="2026-08-12T14:05:11Z",
    instrument={
        "id": "scale:demo-1",
        "calibration_reference": "evidence://calibration/scale-demo-1",
    },
    source_records=[source],
)

report = check(observation)
print(report.structural_validity)
print(report.provenance_completeness)
```

This object records the observation. It does not decide whether a claim,
methodology, financing requirement, assurance standard, or regulatory program
accepts the observation.

