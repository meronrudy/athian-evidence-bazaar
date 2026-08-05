# Integrations Event Inbox Orientation

## Purpose

The Evidence Event Inbox is the one-way bridge from existing Athian operational
systems into AgEvidence. It preserves upstream authority while giving Rails
enough normalized evidence state to request receipts and artifacts.

```text
Existing Athian platform
  -> signed JSON event
  -> POST /v1/integrations/events
  -> IntegrationEvent
  -> ExternalObjectMapping
  -> EvidenceProjection
  -> ReceiptOutbox
  -> result webhook
```

Rails must not migrate or replace producer, protocol, asset, marketplace,
ledger, claim-right, or payment systems.

## Implemented Scaffold

Inbound API:

- `POST /v1/integrations/events`
- `GET /v1/integrations/events/:external_event_id`
- `POST /v1/integrations/events/:external_event_id/replay`
- `GET /v1/integrations/operations/:external_id`
- `GET /v1/integrations/webhook_endpoints`
- `POST /v1/integrations/webhook_endpoints`
- `DELETE /v1/integrations/webhook_endpoints/:id`

Admin pages:

- `/integrations/sources`
- `/integrations/events`
- `/integrations/operations`
- `/integrations/outbox`
- `/integrations/deliveries`
- `/integrations/dead-letter`

Core models:

- `IntegrationSource`
- `IntegrationEvent`
- `IntegrationOperation`
- `ExternalObjectMapping`
- `EvidenceProjection`
- `ReceiptOutbox`
- `IntegrationWebhookEndpoint`
- `IntegrationDelivery`

## Event Vocabulary

The scaffold supports exactly eight inbound event types:

- `project.registered`
- `protocol.version_assigned`
- `source.manifest_available`
- `intervention.recorded`
- `model.run_completed`
- `verification.status_changed`
- `asset.status_changed`
- `producer.payment_recorded`

Initial outbound result events:

- `artifact.ready`
- `artifact.verification_failed`
- `reliance.recorded`

Do not add generic `object.updated` events. New event types should be gated by a
paid mapping and must include schema, fixture, handler, projection behavior,
outbox policy, and tests.

## Idempotency and Replay

Duplicate behavior:

- same source, same event ID, same payload: return the original operation;
- same source, same event ID, different payload: reject as conflict;
- replay: reprocess the preserved original event without creating a new inbox
  row.

Receipt requests use deterministic idempotency keys so replay cannot produce a
second receipt request for the same source event.

## Project 4030

The canonical fixture chain lives under
`examples/integrations/project_4030_beef`.

Replay helper:

```bash
ruby examples/integrations/project_4030_beef/replay_project_4030.rb \
  http://localhost:3000 athian_salesforce_production "$ATHIAN_INTEGRATION_SECRET"
```

Use this scenario to demonstrate:

- signed acceptance;
- duplicate handling;
- external identifier mapping;
- append-only evidence projection;
- receipt outbox creation;
- webhook result delivery;
- dead-letter inspection.

## Demo-Only Behavior

- HMAC-SHA256 is the implemented integration signing path.
- Ed25519 integration verification is configured as a future hardening item.
- Runtime validation uses scaffold checks rather than final JSON Schema
  enforcement.
- Webhook delivery is scaffolded and should not be represented as externally
  interoperable production delivery unless separately proven.

## Production-Hardening Backlog

- runtime JSON Schema validation;
- timestamp replay-window enforcement;
- KMS or approved secret storage;
- Ed25519 public-key verification through the trust boundary;
- durable processing queue;
- production retry policies and alerting;
- source credential rotation and suspension workflow;
- outbound webhook domain validation and secret rotation;
- diagnostic export and replay audit records.

## Non-Goals

- no Salesforce table polling;
- no bidirectional synchronization;
- no full operational data replication;
- no producer or payment authority migration;
- no Kafka or generic service bus for the first bridge.

## Read Next

- [Integration Overview](../integrations/overview.md)
- [Event Envelope](../integrations/event-envelope.md)
- [Idempotency](../integrations/idempotency.md)
- [Project 4030 Example](../integrations/project-4030-example.md)
