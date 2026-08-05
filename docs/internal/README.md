# Internal Orientation

This folder is the first-read orientation pack for internal Athian stakeholders
working with the AgEvidence repository.

The thesis is:

```text
Evidence first.
Carbon second.
```

The current repository is a scaffolded Developer OS for agricultural evidence.
It gives a startup or an existing Athian operational system the shortest path
from source records or signed events to reviewable evidence projections,
receipt requests, sandbox priced artifacts, and local verification metadata.

## Current Baseline

Implemented scaffold:

- Rails is the public control plane and projection UI.
- The append-only Evidence Event Inbox accepts signed operational events through
  `/v1/integrations/events`.
- The source-record path accepts controlled references through
  `/v1/developer/projects/:project_id/source_records`.
- Fixture-backed model runs create source-linked candidates and evidence gaps.
- Human review decisions are append-only.
- Sandbox quote and artifact-order records demonstrate the revenue path.
- OpenAPI and SDK examples exist for developer onboarding.
- `ink_receipts` and Rust remain the trust boundary for receipt-like behavior.

Demo-only behavior:

- Fixture model output is not production inference.
- Sandbox checkout is not recognized revenue.
- Sandbox quote and order values are not recognized revenue.
- Lightweight AVSA anchors may be created for demo artifact assembly.
- HMAC integration signing exists; Ed25519 integration verification remains a
  production-hardening item.

Production-hardening backlog:

- Runtime JSON Schema validation for integration events.
- Production signing, key rotation, and secret management.
- Durable queue and object-storage configuration.
- Released receipt schemas and verifier integration.
- Authentication, tenancy, billing, monitoring, and security review.

Non-goals:

- No Rails receipt cryptography.
- No model authority or automatic scientific approval.
- No bidirectional synchronization with Athian operational systems.
- No country-specific Rails branches or receipt envelopes.
- No migration of producer, asset, ledger, marketplace, or payment authority
  into Rails.

## Role Reading Paths

| Role | Start Here | Then Read |
| --- | --- | --- |
| Executives | [Executive Orientation](EXECUTIVE_ORIENTATION.md) | [Australian GTM Backlog](../strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md) |
| Product and GTM | [Product and GTM Orientation](PRODUCT_GTM_ORIENTATION.md) | [Premium Catalog](../implementation/PREMIUM_ARTIFACT_CATALOG.md) |
| Engineering leads | [Engineering Architecture Orientation](ENGINEERING_ARCHITECTURE_ORIENTATION.md) | [Scaffold Handoff](../implementation/AGEVIDENCE_SCAFFOLD_HANDOFF.md) |
| Rails developers | [Rails Developer OS Orientation](RAILS_DEVELOPER_OS_ORIENTATION.md) | [Rails README](../../athian_ink_rails_bootstrap/README.md) |
| Integration engineers | [Integration Inbox Orientation](INTEGRATIONS_EVENT_INBOX_ORIENTATION.md) | [Integration Docs](../integrations/overview.md) |
| Trust-layer engineers | [Trust Boundary Orientation](TRUST_BOUNDARY_ORIENTATION.md) | [Model Authority Boundary](../implementation/MODEL_AUTHORITY_BOUNDARY.md) |
| Model-service engineers | [Model Service Orientation](MODEL_SERVICE_ORIENTATION.md) | [Developer GTM Spec](../implementation/AGEVIDENCE_DEVELOPER_GTM.md) |
| Country-policy developers | [Country Adapter Orientation](COUNTRY_ADAPTER_ORIENTATION.md) | [Global Thin Waist](../implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md) |
| Operators | [Operations Orientation](OPERATIONS_ORIENTATION.md) | [Project 4030 Example](../integrations/project-4030-example.md) |

## External Self-Service Companion

Customer, startup developer, and API user documentation lives at
[docs/self-service](../self-service/README.md). Use it for external activation
paths, quickstarts, API examples, Project 4030 replay, sandbox quote/order
walkthroughs, webhook concepts, and local verification language.

Internal documents may discuss GTM hypotheses, campaign risks, and unfinished
hardening work. The self-service guides are the safer external starting point
and avoid internal account dossiers, revenue gates, and campaign ownership
details.

## Canonical References

- Strategy proposal: [ATHIAN_AGEVIDENCE_CSUITE_PROPOSAL.md](../strategy/ATHIAN_AGEVIDENCE_CSUITE_PROPOSAL.md)
- Australian GTM backlog: [AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md](../strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md)
- Developer GTM implementation spec: [AGEVIDENCE_DEVELOPER_GTM.md](../implementation/AGEVIDENCE_DEVELOPER_GTM.md)
- Scaffold handoff: [AGEVIDENCE_SCAFFOLD_HANDOFF.md](../implementation/AGEVIDENCE_SCAFFOLD_HANDOFF.md)
- Global thin waist: [GLOBAL_THIN_WAIST_ARCHITECTURE.md](../implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md)
- Model authority boundary: [MODEL_AUTHORITY_BOUNDARY.md](../implementation/MODEL_AUTHORITY_BOUNDARY.md)
- Premium artifact catalog: [PREMIUM_ARTIFACT_CATALOG.md](../implementation/PREMIUM_ARTIFACT_CATALOG.md)
- Integration docs: [docs/integrations](../integrations/overview.md)
- OpenAPI contract: [agevidence.v1.yaml](../openapi/agevidence.v1.yaml)
- Self-service guides: [docs/self-service](../self-service/README.md)

## Working Rule

If a local document and a canonical implementation spec disagree, treat the
canonical spec as the deeper source, then update the orientation doc so the next
reader does not inherit the mismatch.
