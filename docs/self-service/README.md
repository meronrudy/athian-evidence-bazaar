# AgEvidence Self-Service Guides

Build your product. Let Athian handle evidence.

Evidence first. Carbon second.

This guide pack is the customer-facing path into the AgEvidence Developer OS.
It is written for startups, customer operators, developers, API users,
reviewers, and integration engineers who need to move from source records or
signed operational events to a sandbox reliance artifact without a sales call.

## What You Can Do

Implemented scaffold:

- Create a sandbox developer project.
- Add controlled source-record references.
- Replay the Project 4030 signed event fixture.
- Run fixture-backed model extraction.
- Review evidence candidates and gaps.
- Create sandbox quotes and artifact orders.
- Assemble artifact metadata with local verification commands.
- Register webhook endpoints and inspect operations.

Demo-only behavior:

- Sandbox pricing and orders are illustrative planning records, not booked,
  collected, or recognized revenue.
- Fixture model output is candidate evidence only.
- Model output cannot approve a method, certify reductions, determine claim
  ownership, or create institutional reliance.
- Rails is a projection and control plane, not the receipt trust boundary.

Production-hardening backlog:

- Production authentication and tenancy.
- Runtime JSON Schema validation.
- Production signing, key rotation, and secret management.
- Durable queue, object storage, monitoring, and security review.
- External customer interoperability and production payment collection.

## Choose Your Entry Path

| Path | Use When | Start Here |
| --- | --- | --- |
| Source Records | You have documents, files, lab exports, trial reports, or controlled references. | [Customer Quickstart](CUSTOMER_QUICKSTART.md) |
| Developer API | You want to create projects, source records, reviews, quotes, orders, and artifacts with `/v1`. | [API User Guide](API_USER_GUIDE.md) |
| Evidence Event Inbox | You already have an operational system that can emit signed business events. | [Event Inbox Guide](EVENT_INBOX_GUIDE.md) |
| Project 4030 | You want to replay the Australian beef reference scenario. | [Project 4030 Flow](examples/project-4030-event-flow.md) |
| SDK Examples | You want a minimal Python or TypeScript client. | [Python SDK Flow](examples/sdk-python-flow.md) |

## Role Paths

| Role | Recommended Path |
| --- | --- |
| Customer operator | [Customer Quickstart](CUSTOMER_QUICKSTART.md), then [Pricing and Artifacts](PRICING_ORDERS_ARTIFACTS_GUIDE.md) |
| Startup developer | [Developer Quickstart](DEVELOPER_QUICKSTART.md), then [API User Guide](API_USER_GUIDE.md) |
| API user | [API User Guide](API_USER_GUIDE.md), then [Source Records](SOURCE_RECORDS_GUIDE.md) |
| Integration engineer | [Event Inbox Guide](EVENT_INBOX_GUIDE.md), then [Webhooks and Operations](WEBHOOKS_OPERATIONS_GUIDE.md) |
| Scientific reviewer | [Model and Review Guide](MODEL_REVIEW_GUIDE.md), then [Local Verification](LOCAL_VERIFICATION_GUIDE.md) |
| Buyer, auditor, or VVB reviewer | [Local Verification](LOCAL_VERIFICATION_GUIDE.md), then [Glossary](GLOSSARY.md) |

## Canonical References

- OpenAPI contract: [docs/openapi/agevidence.v1.yaml](../openapi/agevidence.v1.yaml)
- Canonical Python SDK and CLI: [sdks/python](../../sdks/python/README.md)
- Python usage example: [examples/sdk/python/agevidence_client.py](../../examples/sdk/python/agevidence_client.py)
- TypeScript SDK example: [examples/sdk/typescript/agevidenceClient.ts](../../examples/sdk/typescript/agevidenceClient.ts)
- Integration docs: [docs/integrations/overview.md](../integrations/overview.md)
- Project 4030 fixtures: [examples/integrations/project_4030_beef](../../examples/integrations/project_4030_beef)
- Trust boundary orientation: [docs/internal/TRUST_BOUNDARY_ORIENTATION.md](../internal/TRUST_BOUNDARY_ORIENTATION.md)

## Safety Boundary

The self-service path does not move producer, protocol, asset, marketplace,
ledger, claim-right, or payment authority into Rails. Existing Athian
operational systems remain authoritative for those records. Rails stores
evidence projections, review state, receipt requests, artifact metadata, and
operation status.

Cryptographic validity, method compatibility, review status, artifact status,
reliance status, and payment status are separate states. One state is never a
substitute for another.
