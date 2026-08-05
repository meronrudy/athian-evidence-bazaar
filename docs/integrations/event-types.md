# Event Types

The bridge starts with eight material business transitions:

| Event | Purpose |
| --- | --- |
| `project.registered` | Create or update the developer-project projection |
| `protocol.version_assigned` | Link the project to a protocol or method-version projection |
| `source.manifest_available` | Record source commitments and access references |
| `intervention.recorded` | Append intervention evidence and request a receipt |
| `model.run_completed` | Persist normalized model execution and candidate/gap output |
| `verification.status_changed` | Append verifier status, criteria, and exceptions |
| `asset.status_changed` | Record asset projection state without recreating the asset ledger |
| `producer.payment_recorded` | Record payment lineage and request a payment receipt |

Do not add generic `object.updated` events. Each event must be material to
evidence, verification, claim custody, reliance, asset state, or producer
economics.
