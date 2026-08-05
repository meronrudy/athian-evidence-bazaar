# Project 4030 Beef Integration Scenario

This fixture set models the first bridge acceptance chain using synthetic data.
The events intentionally preserve upstream identifiers and avoid migrating
producer, asset, ledger, marketplace, or payment authority into Rails.

The fixture files include scaffold integrity values. A production forwarder
must canonicalize each envelope, compute the payload commitment over the
canonical payload excluding transport integrity fields, and sign the same
canonical payload with the configured integration source secret.

Happy path:

1. `01-project.registered.json`
2. `02-protocol.version_assigned.json`
3. `03-source.manifest_available.json`
4. `04-intervention.recorded.json`
5. `05-model.run_completed.json`
6. `06-verification.status_changed.json`
7. `07-asset.status_changed.json`
8. `08-producer.payment_recorded.json`

Expected outcome:

- upstream IDs are mapped to Rails projections;
- evidence projections are append-only;
- receipt requests are written through `ReceiptOutbox`;
- the receipt graph is issued asynchronously through `ink_receipts`;
- a verification-readiness artifact can later emit `artifact.ready`.
