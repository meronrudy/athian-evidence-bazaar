# Model Runs

A `ModelRun` records a derived result without mutating the evidence that fed it.

```python
from agevidence.primitives import ModelRun

run = ModelRun(
    model_id="pasturekey",
    model_version="2.3.1",
    implementation_digest="sha256:model-implementation",
    input_commitments=["sha256:evidence-bundle"],
    parameters={"seed": 42},
    execution_environment={"runtime": "python-3.12"},
    started_at="2026-08-12T18:00:00Z",
    completed_at="2026-08-12T18:00:05Z",
    outputs=[{"observable": "estimated_biomass", "value": 1840, "unit": "kg_dm_ha"}],
    limitations=["synthetic example"],
    verification={
        "adapter_id": "pasturekey-adapter-v1",
        "adapter_digest": "sha256:adapter",
        "normalized_output_digest": "sha256:output",
    },
)
```

The question shifts from "which calculator owns the truth?" to "which model,
version, assumptions, inputs, and output produced this result?"

## Multiple Models

```python
evidence = "sha256:evidence-bundle"

model_a = ModelRun(
    model_id="model-a",
    model_version="1.0.0",
    implementation_digest="sha256:model-a",
    input_commitments=[evidence],
    parameters={},
    execution_environment={"runtime": "python"},
    started_at="2026-08-12T18:00:00Z",
    completed_at="2026-08-12T18:00:05Z",
    outputs=[{"value": 1}],
    limitations=["example"],
    verification={},
)
model_b = ModelRun(
    model_id="model-b",
    model_version="2.0.0",
    implementation_digest="sha256:model-b",
    input_commitments=[evidence],
    parameters={},
    execution_environment={"runtime": "python"},
    started_at="2026-08-12T18:01:00Z",
    completed_at="2026-08-12T18:01:05Z",
    outputs=[{"value": 2}],
    limitations=["example"],
    verification={},
)
```

The evidence stays fixed. Each model execution has separate provenance.

Local model-run validation does not establish scientific validity, regulatory
eligibility, carbon-credit issuance, external verification, claim ownership, or
institutional reliance.
