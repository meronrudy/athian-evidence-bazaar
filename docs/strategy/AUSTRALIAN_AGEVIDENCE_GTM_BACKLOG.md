# Australian AgEvidence GTM Backlog

Repository baseline: `f71d04d16c747374c215734e8ce191824dd63592`  
Commit: `Add append-only evidence event inbox`

## Executive Summary

The Australian GTM motion should now be organized around the implemented Evidence Event Inbox, not around a future bridge build.

At this baseline, the repository is a demonstration-grade integration and evidence-projection monolith:

```text
Existing Athian operational platform
  -> signed normalized JSON event
  -> POST /v1/integrations/events
  -> Rails IntegrationEvent inbox
  -> ExternalObjectMapping
  -> append-only EvidenceProjection
  -> ReceiptOutbox
  -> ink_receipts
  -> receipt verification projection
  -> signed result webhook
```

The existing Athian platform remains authoritative for producers, protocols, assets, marketplace activity, ledger state, claim rights, and payment execution. Rails is authoritative only for received events, normalized mappings, evidence projections, receipt requests, receipt-state projections, and outbound artifact notifications.

The commercial challenge is no longer deciding what bridge architecture to build. It is proving that one Australian livestock technology company will pay to map its existing operational evidence into the architecture now present.

## Current Repository Baseline

The repository now exposes these implemented integration interfaces:

```text
POST   /v1/integrations/events
GET    /v1/integrations/events/:external_event_id
POST   /v1/integrations/events/:external_event_id/replay
GET    /v1/integrations/operations/:external_id
GET    /v1/integrations/webhook_endpoints
POST   /v1/integrations/webhook_endpoints
DELETE /v1/integrations/webhook_endpoints/:id
```

It also includes internal Rails inspection surfaces for integration sources, received events, operations, receipt outbox records, webhook deliveries, retries, and dead-letter records.

The implemented data model includes:

- `IntegrationSource`
- `IntegrationEvent`
- `IntegrationOperation`
- `ExternalObjectMapping`
- `EvidenceProjection`
- `ReceiptOutbox`
- `IntegrationWebhookEndpoint`
- `IntegrationDelivery`

The repository preserves raw event JSON, canonical event JSON, payload commitments, supplied commitments, signatures, signature status, schema status, processing status, errors, attempts, correlation, supersession references, mappings, projection versions, outbox idempotency, receipt verification results, webhook idempotency, response status, retry timing, and dead-letter state.

The supported inbound event vocabulary is:

- `project.registered`
- `protocol.version_assigned`
- `source.manifest_available`
- `intervention.recorded`
- `model.run_completed`
- `verification.status_changed`
- `asset.status_changed`
- `producer.payment_recorded`

The supported outbound result events are:

- `artifact.ready`
- `artifact.verification_failed`
- `reliance.recorded`

The Project 4030 integration example, integration schemas, and integration docs already exist under:

```text
examples/integrations/project_4030_beef/
specs/integrations/
docs/integrations/
```

## Current Limitations

This is an implemented scaffold, not production infrastructure.

Current integration authentication is HMAC-SHA256 shared-secret signing. Ed25519 is configured as a source option but explicitly returns unsupported. Production hardening should add Ed25519 public-key verification, KMS-backed secret management, rotation, revocation, and timestamp-window enforcement.

Runtime validation is still lightweight Ruby envelope and required-field checking. JSON Schema files exist under `specs/integrations/`, but the runtime does not yet execute those schemas as the authoritative validator. Production hardening should add runtime JSON Schema validation, schema digest commitments, compatibility rules, schema deprecation, version negotiation, fixture-to-schema conformance tests, and CI rejection of invalid schemas.

Receipt issuance still passes through the current scaffolded `ink_receipts` path. If a mapped project has no AVSA, the outbox processor creates a lightweight integration AVSA and an `ATH-INTEGRATION` projection protocol to anchor generated receipts. This is useful demo behavior, but it is not a real AVSA issuance decision, approved methodology, registry recognition, APVMA determination, or external verifier reliance.

The current tests prove scaffold behavior: signed event acceptance, duplicate handling, conflicting-payload rejection, invalid-signature retention, unknown-event retention, project projection, external mapping, evidence projection, deterministic outbox creation, receipt creation, and receipt idempotency. They do not prove production deployment, load capacity, operational uptime, penetration resistance, external interoperability, Salesforce delivery, AWS delivery, external receipt verification, customer use, or recognized revenue.

Do not state that CI passed for this baseline unless the suite is run separately and the results are recorded.

## Australian Account Priority

The first GTM cohort should fit the existing eight-event vocabulary. The best immediate targets are livestock technology companies whose current systems already produce structured project, source-record, intervention, model-output, verification, asset, or payment data.

Priority order:

1. DIT AgTech
2. Agscent
3. Number 8 Bio
4. Bovotica
5. Rumin8
6. Sea Forest
7. ProAgni
8. Ruminant BioTech

The first outreach should sell a bounded integration architecture motion, not a full platform migration. The offer:

> Keep the existing operational platform. Publish eight signed material events. Receive an independently inspectable evidence projection, receipt graph, and artifact-result callback.

## Phased GTM Backlog

### Phase 0: Demonstrate the Implemented Bridge

Timing: days 0-30.

Objective: turn Project 4030 into a clean, reproducible product demonstration.

Use the existing:

- `examples/integrations/project_4030_beef/`
- `docs/integrations/`
- `specs/integrations/`
- `POST /v1/integrations/events`
- `IntegrationEvent`
- `EvidenceProjection`
- `ReceiptOutbox`
- `IntegrationDelivery`

Demonstrate the eight-event sequence:

```text
project.registered
  -> protocol.version_assigned
  -> source.manifest_available
  -> intervention.recorded
  -> model.run_completed
  -> verification.status_changed
  -> asset.status_changed
  -> producer.payment_recorded
```

The demonstration must show signed acceptance, duplicate handling, conflicting-payload rejection, missing-parent handling, asynchronous operation state, external identifier mapping, evidence projection, receipt-outbox creation, receipt verification, webhook result, retry, and dead-letter inspection.

GTM artifact: `Australian Livestock Evidence Event Bridge`.

Exit gate:

- one clean scripted demonstration;
- one externally reproducible integration example;
- five qualified Australian companies shown the exact event contract;
- three technical discovery sessions;
- one company provides a sample upstream payload map.

No new vertical is added in Phase 0.

### Phase 1: First Paid Integration Architecture Engagement

Timing: days 31-90.

Product: `Evidence Architecture Sprint`.

Current planning price: `$25,000`.

Scope: map one target company current records into the implemented eight-event contract.

Deliver:

- source-system inventory;
- external identifier map;
- event mapping;
- missing evidence map;
- signature and secret-handling plan;
- result-webhook design;
- reliance-recipient map;
- receipt graph;
- production-hardening backlog;
- fixed-scope implementation quote.

Best first account types are companies that already emit structured operational data. Priority sequence: DIT AgTech, Agscent, Number 8 Bio, Bovotica, then Rumin8.

Repository permission: only add new fields or event types required by the first contracted mapping.

Likely first livestock additions:

- `trial.cohort_registered`
- `product.batch_released`
- `dosage.recorded`
- `productivity.observed`
- `safety.observation_recorded`
- `laboratory.result_available`
- `regulatory.submission_recorded`
- `regulatory.determination_recorded`

Each new event requires schema, fixture, handler, projection type, outbox policy, parent requirements, success test, duplicate test, invalid-event test, and commercial engagement reference.

Revenue gate:

- one or two paid Architecture Sprints;
- `$25,000-$50,000` contracted;
- at least 70 percent of the first customer path uses existing inbox infrastructure.

### Phase 2: Production Hardening for First Implementation

Timing: months 4-6.

Objective: harden the existing bridge rather than build another integration architecture.

Required work:

- PostgreSQL production configuration;
- real background-job backend;
- runtime JSON Schema validation;
- Ed25519 public-key signature verification;
- KMS or secrets-manager integration;
- timestamp freshness and replay-window enforcement;
- source credential rotation;
- encrypted webhook secrets;
- real HTTP delivery testing;
- exponential retry policy;
- dead-letter recovery procedure;
- structured metrics and logs;
- rate limiting;
- tenant and source authorization;
- production object-storage references;
- released Rust receipt and verifier binding;
- removal or explicit labeling of lightweight AVSA projection behavior;
- external clean-machine verification.

Commercial products:

- `Protocol Evidence Implementation`
- `Verification Readiness Cycle`
- `Enterprise Reliance Artifact`

Revenue gate:

- one paid production implementation;
- one external reviewer or relying institution;
- one production-signed artifact;
- one reliance decision linked to an `ArtifactEngagement`.

### Phase 3: Connect Repository Growth to Revenue

Current gap: the event inbox is implemented, but growth-to-revenue attribution is not.

The repository already has enough objects to attach the first attribution layer:

- `IntegrationSource`
- `IntegrationEvent`
- `EvidenceProjection`
- `ReceiptOutbox`
- `DeveloperProject`
- `ArtifactEngagement`
- `EvidenceBundle`
- `RelianceEvent`

Minimal implementation:

- extend `ArtifactEngagement` with integration source, first event, capability release, release SHA, contracted value, invoiced value, cash collected, and milestone dates;
- extend `RelianceEvent` with obligation code, decision authority, decision reference, expansion trigger, and expansion value;
- add `Agevidence::GrowthRevenueAttribution`.

The attribution report should show sources onboarded, events accepted, projects projected, verified outboxes, artifacts purchased, contracted value, collected cash, reliance events, expansion value, support minutes, dead-letter rate, and configuration reuse.

North-star metric:

```text
Collected revenue and external reliance per reusable integration capability
```

## Deferred Claims

The current repository supports a livestock-project integration sequence. It does not yet justify claiming production support for soil carbon, remote-sensing model validation, autonomous machinery execution, fermentation manufacturing, agricultural hydrogen, APVMA submission management, ACCU issuance, Verra audit, or enterprise Scope 3 reporting.

These should remain later adapter families. The next repository growth should be driven by the first Australian company willing to map real upstream records into the implemented Evidence Event Inbox.

## Strategic Position

At commit `f71d04d16c747374c215734e8ce191824dd63592`, the product is no longer merely a conceptual evidence bazaar with a proposed bridge.

It is a demonstration-grade append-only evidence integration bridge that accepts signed agricultural events, preserves upstream authority, maps external objects, creates evidence projections, queues idempotent receipt issuance, verifies receipt projections, and returns result events through managed webhooks.

The first Australian GTM motion should sell proof of integration reuse and reliance utility, not a platform replacement.
