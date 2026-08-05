# Troubleshooting

This guide lists common self-service failures and what they mean.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Invalid Signature

Symptom:

```text
SIGNATURE_INVALID
```

Meaning: the event was not signed with the expected integration credential or
the signing input changed.

Check:

- `X-Athian-Integration-Source`
- `X-Athian-Timestamp`
- `X-Athian-Signature`
- canonical payload used by the upstream signer

## Payload Digest Mismatch

Symptom:

```text
PAYLOAD_DIGEST_MISMATCH
```

Meaning: the submitted digest does not match the canonical event payload.

Check that the upstream system excludes the signature field from the signed
payload and preserves deterministic JSON key ordering.

## Duplicate Event

Symptom: same event ID returns `duplicate: true`.

Meaning: the same source submitted the same event ID and same digest again.
This is safe and idempotent.

## Conflicting Duplicate

Symptom:

```text
EVENT_ID_PAYLOAD_CONFLICT
```

Meaning: the same source reused an event ID with different content. Send a new
correction event instead of mutating the original event.

## Unknown Event Type

Symptom: event is retained but marked ignored.

Meaning: the event type is not part of the released eight-event vocabulary.
Unknown events are not silently repaired or processed.

## Missing Parent

Symptom: projection is marked `pending_parent` or `indeterminate`.

Meaning: an event arrived before the project, protocol, source manifest, or
other parent reference needed to complete the projection.

Late parent events can complete later projections without rewriting the
original event.

## Receipt Outbox Failed

Symptom: outbox status is `failed` or `dead_letter`.

Meaning: receipt issuance or verification through the trust boundary failed or
timed out.

Rails must not repair receipt commitments directly. Inspect the outbox record,
operation, verifier result, and trust-boundary logs.

## Model Output Looks Wrong

Model output is candidate evidence only. Reject the candidate or request more
evidence through an append-only review decision. Do not treat model confidence
as method eligibility or institutional reliance.

## Artifact Not Ready

Artifact assembly can wait on review, payment status, receipt outbox, or
verification state. Poll the operation and inspect the artifact order.

## Where to Inspect

Browser pages:

- `/integrations/events`
- `/integrations/operations`
- `/integrations/outbox`
- `/integrations/deliveries`
- `/integrations/dead-letter`

API operations:

- `GET /v1/developer/operations/:external_id`
- `GET /v1/integrations/operations/:external_id`
