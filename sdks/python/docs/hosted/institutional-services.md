# Institutional Services

Hosted institutional services are for organizations that need managed evidence
graphs, program/profile workflows, review, retention, audit, and institutional
APIs.

These services are optional layers above the open SDK.

## Boundary

The SDK can preserve evidence independently from downstream determinations.
Institutional reliance, external verification, claim ownership, credit
issuance, and regulatory eligibility must be issued by the relevant authority
or institution. They are not created by local SDK validation.

## Developer Flow

Use the local SDK first:

```bash
agevidence demo
agevidence ingest record.json --format table
agevidence explain record.json --format table
agevidence adapter test my_adapter.py fixtures/
```

Move to hosted services when managed infrastructure is needed.

