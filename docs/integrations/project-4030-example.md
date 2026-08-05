# Project 4030 Example

Synthetic fixtures live in:

```text
examples/integrations/project_4030_beef/
```

The chain is:

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

Expected bridge behavior:

- every event is preserved;
- upstream identifiers are mapped;
- projections tolerate late or missing parents;
- receipt requests use the transactional outbox;
- receipt issuance is asynchronous;
- model output remains non-authoritative;
- artifact result events return only references and verification status.
