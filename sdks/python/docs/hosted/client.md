# Hosted Client

`Client` and `AsyncClient` connect to hosted Agevidence workflows.

```python
from agevidence import Client

client = Client(base_url="http://localhost:3000")
```

Configure the CLI:

```bash
agevidence login --base-url http://localhost:3000
```

Environment variables:

```text
AGEVIDENCE_BASE_URL
AGEVIDENCE_API_TOKEN
AGEVIDENCE_INTEGRATION_SOURCE
AGEVIDENCE_INTEGRATION_SECRET
AGEVIDENCE_VERIFIER_COMMAND
```

Hosted clients are optional. Local primitives, ingest, provenance checks, source
adapter tests, fixtures, and demos do not require them.

