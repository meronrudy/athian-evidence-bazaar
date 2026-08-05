# Developer Quickstart

This quickstart is for a developer running the AgEvidence scaffold locally.

## Outcome

You will start the Rails app, open the Developer OS, submit a source record,
run fixture-backed extraction, and create a sandbox artifact path.

Sandbox quote and order values are illustrative planning records, not booked,
collected, or recognized revenue.

## Local Setup

From the repository root:

```bash
cargo test --workspace
```

For the model service:

```bash
cd services/agevidence-model
python3 -m pytest
```

For Rails:

```bash
cd athian_ink_rails_bootstrap
bin/setup
bin/rails db:migrate db:seed
bin/dev
```

Rails validation currently requires Ruby 3.3.8 and Node/npm.

## Browser Path

Open:

```text
http://localhost:3000/agevidence/developer-os
```

Use the Source Records path first. It is the shortest path for a startup that
does not yet have a signed operational event stream.

## API Path

The API contract is:

```text
docs/openapi/agevidence.v1.yaml
```

Install the canonical Python SDK and CLI:

```bash
python3 -m pip install -e "sdks/python[test]"
agevidence --help
```

Core flow:

```text
POST /v1/developer/projects
POST /v1/developer/projects/:project_id/source_records
POST /v1/developer/projects/:project_id/model_runs
PATCH /v1/developer/candidates/:id
POST /v1/pricing/quotes
POST /v1/artifact-orders
POST /v1/artifact-orders/:id/checkout
POST /v1/developer/projects/:project_id/artifacts
```

The API is scaffolded for sandbox use. Production authentication, tenancy,
rate limits, billing, and hardened signing remain backlog items.

## Event Inbox Path

If you want to test the current-business bridge, replay Project 4030:

```bash
agevidence replay project-4030
```

The CLI signs the fixture events and posts them to `/v1/integrations/events`.
The older Ruby replay script remains available in
`examples/integrations/project_4030_beef`.

## Trust Boundary

Rails is not the cryptographic authority. Receipt-like operations go through
`ink_receipts` and the Rust trust boundary. Rails app code must not compute
receipt commitments, sign receipts, or verify bundles directly.

## Next Guides

- [API User Guide](API_USER_GUIDE.md)
- [Source Record API Flow](examples/source-record-api-flow.md)
- [Project 4030 Event Flow](examples/project-4030-event-flow.md)
