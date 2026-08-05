# Idempotency

Inbound idempotency key:

```text
integration_source_id + external_event_id
```

Duplicate behavior:

- same source, same event ID, same payload commitment: return `202` with
  `duplicate: true` and the original operation ID;
- same source, same event ID, different payload commitment: return
  `409 EVENT_ID_PAYLOAD_CONFLICT`;
- never create a second event row for the same source and event ID.

Receipt outbox idempotency key:

```text
integration-source:event-id:receipt-type:payload-digest
```

Replays use the preserved event and deterministic projection/outbox keys.
