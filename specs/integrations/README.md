# Athian Integration Event Contracts

This directory is the released contract for the append-only Evidence Event Inbox.
Rails models and controllers implement these schemas; they do not define the
contract by themselves.

The bridge is one-way for operational data. Existing Athian systems publish
signed business events, Rails preserves those events, and downstream workers
create evidence projections, receipt outbox rows, and artifact result events.

Canonical event commitments exclude transport integrity fields
`integrity.payload_digest` and `integrity.signature`. The submitted digest is
stored separately as the upstream assertion and must match the canonical payload
before the event is eligible for processing.

Initial inbound event types:

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

Non-goals for this bridge:

- Salesforce replication
- bidirectional CRUD synchronization
- producer master-data migration
- replacement payment execution
- replacement asset ledger
- country-specific Rails branches
- model approval authority
