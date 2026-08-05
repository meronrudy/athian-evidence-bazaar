# Rails Developer OS Orientation

## Purpose

The Rails Developer OS is the self-service product surface around the evidence
rail. It lets a startup begin with controlled source references, or an existing
Athian system begin with signed events, then move toward reviewable model
candidates, append-only decisions, sandbox pricing, artifact orders, and local
verification metadata.

Rails is a projection and workflow layer. It is not the cryptographic authority.

## Browser Surfaces

Implemented scaffold:

- `/agevidence/developer-os`: dual-path launchpad, API snippets, Project 4030
  replay helper, sandbox product cards, and webhook tester notes.
- `/agevidence`: funded-startup launchpad.
- `/agevidence/developer_projects/:id`: project evidence map.
- `/agevidence/developer_projects/:id/source_records`: source record console.
- `/agevidence/developer_projects/:id/pricing_quotes/new`: quote builder.
- `/agevidence/developer_projects/:id/pricing_quotes/:id`: quote detail.
- `/agevidence/developer_projects/:id/artifact_orders/:id`: sandbox checkout,
  artifact assembly, and verifier metadata.

Existing Evidence Bazaar pages remain intact: dashboard, AVSA chain, receipt
viewer, evidence explorer, bundle builder, VVB console, producer ledger,
co-claim workbench, methodology migration, marketplace, and country programs.

## Public API Surfaces

Implemented scaffold:

- `POST /v1/developer/projects`
- `GET /v1/developer/projects/:external_id`
- `GET /v1/developer/projects/:project_id/source_records`
- `POST /v1/developer/projects/:project_id/source_records`
- `POST /v1/developer/projects/:project_id/model_runs`
- `GET /v1/developer/projects/:project_id/model_runs/:id`
- `GET /v1/developer/candidates/:id`
- `PATCH /v1/developer/candidates/:id`
- `GET /v1/pricing/products`
- `GET /v1/pricing/products/:code`
- `POST /v1/pricing/quotes`
- `GET /v1/pricing/quotes/:external_id`
- `POST /v1/artifact-orders`
- `GET /v1/artifact-orders/:external_id`
- `POST /v1/artifact-orders/:external_id/checkout`
- `POST /v1/developer/projects/:project_id/artifacts`

The OpenAPI contract is `docs/openapi/agevidence.v1.yaml`.

## Source Record Path

Source records store references, not large documents:

```text
document_id
evidence_type
evidence_class
source_system
controlled_uri
commitment
disclosure_status
metadata
```

When submitted, `Agevidence::SourceRecordProjection` creates a
`source.manifest_available` IntegrationEvent so the source-record path and the
operational event path converge at the Evidence Event Inbox.

## Model and Review Path

Fixture-backed model runs are created through `Agevidence::ModelRunIngestion`.
The run stores normalized model output, candidates, and gaps. Every candidate
starts as `review_required`.

Human decisions are appended as `Agevidence::ReviewDecision` records. Older
decisions must not be edited in place. The candidate row is a projection of the
latest decision, not the authority record.

## Pricing and Artifact Path

`Agevidence::PricingQuote` persists:

- product code;
- pricing version;
- exact input scope;
- exact breakdown;
- expiration;
- accepted state.

`Agevidence::ArtifactOrder` persists the sandbox lifecycle:

```text
quoted
checkout_pending
paid
assembling
verification_pending
fulfilled
payment_failed
canceled
expired
```

Sandbox checkout marks an order paid for demo assembly. It is not collected or
recognized revenue.

Artifact assembly delegates to `Agevidence::ArtifactOrderFulfillment`, which in
turn delegates reliance artifact construction to `Agevidence::ArtifactAssembler`
and `ink_receipts`.

## Seeded Demo State

Seeds create:

- the canonical AVSA Evidence Bazaar chain;
- synthetic Northstar Methane Systems;
- Qwen3.5 reference adapter entry;
- source records;
- fixture model run;
- evidence candidates and gaps;
- append-only review decisions;
- country determinations;
- artifact engagements;
- sandbox quote and artifact order.

## Demo-Only Behavior

- Lightweight AVSA anchors may be created when a self-service project lacks one.
- Fixture model output is not production model output.
- Sandbox checkout is not revenue.
- Download URLs are scaffold metadata, not production signed object-storage
  URLs.

## Production-Hardening Backlog

- authentication and developer accounts;
- API tokens and scopes;
- runtime OpenAPI/schema conformance checks;
- production quote terms and payment provider integration;
- artifact object storage and signed URL expiration;
- durable job backend;
- role-aware review queues;
- production-safe audit logs.

## Non-Goals

- no Rails receipt crypto;
- no direct model authority;
- no upstream operational mutations;
- no country-specific controllers or templates.

## Read Next

- [OpenAPI Contract](../openapi/agevidence.v1.yaml)
- [Rails App README](../../athian_ink_rails_bootstrap/README.md)
- [Integration Inbox Orientation](INTEGRATIONS_EVENT_INBOX_ORIENTATION.md)
