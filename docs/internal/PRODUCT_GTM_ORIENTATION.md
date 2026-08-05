# Product and GTM Orientation

## Product Position

AgEvidence should be described as a developer operating system for agricultural
evidence. The promise is speed from a startup source record or an existing
Athian operational event to a portable, reviewable, independently verifiable
reliance artifact.

The positioning is:

```text
Developer OS
  + Evidence Event Inbox
  + review-required model candidates
  + append-only human decisions
  + priced reliance artifacts
```

It is not a replacement marketplace, payment ledger, producer database, VVB, or
government authority.

## Target Users

Primary users:

- funded agricultural startups with structured source records;
- Athian teams bridging current operational systems into AgEvidence;
- protocol, VVB, buyer, auditor, sponsor, and insurer stakeholders evaluating
  reliance artifacts.

Good first customer profile:

- structured project, source, model, verification, asset, or payment records;
- clear evidence pain;
- willingness to map data into a bounded event contract;
- interest in portable artifacts rather than only dashboard reporting.

Poor first customer profile:

- requires a new scientific ontology before any evidence map;
- wants Rails to become the operational system of record;
- requires production billing, confidential customer data, or live registry
  integration before a paid architecture sprint.

## Australian GTM Motion

Use the implemented Evidence Event Inbox as the near-term product surface. The
first offer is:

```text
Australian Livestock Evidence Event Bridge
```

The discovery call should test whether the customer can provide:

- project registration data;
- protocol or method assignment;
- source manifest references;
- intervention records;
- model outputs or measurement records;
- verification state;
- asset state;
- producer payment lineage.

Do not add future livestock events until a paid mapping requires them. Candidate
future events include cohort enrollment, product batch release, dosage recorded,
productivity observed, safety observation, laboratory result, and regulatory
submission or determination.

## Product Catalog

The current machine-readable catalog lives in
`athian_ink_rails_bootstrap/config/agevidence/products.yml`.

Initial product hypotheses include:

- Evidence Architecture Sprint;
- Protocol Evidence Implementation;
- Verification Readiness Cycle;
- Enterprise Reliance Artifact;
- Managed Evidence Plane;
- Private Deployment Model Registry;
- Sponsor Portfolio Program;
- Methodology Migration or Dispute Event.

All commercial values are illustrative planning assumptions. They are not
quotes, commitments, booked value, cash collected, or recognized revenue.

## Customer Discovery Flow

1. Start with the Developer OS story: source record or signed event to artifact.
2. Confirm which existing system remains authoritative.
3. Map the customer records to the eight-event inbox vocabulary.
4. Identify missing evidence and authority boundaries.
5. Price an Evidence Architecture Sprint using the sandbox quote model.
6. Only add new events, schemas, or handlers after a paid mapping shows the need.

## Implemented Scaffold

- `/agevidence/developer-os` shows the dual-path launchpad.
- `/v1/developer/projects` creates sandbox projects.
- `/v1/developer/projects/:project_id/source_records` submits controlled source
  references.
- `/v1/pricing/products` exposes the price book.
- `/v1/pricing/quotes` creates versioned sandbox quotes.
- `/v1/artifact-orders` demonstrates quote-to-order lifecycle.
- The OpenAPI contract and SDK examples exist for developer onboarding.

## Demo-Only Behavior

- Sandbox checkout does not collect payment.
- Artifact metadata does not prove external reliance.
- Fixture model output is not an approving authority.
- Lightweight AVSA anchors are scaffold behavior.

## Production-Hardening Backlog

- customer-facing authentication and API keys;
- generated SDKs from OpenAPI;
- production pricing governance and quote terms;
- live checkout/subscription integration;
- object-storage artifact delivery;
- signed outbound customer webhooks;
- customer support and observability workflows.

## Non-Goals

- no token-based evidence artifact pricing;
- no automatic scientific acceptance;
- no replacement payment execution;
- no generic enterprise implementation practice;
- no country-specific product forks.

## Read Next

- [Australian GTM Backlog](../strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md)
- [Premium Artifact Catalog](../implementation/PREMIUM_ARTIFACT_CATALOG.md)
- [OpenAPI Contract](../openapi/agevidence.v1.yaml)
