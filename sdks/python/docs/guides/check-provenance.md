# Check Provenance

Use `agevidence.provenance.check` to inspect local evidence readiness.

```python
from agevidence.primitives import Observation
from agevidence.provenance import check

observation = Observation(
    subject="animal:982000001234",
    observable="enteric_methane",
    value=18.2,
    unit="g_ch4_min",
    observed_at="2026-08-12T15:10:00Z",
    instrument={"id": "breath-sensor:demo-2"},
)

report = check(observation)
print(report.structural_validity)
print(report.provenance_completeness)
for finding in report.findings:
    print(finding.code, finding.severity, finding.message)
```

CLI:

```bash
agevidence explain methane.json --format table
```

The report separates local evidence readiness from program eligibility,
verification status, and institutional reliance. Local `PASS` does not
establish regulatory eligibility, scientific validity, carbon-credit issuance,
third-party verification, claim ownership, or institutional reliance.

