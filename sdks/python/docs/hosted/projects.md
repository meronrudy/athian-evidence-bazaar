# Hosted Projects

Hosted projects organize evidence workflows in managed infrastructure.

```python
from agevidence import Client

client = Client(base_url="http://localhost:3000")

project = client.create_project(
    account_name="Northstar Methane Systems Sandbox",
    project_name="Enterprise dairy pilot",
    target_claim="The intervention reduces enteric methane.",
)

source = client.submit_source_record(
    project_id=project.id,
    document_id="trial-report-001",
    evidence_type="evidence.trial_report",
    controlled_uri="evidence://trial-report-001",
    commitment="sha256:demo",
)
```

A hosted project does not change the authority boundary. Source records and
model outputs do not automatically establish regulatory eligibility,
scientific validity, carbon-credit issuance, third-party verification, claim
ownership, or institutional reliance.

