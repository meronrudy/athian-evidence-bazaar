# Provenance

Provenance means retaining enough information to understand where evidence came
from and how it was produced.

It is a developer concept before it is a compliance concept.

## Local Explanation

```bash
agevidence explain record.json --format table
```

Example shape:

```text
Agevidence Explain
Primitive: Observation
Structural validity: PASS
Provenance completeness: INCOMPLETE
Missing:
  CALIBRATION_REFERENCE_MISSING
Warnings:
  SOURCE_RECORD_MISSING
```

Why this matters:

```text
The observation identifies an instrument, but no calibration reference covers
the observation.
```

## What Is Checked

The local provenance checker separates:

- structural validity;
- provenance completeness;
- program eligibility;
- verification status;
- institutional reliance.

Program eligibility is `not_evaluated`, verification is `not_issued`, and
institutional reliance is `not_asserted` for local SDK checks.

Local `PASS` does not establish regulatory eligibility, scientific validity,
carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

