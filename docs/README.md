# AgEvidence Documentation

This directory is the review index for the current repository. It describes a
local-first AgEvidence SDK, a Rails workflow/control-plane scaffold, a Rust
trust boundary, public specifications, integration contracts, and release
evidence.

The repository should not be read as proof of customer adoption, production
security, regulatory acceptance, verified climate impact, booked revenue, or a
production marketplace. Historical planning documents are retained where useful,
but current capability claims should point to code, specifications, tests, or
release artifacts.

## Current Architecture

| Area | Start here | Current role |
| --- | --- | --- |
| Repository overview | [Root README](../README.md) | Screening-branch thesis, maturity map, local inspection commands, and diligence gaps |
| Python SDK | [SDK docs](../sdks/python/docs/index.md) | Local package `agevidence==1.0.0`, CLI, primitives, local fixtures, source adapters, provenance checks, and optional hosted client |
| Rails control plane | [Rails README](../athian_ink_rails_bootstrap/README.md) | Demonstration workflow surface for evidence intake, projections, review, artifacts, and integration inboxes |
| Rust trust boundary | [Rust AgEvidence crate](../crates/baink-agevidence/README.md) | Local validation and verifier-adjacent behavior that remains outside Rails workflow authority |
| Public specs | [AgEvidence specs](../specs/agevidence/examples/README.md) | Schemas, examples, country adapters, bundle profiles, trust policies, and conformance fixtures |
| Integration contracts | [Integrations overview](integrations/overview.md) | Signed event envelope, idempotency, replay, webhook, authentication, and Project 4030 example contracts |
| Release evidence | [v1 release notes](releases/v1.0.0/RELEASE_NOTES.md) | SDK v1.0.0 release scope, limitations, checks, and recorded artifact hashes |

## Local SDK

The Python SDK is the current developer-facing local interface. It supports:

- typed evidence primitives and packaged schemas;
- no-account local demos and fixtures;
- source-adapter testing;
- provenance explanation;
- CI helper APIs; and
- optional hosted `/v1` Rails client calls.

See:

- [SDK index](../sdks/python/docs/index.md)
- [Quickstart](../sdks/python/docs/quickstart.md)
- [Python API](../sdks/python/docs/reference/python-api.md)
- [CLI reference](../sdks/python/docs/reference/cli.md)
- [Release process](../sdks/python/RELEASING.md)

The SDK does not issue receipts, perform scientific validation, decide
regulatory eligibility, create carbon credits, replace third-party verification,
or establish institutional reliance.

## Rails Control Plane

The Rails app is a scaffold for workflow, review, projection, and commercial
planning surfaces. It is intentionally not the cryptographic trust boundary and
does not become the producer, protocol, asset, marketplace, ledger, claim-right,
or payment system of record.

See:

- [Rails README](../athian_ink_rails_bootstrap/README.md)
- [Rails implementation map](../athian_ink_rails_bootstrap/docs/implementation-map.md)
- [Commercial order lifecycle](../athian_ink_rails_bootstrap/docs/architecture/COMMERCIAL_ORDER_LIFECYCLE.md)
- [Build validation note](../athian_ink_rails_bootstrap/docs/build-validation.md)
- [Verifier adapter contract](../athian_ink_rails_bootstrap/docs/verifier-adapter-contract.md)

## Rust Trust Boundary

The Rust workspace owns canonicalization, bundle/verifier-adjacent behavior, and
portable local verification paths. Rails may display verification status or call
the `ink_receipts` facade, but cryptographic authority remains below that
boundary.

See:

- [Model authority boundary](implementation/MODEL_AUTHORITY_BOUNDARY.md)
- [Rails/Rust trust boundary ADR](adr/0004-rails-rust-trust-boundary.md)
- [SDK API boundary ADR](adr/0001-sdk-api-boundary.md)
- [Rust AgEvidence crate](../crates/baink-agevidence/README.md)

## Specifications

Specification files define the shared evidence grammar. Runtime implementations
should conform to these contracts rather than redefining them in controllers,
templates, prompts, or client libraries.

See:

- [Integration specs](../specs/integrations/README.md)
- [Country adapters](../specs/agevidence/country_adapters/README.md)
- [Bundle profiles](../specs/agevidence/bundle_profiles/README.md)
- [Trust policies](../specs/agevidence/trust_policies/README.md)
- [OAEP standards draft](../standards/oaep/README.md)

## Integrations

Integration documentation covers signed inbound events, idempotent processing,
replay, outbound webhooks, authentication, and error handling.

See:

- [Overview](integrations/overview.md)
- [Event envelope](integrations/event-envelope.md)
- [Event types](integrations/event-types.md)
- [Authentication](integrations/authentication.md)
- [Signatures](integrations/signatures.md)
- [Idempotency](integrations/idempotency.md)
- [Replay](integrations/replay.md)
- [Webhooks](integrations/webhooks.md)
- [Project 4030 example](integrations/project-4030-example.md)

## Self-Service Docs

The self-service docs describe the developer and customer-facing flow around
source records, event inboxes, local verification, country adapters, model
review, and artifact orders.

See:

- [Self-service index](self-service/README.md)
- [Developer quickstart](self-service/DEVELOPER_QUICKSTART.md)
- [API user guide](self-service/API_USER_GUIDE.md)
- [Source records guide](self-service/SOURCE_RECORDS_GUIDE.md)
- [Event inbox guide](self-service/EVENT_INBOX_GUIDE.md)
- [Local verification guide](self-service/LOCAL_VERIFICATION_GUIDE.md)
- [Pricing, orders, and artifacts guide](self-service/PRICING_ORDERS_ARTIFACTS_GUIDE.md)
- [Troubleshooting](self-service/TROUBLESHOOTING.md)

## Strategy And Historical Context

Strategy and roadmap files are useful for understanding intent, but they are
not current capability inventories unless they explicitly say so. Historical
release records preserve prior baseline facts and deferred work for audit
context.

See:

- [Internal docs index](internal/README.md)
- [Australian GTM backlog](strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md)
- [Developer GTM implementation specification](implementation/AGEVIDENCE_DEVELOPER_GTM.md)
- [SDK v1 implementation plan](../sdks/python/docs/roadmap/pypi-v1-implementation-plan.md)
- [v0.1.0 historical release records](releases/v0.1.0-tenacious-screening/SCOPE.md)
- [v1.0.0 release notes](releases/v1.0.0/RELEASE_NOTES.md)
