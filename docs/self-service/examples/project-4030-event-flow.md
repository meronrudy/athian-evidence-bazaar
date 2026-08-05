# Project 4030 Event Flow

Project 4030 is the synthetic Australian beef-style event inbox scenario. It
shows how an existing operational system can publish eight signed material
events without moving producer, protocol, asset, ledger, or payment authority
into Rails.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Fixture Files

```text
examples/integrations/project_4030_beef/
```

Happy path:

```text
01-project.registered.json
02-protocol.version_assigned.json
03-source.manifest_available.json
04-intervention.recorded.json
05-model.run_completed.json
06-verification.status_changed.json
07-asset.status_changed.json
08-producer.payment_recorded.json
```

## Replay

Start Rails, then run:

```bash
python3 -m pip install -e "sdks/python[test]"
agevidence replay project-4030
```

The CLI signs each fixture and posts it to:

```text
POST /v1/integrations/events
```

The original Ruby replay script remains available at
`examples/integrations/project_4030_beef/replay_project_4030.rb`.

## Expected Outcome

The scenario should demonstrate:

- signed event acceptance
- duplicate-safe replay
- external identifier mapping
- append-only evidence projections
- receipt outbox creation
- asynchronous receipt issuance
- verification metadata
- outbound result-event readiness

## Inspect in Rails

Open:

```text
http://localhost:3000/integrations/events
http://localhost:3000/integrations/operations
http://localhost:3000/integrations/outbox
http://localhost:3000/integrations/deliveries
http://localhost:3000/integrations/dead-letter
```

## Failure Fixtures

Failure examples live under:

```text
examples/integrations/project_4030_beef/failures/
```

Use them to inspect invalid signatures, conflicting duplicates, missing
parents, invalid money representation, and webhook delivery failure.

## Authority Boundary

Project 4030 is a fixture. It does not claim production deployment, external
interoperability, customer use, regulatory approval, institutional reliance, or
recognized revenue.
