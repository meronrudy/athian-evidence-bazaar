# Replay

Replay reprocesses the preserved event. It does not create a new
`IntegrationEvent`.

Replay requires:

- a signature-valid event;
- an explicit operator reason;
- a new `IntegrationOperation`;
- deterministic handlers that reuse mappings, projections, and receipt outbox
  rows where the event was already processed.

Replay must not create duplicate receipts for the same idempotency key.
