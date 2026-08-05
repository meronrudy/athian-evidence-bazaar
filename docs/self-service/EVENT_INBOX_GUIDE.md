# Evidence Event Inbox Guide

Use the Evidence Event Inbox when an existing operational platform can publish
signed business events into AgEvidence.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Purpose

The inbox connects existing Athian or startup operational systems to the
evidence rail without migration or bidirectional synchronization.

```text
existing operational system
  -> signed JSON event
  -> POST /v1/integrations/events
  -> IntegrationEvent
  -> ExternalObjectMapping
  -> EvidenceProjection
  -> ReceiptOutbox
  -> result webhook
```

Existing systems remain authoritative for producer, protocol, asset,
marketplace, ledger, claim-right, and payment records. Rails preserves received
events and builds evidence projections.

## Endpoint

```text
POST /v1/integrations/events
```

Required headers:

```text
X-Athian-Integration-Source
X-Athian-Event-Id
X-Athian-Timestamp
X-Athian-Signature
Content-Type: application/json
```

## Supported Event Types

The initial vocabulary is intentionally small:

- `project.registered`
- `protocol.version_assigned`
- `source.manifest_available`
- `intervention.recorded`
- `model.run_completed`
- `verification.status_changed`
- `asset.status_changed`
- `producer.payment_recorded`

Do not add generic `object.updated` events. New livestock or country events
should be added only when a paid mapping requires schema, fixture, handler,
projection, outbox policy, tests, and commercial reference.

## Duplicate Behavior

Same source and event ID with the same digest:

- returns `202 Accepted`
- returns the original operation
- sets `duplicate: true`
- creates no duplicate event or receipt request

Same source and event ID with a different digest:

- returns `409 EVENT_ID_PAYLOAD_CONFLICT`
- creates no replacement event
- requires a new correction event

## Unknown Events

Unknown event types are retained but not processed. They are marked as ignored
so operators can inspect them without silently repairing or inventing business
meaning.

## Project 4030

Project 4030 is the Australian beef-style reference scenario. Start with:

- [Project 4030 Event Flow](examples/project-4030-event-flow.md)
- [Integration Project 4030 docs](../integrations/project-4030-example.md)
- [Fixture directory](../../examples/integrations/project_4030_beef)

## Trust Boundary

Integration signatures prove that an authorized source submitted an event.
Receipt signatures prove that a canonical evidence or decision payload was
issued under the INK receipt contract.

Do not treat one signature as a substitute for the other.
