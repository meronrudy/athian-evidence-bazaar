# Build a Source Adapter

Source adapters map native records at the edge into clean Agevidence
primitives.

Use them when your system emits records that do not already match canonical
primitive fields.

## Native Record

```json
{
  "eid": "982000001234",
  "ppm": 18.7,
  "timestamp": "2026-08-12T15:10:00Z",
  "sensor_id": "SENSOR-17"
}
```

## Adapter

Create `my_adapter.py`:

```python
from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MySensorAdapter(Adapter):
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

## Test

Put JSON records in `fixtures/`, then run:

```bash
agevidence adapter test my_adapter.py fixtures/
```

Expected shape:

```text
Agevidence Source Adapter Test
Fixtures: 12
Mapped: 12
Structurally valid: 12
Provenance complete: 10
Provenance incomplete: 2
No canonical schema extensions required.
```

The last line matters. Source-system quirks should be handled in the adapter,
not by expanding the canonical primitive contract.

## Loader Forms

```bash
agevidence adapter test my_adapter.py fixtures/
agevidence adapter test my_adapter.py:MySensorAdapter fixtures/
agevidence adapter test my_package.adapters:MySensorAdapter fixtures/
```

`agevidence adapter test` is for source-system mapping adapters. The existing
plural command group, `agevidence adapters ...`, is for country/profile
adapters.

Adapter tests validate local structure, provenance, deterministic
representation, and canonical primitive compatibility. They do not establish
regulatory eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.

