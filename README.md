# Athian Evidence Bazaar

Athian Evidence Bazaar is a demonstration workspace for an evidence-first agricultural carbon architecture.

It is not a carbon marketplace. It shows Athian as an evidence company: carbon assets are only the visible commercial object; the durable product is the portable, independently verifiable evidence rail underneath every environmental claim.

## What Is In This Repo

This repository contains three connected parts:

- `athian_ink_rails_bootstrap/`: a Rails 7.1 clickable demo that feels like GitHub for evidence.
- `services/agevidence-model/`: a fixture-first Python model-service scaffold for source-linked evidence candidates and gaps.
- `crates/`: a Rust BAINK workspace with receipt, bundle, canonicalization, crypto, verifier, schema, and CLI crates used as the trust-boundary substrate.

Rails presents workflow state and human review. The `ink_receipts` facade owns receipt-like operations and wraps the Rust CLI where available.

## Product Thesis

Evidence first. Carbon second.

Athian's strategic advantage is not simply issuing more agricultural carbon credits. It is making claims portable, inspectable, and reliable enough for buyers, registries, insurers, auditors, producers, and VVBs to use outside the originating application.

## Strategic Moves

| Demo Surface | Strategic Move |
|---|---|
| Bundle Builder | #1 Portable Proof Product |
| Co-Claim Workbench | #2 Standardize Co-Claim Geometry |
| VVB Console | #3 First-Class VVB |
| Producer Ledger | #4 Producer Economics |
| Methodology Migration | #5 Neutral Trust Waist |
| Evidence Marketplace | #6 Sell Evidence Acceptance |

## Demo Flow

The seeded Rails demo follows one AVSA through:

1. Practice implementation.
2. Evidence ingestion.
3. Model execution.
4. VVB review and attestation.
5. AVSA issuance.
6. Scope 3 claim and retirement.
7. Producer payment.
8. Evidence bundle download.
9. Offline verification path.
10. Methodology migration from VM0042 v2.2 to VM0042 v3.0.

## Receipt Chain

```text
Practice Receipt
  -> Measurement Receipt
  -> Model Execution Receipt
  -> Verifier Receipt
  -> Issuance Receipt
  -> Claim Receipt
  -> Producer Payment Receipt
```

Append-only receipts, such as contribution, retirement, verifier determination, and methodology delta receipts, are displayed outside the seven-node hero chain so history is never overwritten.

## Rails App

See [athian_ink_rails_bootstrap/README.md](athian_ink_rails_bootstrap/README.md) for the application-level README.

Key routes:

- `/`: Evidence Bazaar dashboard.
- `/evidence`: evidence explorer.
- `/avsas/:id`: AVSA receipt-chain hero.
- `/receipts/:id`: technical receipt viewer.
- `/bundle_exports`: bundle builder.
- `/verifier`: VVB console.
- `/producer_payments`: producer ledger.
- `/methodology_migrations`: methodology migration.
- `/marketplace`: evidence marketplace.
- `/agevidence`: funded-startup developer launchpad.
- `/agevidence/developer-os`: self-service Developer OS start page.
- `/agevidence/country_programs`: country adapter and method-compatibility projections.
- `/agevidence/revenue_model`: illustrative C-suite revenue scenario.
- `/v1/integrations/events`: append-only signed event intake for upstream Athian systems.
- `/v1/developer/projects`: source-record developer API.
- `/v1/pricing/products`: machine-readable artifact price book.
- `/v1/artifact-orders`: sandbox quote-to-order artifact flow.
- `/integrations/events`: internal inbox inspection, replay, outbox, delivery, and dead-letter views.

## Trust Boundary

Rails must not compute hashes, sign receipts, evaluate cryptographic validity, or assemble canonical bundles directly.

All trust-boundary operations go through:

```ruby
InkReceipts.issue(...)
InkReceipts.verify(...)
InkReceipts.bundle(...)
InkReceipts.attest(...)
InkReceipts.export(...)
InkReceipts.migrate(...)
InkReceipts.graph(...)
InkReceipts.verify_bundle(...)
```

The local Ruby facade lives at:

```text
athian_ink_rails_bootstrap/gems/ink_receipts
```

The Rust CLI lives at:

```text
target/debug/baink-cli
```

## Global AgEvidence

The repository also scaffolds a global thin-waist architecture:

```text
one global evidence graph
many versioned country determinations
many institution-specific reliance artifacts
```

Country methodology rules live in YAML adapter packs under `specs/agevidence/country_adapters`, while stable global vocabulary and receipt contracts live under `specs/agevidence`. Rails displays country programs as projections over the same objects; it does not fork the workflow by country.

## Integration Bridge

The append-only Evidence Event Inbox is documented under `docs/integrations`.
Its versioned contracts live under `specs/integrations`, and the synthetic
Project 4030 scenario lives under `examples/integrations/project_4030_beef`.

The bridge is intentionally one-way for operational data: existing Athian
systems publish signed events; Rails preserves them, maps external identifiers,
creates evidence projections, and writes receipt requests through
`ReceiptOutbox`.

The Australian executive GTM backlog is documented in
`docs/strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md`.

## Developer OS

AgEvidence is now scaffolded as a developer operating system, not only an
enterprise implementation practice. A startup can enter through either:

- signed operational events into `/v1/integrations/events`; or
- controlled source references into `/v1/developer/projects/:id/source_records`.

Both paths produce Rails evidence projections and async receipt requests while
the original operating platform or source owner remains authoritative. Fixture
model runs create review-required candidates and gaps, human decisions are
append-only, sandbox quotes preserve versioned pricing inputs, and artifact
orders expose metadata plus a local verification command.

Developer-facing contracts and examples:

- OpenAPI: `docs/openapi/agevidence.v1.yaml`
- Python SDK example: `examples/sdk/python/agevidence_client.py`
- TypeScript SDK example: `examples/sdk/typescript/agevidenceClient.ts`
- Project 4030 replay script:
  `examples/integrations/project_4030_beef/replay_project_4030.rb`

## Self-Service Guides

Customer, startup developer, and API user guides live at
`docs/self-service/README.md`. They provide no-meeting-required quickstarts for
the source-record path, signed Evidence Event Inbox path, Project 4030 replay,
SDK examples, sandbox quote/order flow, webhook callbacks, and local
verification.

The guides are external-safe. Sandbox prices and orders are planning records,
not booked, collected, or recognized revenue, and model output is candidate
evidence only.

## Internal Orientation

New Athian stakeholders should start with the role-based internal orientation
pack at `docs/internal/README.md`. It routes executives, GTM/product,
engineering, Rails, integrations, trust-layer, model-service, country-policy,
and operations readers to the right first document without replacing the
canonical implementation specs.

## Validation

Rust:

```bash
cargo test --workspace
cargo build -p baink-cli
```

Python model service:

```bash
cd services/agevidence-model
python3 -m pytest
```

Rails, after installing Ruby 3.3.8 and Node/npm:

```bash
cd athian_ink_rails_bootstrap
bin/setup
bin/rails db:migrate db:seed
bin/rails test
npm run build
bin/dev
```

Boundary check:

```bash
cd athian_ink_rails_bootstrap
rg -n "\\bDigest\\b|\\bOpenSSL\\b|crypto\\.subtle\\.digest|SHA256|SHA-256" app db
```

That grep should return no matches.
