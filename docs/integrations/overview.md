# Append-Only Evidence Event Inbox

The integration bridge receives signed JSON events from Athian operational
systems and turns them into evidence projections, receipt requests, and portable
artifact workflows.

The existing operational platform remains authoritative for producers,
protocols, assets, marketplace activity, ledger state, claim rights, and payment
execution. Rails preserves the inbound event, maps upstream identifiers, appends
projection state, and requests receipts asynchronously through `ink_receipts`.

Initial endpoint:

```text
POST /v1/integrations/events
```

Successful ingestion is asynchronous:

```json
{
  "event_id": "evt_01J...",
  "status": "accepted",
  "duplicate": false,
  "operation_id": "op_01J..."
}
```

The controller does not run models, issue receipts, build bundles, call Stripe,
or call Salesforce during intake.
