# Methane Sensor

Native record:

```json
{
  "eid": "982000009999",
  "ppm": 18.2,
  "timestamp": "2026-08-12T15:10:00Z",
  "sensor_id": "breath-sensor:demo-2"
}
```

Adapter:

```python
from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MethaneSensorAdapter(Adapter):
    def map(self, record):
        return Observation(
            subject=f"animal:{record['eid']}",
            observable="methane_concentration",
            value=record["ppm"],
            unit="ppm",
            observed_at=record["timestamp"],
            instrument={"id": record["sensor_id"]},
        )
```

Run:

```bash
agevidence adapter test methane_adapter.py fixtures/
```

If the adapter omits calibration references, the output can be structurally
valid while provenance remains incomplete. That is useful developer feedback,
not an external verification decision.

