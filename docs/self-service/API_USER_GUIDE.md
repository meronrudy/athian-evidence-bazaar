# API User Guide

This guide explains the `/v1` Developer OS API for sandbox projects, source
records, model runs, candidate review, quotes, artifact orders, and operations.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Base URL

Local scaffold:

```text
http://localhost:3000
```

OpenAPI:

```text
docs/openapi/agevidence.v1.yaml
```

## Create a Project

```bash
curl -sS http://localhost:3000/v1/developer/projects \
  -H "Content-Type: application/json" \
  -d '{
    "developer_account": {
      "name": "Northstar Methane Systems Sandbox",
      "funding_stage": "sandbox"
    },
    "project": {
      "name": "Enterprise dairy pilot",
      "project_type": "intervention",
      "target_claim": "The intervention reduces enteric methane."
    }
  }'
```

Use the returned project identifier in later calls.

## Add a Source Record

```bash
curl -sS http://localhost:3000/v1/developer/projects/PROJECT_ID/source_records \
  -H "Content-Type: application/json" \
  -d '{
    "source_record": {
      "document_id": "trial-report-001",
      "evidence_type": "evidence.trial_report",
      "controlled_uri": "evidence://trial-report-001",
      "commitment": "sha256:replace-with-source-commitment",
      "source_system": "developer_api"
    }
  }'
```

Large files stay in controlled storage. Rails stores references and evidence
projections.

## Run Fixture Extraction

```bash
curl -sS http://localhost:3000/v1/developer/projects/PROJECT_ID/model_runs \
  -H "Content-Type: application/json" \
  -d '{"adapter_id":"qwen3.5-4b-reference"}'
```

Model output is candidate evidence only. It cannot approve methods, certify
reductions, determine claim ownership, or create institutional reliance.

## Review a Candidate

```bash
curl -sS -X PATCH http://localhost:3000/v1/developer/candidates/CANDIDATE_ID \
  -H "Content-Type: application/json" \
  -d '{
    "review_decision": {
      "decision": "accepted",
      "reason": "Source reference supports the observed delivery event.",
      "reviewer_role": "scientific_reviewer_sandbox"
    }
  }'
```

Review decisions are append-only. A later decision supersedes the prior
decision without deleting history.

## Quote, Order, and Artifact

```bash
curl -sS http://localhost:3000/v1/pricing/products
```

```bash
curl -sS http://localhost:3000/v1/pricing/quotes \
  -H "Content-Type: application/json" \
  -d '{
    "quote": {
      "project_id": "PROJECT_ID",
      "product_code": "verification_readiness_cycle",
      "scope": {
        "protocol_complexity": "medium",
        "evidence_classes": 4,
        "source_systems": 2,
        "countries": 1,
        "relying_parties": 1,
        "selective_disclosure": false,
        "turnaround_days": 30
      }
    }
  }'
```

```bash
curl -sS http://localhost:3000/v1/artifact-orders \
  -H "Content-Type: application/json" \
  -d '{"artifact_order":{"quote_id":"QUOTE_ID"}}'
```

```bash
curl -sS -X POST http://localhost:3000/v1/artifact-orders/ORDER_ID/checkout
```

```bash
curl -sS http://localhost:3000/v1/developer/projects/PROJECT_ID/artifacts \
  -H "Content-Type: application/json" \
  -d '{"order_id":"ORDER_ID","sandbox_checkout":true}'
```

Artifact metadata must distinguish cryptographic validity, method
compatibility, review status, artifact status, reliance status, and payment
status.

## Operations

Longer-running operations expose status through:

```text
GET /v1/developer/operations/:external_id
GET /v1/integrations/operations/:external_id
```

Poll operations instead of assuming receipt issuance or artifact assembly
completed synchronously.

## SDK Examples

- [Python SDK Flow](examples/sdk-python-flow.md)
- [TypeScript SDK Flow](examples/sdk-typescript-flow.md)

The examples mirror the OpenAPI contract. Production SDKs should be generated
from OpenAPI instead of maintaining independent request types.
