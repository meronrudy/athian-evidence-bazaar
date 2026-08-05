# Engineering Architecture Orientation

## Repository Shape

The monorepo separates human workflow, model extraction, and trust operations:

```text
athian_ink_rails_bootstrap/
  Rails control plane, browser UI, public APIs, projections, jobs

athian_ink_rails_bootstrap/gems/ink_receipts/
  Ruby facade into receipt, bundle, verification, and signing behavior

services/agevidence-model/
  Python fixture/local/remote model service for extraction and gap detection

crates/
  Rust BAINK workspace for canonicalization, receipt validation, bundle
  integrity, signing/verifier substrate, schema, and CLI behavior

specs/
  JSON/YAML contracts for AgEvidence, integrations, country adapters, and
  receipt payloads
```

The dependency direction should remain downward:

```text
Rails workflow
  -> ink_receipts facade
  -> Rust trust kernel
```

The generic Rust kernel must not depend on Rails, country adapters, Python
model code, or customer-specific workflow.

## Implemented Scaffold

- Rails exposes the Evidence Bazaar demo, AgEvidence Developer OS, Event Inbox,
  country programs, integration admin pages, and sandbox pricing/order flows.
- Python provides fixture-backed evidence extraction contracts.
- Rust provides domain validation and verifier tests.
- `ink_receipts` supplies demo receipt, bundle, verification, event
  canonicalization, and integration-signature helpers.
- OpenAPI and SDK examples provide developer-facing contract starting points.

## Core Data Flow

```text
Source record path:
developer API or browser
  -> Agevidence::SourceRecord
  -> source.manifest_available IntegrationEvent
  -> EvidenceProjection
  -> ReceiptOutbox
  -> ink_receipts

Operational event path:
upstream signed event
  -> /v1/integrations/events
  -> IntegrationEvent
  -> ExternalObjectMapping
  -> EvidenceProjection
  -> ReceiptOutbox
  -> webhook result projection
```

Model output stays separate:

```text
source documents
  -> fixture model service
  -> Agevidence::ModelRun
  -> EvidenceCandidate and EvidenceGap
  -> append-only ReviewDecision
```

## Trust Boundary

Rails must never compute receipt commitments, sign receipts, verify receipt
cryptography, or evaluate trust policy directly. Rails can persist projections
and call facade methods.

Integration event signing is not receipt signing. Event HMAC proves the event
came from an integration source. INK receipts prove the canonical evidence or
decision payload was issued under the receipt trust contract.

## Thin-Waist Country Architecture

Country rules live in YAML adapter packs, not controllers or templates. Adding a
country should not require a new receipt envelope, cryptographic code, model
runtime, or Rails workflow.

Keep these states separate:

- cryptographic validity: `valid`, `invalid`, `indeterminate`;
- method compatibility: `eligible`, `eligible_with_conditions`,
  `outside_current_method`, `method_extension_required`,
  `insufficient_evidence`, `unassigned`;
- institutional reliance: `accepted`, `relied_on`, `rejected`,
  `needs_more_evidence`.

## Demo-Only Behavior

- Fixture mode is the default for model extraction.
- Some receipt issuance uses scaffold projection behavior in the facade.
- Lightweight AVSA anchors support demo artifact assembly where a project does
  not already have a real AVSA.
- Runtime event validation is still lighter than final JSON Schema enforcement.

## Production-Hardening Backlog

- install and validate Rails under Ruby 3.3.8 with Node/npm;
- add durable background queue configuration;
- enforce JSON Schema at runtime;
- move signing and verification secrets to approved secret storage;
- replace scaffold receipt behavior with released receipt schemas and verifier
  bindings;
- add tenant isolation and API authorization;
- add object storage for artifacts and source references;
- add production observability and replay controls.

## Validation Commands

```bash
cargo test --workspace
cd services/agevidence-model && python3 -m pytest
cd athian_ink_rails_bootstrap && bin/rails db:migrate db:seed test
cd athian_ink_rails_bootstrap && npm run build
rg -n "\bDigest\b|\bOpenSSL\b|crypto\.subtle\.digest|SHA256|SHA-256" athian_ink_rails_bootstrap/app athian_ink_rails_bootstrap/db
```

The app currently declares Ruby 3.3.8. Do not claim Rails CI passed unless that
toolchain is active and the Rails test suite has actually run.

## Non-Goals

- no Rails receipt crypto;
- no Python receipt signing;
- no country-specific Rails controllers;
- no direct Salesforce polling or bidirectional sync;
- no production billing, confidential data, or live registry integration in the
  scaffold.

## Read Next

- [Scaffold Handoff](../implementation/AGEVIDENCE_SCAFFOLD_HANDOFF.md)
- [Global Thin Waist](../implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md)
- [Model Authority Boundary](../implementation/MODEL_AUTHORITY_BOUNDARY.md)
