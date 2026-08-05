# Operations Orientation

## Purpose

Operations for this repository are about making the scaffold reproducible,
inspectable, and safe to diagnose. The first production objective is not to
migrate Athian systems into Rails. It is to prove that one existing project can
emit a bounded sequence of signed events and receive a portable artifact result.

## Local Setup

Expected validation stack:

- Rust toolchain for `cargo test --workspace`;
- Python 3 for the model-service tests;
- Ruby 3.3.8 for Rails;
- Node/npm for frontend build.

Local commands:

```bash
cargo test --workspace
cd services/agevidence-model && python3 -m pytest
cd athian_ink_rails_bootstrap && bin/rails db:migrate db:seed test
cd athian_ink_rails_bootstrap && npm run build
```

Known workstation blocker from recent validation: Rails runtime tests require
Ruby 3.3.8 and Node/npm on PATH. Do not claim Rails CI passed unless those tests
actually run successfully.

## Replay and Debug Workflow

Project 4030 replay:

```bash
ruby examples/integrations/project_4030_beef/replay_project_4030.rb \
  http://localhost:3000 athian_salesforce_production "$ATHIAN_INTEGRATION_SECRET"
```

Inspect results in Rails:

- `/integrations/events`
- `/integrations/operations`
- `/integrations/outbox`
- `/integrations/deliveries`
- `/integrations/dead-letter`

Use event ID, operation ID, source key, payload commitment, and processing state
as the core diagnostic fields. Do not log secrets, full source documents,
presigned URLs, access tokens, or producer banking details.

## Validation Matrix

Always record which checks ran:

- Rust workspace tests;
- Python model-service tests;
- Rails tests;
- frontend build;
- docs link or anchor checks;
- boundary grep;
- OpenAPI/YAML parse;
- JSON fixture parse.

Boundary grep:

```bash
rg -n "\bDigest\b|\bOpenSSL\b|crypto\.subtle\.digest|SHA256|SHA-256" \
  athian_ink_rails_bootstrap/app \
  athian_ink_rails_bootstrap/db
```

This should return no matches.

## Webhook Retry Concepts

Implemented scaffold:

- outbound result events for artifact and reliance states;
- endpoint registration under the integration API;
- delivery records with attempt counts and response excerpts;
- dead-letter inspection surfaces.

Production operations must add:

- signed outbound payload validation by consumers;
- retry backoff policy verification;
- endpoint disabling thresholds;
- replay audit reasons;
- alerting on delivery failures and backlog growth.

## Dead-Letter Handling

Dead-letter state means the preserved record could not complete after the
configured attempts or failure policy. Operators should:

1. inspect raw and canonical payloads;
2. verify source, signature, schema, and processing error;
3. inspect external mappings and parent projection availability;
4. check receipt outbox and verifier state;
5. replay only when the preserved original event is eligible;
6. document the replay reason.

Never edit the original event payload.

## Implemented Scaffold

- Event inbox admin pages exist.
- Receipt outbox admin pages exist.
- Delivery and dead-letter inspection pages exist.
- Project 4030 fixtures and replay helper exist.
- Seeds create a synthetic Northstar story, source records, model run, review
  decisions, country determinations, artifact engagements, quote, and order.

## Demo-Only Behavior

- SQLite is used in local scaffold configuration.
- Background job durability is not production-hardened.
- Artifact download URLs are scaffold metadata.
- Sandbox checkout is not payment.
- Webhook delivery has not been proven against a real upstream platform.

## Production-Hardening Backlog

- PostgreSQL production configuration;
- durable queue backend;
- object storage and signed download URLs;
- secret manager integration;
- source credential rotation;
- structured logging and metrics;
- alerting for signature failures, backlog, dead letters, verifier failures, and
  webhook outages;
- backup and recovery procedures;
- deployment runbook and clean-machine demonstration.

## Non-Goals

- no Kafka or generic service bus for the first bridge;
- no direct Salesforce table polling;
- no bidirectional CRUD sync;
- no production customer payloads in demo fixtures;
- no recognized revenue claims from sandbox orders.

## Read Next

- [Integration Overview](../integrations/overview.md)
- [Project 4030 Example](../integrations/project-4030-example.md)
- [Scaffold Handoff](../implementation/AGEVIDENCE_SCAFFOLD_HANDOFF.md)
