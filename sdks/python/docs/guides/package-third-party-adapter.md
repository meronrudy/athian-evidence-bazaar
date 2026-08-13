# Package a Third-party Source Adapter

Third-party source adapters map native source-system records into Agevidence
primitives. They should not extend canonical schemas for source-system quirks.

## Package Shape

Recommended package layout:

```text
my-agevidence-adapter/
├── pyproject.toml
├── src/
│   └── my_agevidence_adapter/
│       ├── __init__.py
│       └── adapter.py
└── fixtures/
    └── example.json
```

Adapter implementation:

```python
from agevidence.adapters import Adapter
from agevidence.primitives import Observation


class MyAdapter(Adapter):
    def map(self, record):
        return Observation(
            subject=f"animal:{record['eid']}",
            observable="methane",
            value=record["ppm"],
            unit="ppm",
            observed_at=record["timestamp"],
        )
```

## Local Test

```bash
agevidence adapter test src/my_agevidence_adapter/adapter.py:MyAdapter fixtures/
```

Expected result:

```text
Agevidence Source Adapter Test
Mapped: 1
Structurally valid: 1
No canonical schema extensions required.
```

## Packaging Guidance

- Declare `agevidence>=1.0.0,<2` unless the adapter intentionally supports a narrower range.
- Keep fixtures synthetic or explicitly approved for public testing.
- Include CI that runs `agevidence adapter test`.
- Document which native source-system fields are required.
- Document incomplete provenance findings that users should expect.
- Do not claim regulatory eligibility, scientific validity, carbon-credit issuance, third-party verification, claim ownership, or institutional reliance.

