# Spatial Observation

```python
from agevidence.primitives import SpatialObservation, SourceRecord
from agevidence.provenance import check

source = SourceRecord(
    source_system="synthetic-remote-sensing",
    record_id="scene-0001",
    observed_at="2026-08-12T00:00:00Z",
    controlled_uri="evidence://source/scene-0001",
    commitment="sha256:fixture-scene",
)

observation = SpatialObservation(
    subject="paddock:north-12",
    geometry={
        "type": "Polygon",
        "coordinates": [[
            [151.2, -33.8],
            [151.21, -33.8],
            [151.21, -33.79],
            [151.2, -33.79],
            [151.2, -33.8],
        ]],
    },
    observable="feed_on_offer",
    value=1840,
    unit="kg_dm_ha",
    observed_at="2026-08-12T00:00:00Z",
    crs="EPSG:4326",
    source_records=[source],
)

report = check(observation)
print(report.structural_validity)
print(report.provenance_completeness)
```

Spatial evidence remains evidence. Program-specific treatment belongs in a
versioned interpretation layer.

