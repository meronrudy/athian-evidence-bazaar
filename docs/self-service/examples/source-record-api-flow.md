# Source Record API Flow

This walkthrough uses the `/v1/developer` API to create a sandbox evidence path
from source records to artifact metadata.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## 1. Create a Project

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

Save the returned project ID as `PROJECT_ID`.

## 2. Add Source Records

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

Repeat for invoices, ration logs, model inputs, measurement exports, or lab
reports.

## 3. Run Fixture Extraction

```bash
curl -sS http://localhost:3000/v1/developer/projects/PROJECT_ID/model_runs \
  -H "Content-Type: application/json" \
  -d '{"adapter_id":"qwen3.5-4b-reference"}'
```

All model output remains `review_required`. It cannot approve methods, certify
reductions, determine ownership, or create institutional reliance.

## 4. Review a Candidate

```bash
curl -sS -X PATCH http://localhost:3000/v1/developer/candidates/CANDIDATE_ID \
  -H "Content-Type: application/json" \
  -d '{
    "review_decision": {
      "decision": "accepted",
      "reason": "The source reference supports this candidate.",
      "reviewer_role": "scientific_reviewer_sandbox"
    }
  }'
```

## 5. Create Quote, Order, and Artifact

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
        "relying_parties": 1
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

## 6. Verify Artifact Metadata

Confirm the response separates cryptographic validity, method compatibility,
review status, artifact status, reliance status, and payment status.

Use the local verification command shown in the artifact metadata.
