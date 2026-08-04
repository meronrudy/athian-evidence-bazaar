# Athian Evidence Bazaar

Athian Evidence Bazaar is a Rails demonstration app for an evidence-first agricultural carbon platform.

The objective is not to model a carbon marketplace. The objective is to show Athian as an evidence company: carbon assets are valuable because they are backed by portable, independently verifiable receipt rails.

The app is designed to feel like GitHub for evidence. A reviewer can inspect an AVSA receipt chain, open committed evidence, verify a receipt locally, assemble institutional evidence bundles, review VVB attestations, trace producer economics, and append methodology migrations without rewriting history.

## Core Thesis

Evidence first. Carbon second.

Athian's durable differentiator is not producing more credits than competitors. It is making environmental claims reviewable, portable, and institutionally reliable.

Rails presents workflow state, review queues, and human-readable projections. Rails does not perform cryptography. Canonical encoding, commitments, signing, verification, trust policy, bundle generation, migration receipts, graph export, and local verification belong behind the `ink_receipts` trust boundary.

```text
Rails demo
  dashboard
  AgEvidence launchpad
  country programs
  AVSA chain
  evidence explorer
  receipt viewer
  bundle builder
  VVB console
  producer ledger
  co-claim workbench
  methodology migration
  evidence marketplace
    |
    v
ink_receipts facade
    |
    v
Rust BAINK kernel and CLI
```

The global AgEvidence scaffold keeps the same architecture for international expansion:

```text
one global evidence graph
  -> many versioned country compatibility determinations
  -> many profile-driven reliance artifacts
```

Country rules live in declarative adapter packs under `../specs/agevidence/country_adapters`. Rails displays them as projections and never branches the workflow by country.

## Strategic Moves

| Rails Surface | Strategic Move |
|---|---|
| Bundle Builder | #1 Portable Proof Product |
| Co-Claim Workbench | #2 Standardize Co-Claim Geometry |
| VVB Console | #3 First-Class VVB |
| Producer Ledger | #4 Producer Economics |
| Methodology Migration | #5 Neutral Trust Waist |
| Evidence Marketplace | #6 Sell Evidence Acceptance |

This mapping is visible in the dashboard and shared navigation so the demo keeps the strategy attached to the product surface.

## Demo Story

The seeded flow follows one AVSA from practice implementation through institutional reliance:

1. A producer implements a methane-reduction intervention.
2. Evidence is ingested and committed.
3. A model execution quantifies reductions.
4. A VVB reviews evidence, exceptions, and materiality.
5. An AVSA is issued with a visible receipt chain.
6. A buyer retires the asset for a Scope 3 claim.
7. Producer payment is calculated and linked backward to the chain.
8. A Buyer Evidence Bundle is generated and downloaded.
9. The bundle can be verified offline through the local verifier path.
10. A VM0042 v2.2 to VM0042 v3.0 methodology update appends a delta receipt without altering the original chain.

## Receipt Chain

The AVSA hero page displays the canonical seven-node chain:

```text
Practice Receipt
  -> Measurement Receipt
  -> Model Execution Receipt
  -> Verifier Receipt
  -> Issuance Receipt
  -> Claim Receipt
  -> Producer Payment Receipt
```

Each node exposes:

- verification status
- canonical receipt view
- receipt download
- local verification action

Append-only receipts, such as contribution, retirement, VVB attestation, and methodology delta receipts, are shown separately so the original chain remains intact.

## Application Surfaces

| Route | Surface | Purpose |
|---|---|---|
| `/` | Dashboard | Evidence-first operating queues, recent AVSAs, receipts, bundles, failures, VVB work, payments, and migration alerts |
| `/evidence` | Evidence Explorer | GitHub-tree style evidence browser with receipt, hash, signer, parents, lifecycle, and verify actions |
| `/avsas/:id` | AVSA Receipt Chain | Seven-node receipt-chain hero with timeline, evidence, claims, payments, and bundle sections |
| `/receipts/:id` | Receipt Detail | Technical receipt viewer for schema, version, lifecycle, issuer, signer, parent hashes, canonical encoding, public key, and trust policy |
| `/bundle_exports` | Bundle Builder | Choose AVSA, choose bundle, generate, and download ZIP |
| `/avsas/:avsa_id/co_claim_group` | Co-Claim Workbench | 100 percent allocation geometry, duplicate-claimant checks, retirement validity, and exclusivity validity |
| `/verifier` | VVB Console | Review evidence, exceptions, materiality, and append a Verifier Determination Receipt |
| `/producer_payments` | Producer Ledger | Trace Receipt to Credit to Claim to Revenue to Fees to Net to ACH |
| `/methodology_migrations` | Methodology Migration | Append Methodology Delta Receipts for VM0042 v2.2 to v3.0 |
| `/marketplace` | Evidence Marketplace | Sell evidence acceptance products, not carbon |
| `/agevidence` | Developer Launchpad | Funded-startup projects, model runs, candidate review, artifacts, reliance events, and revenue projections |
| `/agevidence/developer_projects/:id` | Project Evidence Map | Global source records to candidates, reviews, receipts, country determinations, artifacts, and reliance |
| `/agevidence/country_programs` | Country Programs | Shared country adapter projections for method compatibility without country-specific Rails branches |
| `/agevidence/revenue_model` | Revenue Model | Conservative, base, and upside projections labeled as management hypotheses |

## Evidence Products

The marketplace presents evidence products for institutional reliance:

- Buyer Evidence Bundle
- Scope 3 Bundle
- Registry Bundle
- Insurance Bundle
- Due Diligence Bundle
- Financing Bundle
- Dispute Bundle

Each product page shows the problem, included receipts, verification command, and download path through the Bundle Builder.

## AgEvidence Global Surfaces

The AgEvidence extension demonstrates a funded-startup SDK and commercial artifact path:

- Northstar Methane Systems, a synthetic Series A startup, is seeded as the developer account.
- The Qwen3.5 reference adapter is represented as a registry entry, not as an approving authority.
- Fixture model runs produce source-linked candidates and material gaps.
- Human review decisions are append-only.
- Country compatibility determinations are plural and append-only.
- Canada and Australia adapter packs are starter examples; Japan, New Zealand, Ireland/EU, and Brazil are schema-valid placeholders.
- Premium artifacts bind to country adapter, claim policy, verification profile, data policy, determination receipt, and artifact profile when available.

The UI separates cryptographic validity, method compatibility, and institutional reliance. One state must never be displayed as a substitute for another.

## Trust Boundary

The Rails app depends on the local `ink_receipts` gem:

```ruby
InkReceipts.issue(...)
InkReceipts.verify(...)
InkReceipts.bundle(...)
InkReceipts.attest(...)
InkReceipts.export(...)
InkReceipts.migrate(...)
InkReceipts.graph(...)
InkReceipts.verify_bundle(...)
InkReceipts.issue_model_execution(...)
InkReceipts.issue_evidence_candidate(...)
InkReceipts.issue_review_decision(...)
InkReceipts.build_reliance_artifact(...)
InkReceipts.issue_reliance_event(...)
InkReceipts.issue_country_adapter_commitment(...)
InkReceipts.issue_country_determination(...)
```

The facade wraps the Rust `baink-cli` executable when configured:

```bash
INK_RECEIPTS_COMMAND=/absolute/path/to/baink-cli
```

If no CLI is configured, the facade emits deterministic demo projections from inside the gem. That keeps all receipt-like behavior behind the same application boundary during the bootstrap.

## Stack

- Ruby 3.3.8
- Rails 7.1
- SQLite
- Bootstrap 5.3
- Turbo and Stimulus
- `rubyzip`
- local `ink_receipts` path gem
- Rust BAINK workspace for receipt, bundle, verifier, canonical, crypto, schema, and CLI crates

## Local Setup

```bash
cp .env.example .env
bin/setup
bin/rails db:migrate db:seed
bin/dev
```

Open:

```text
http://localhost:3000
```

Optional facade configuration:

```bash
INK_RECEIPTS_COMMAND=/Users/mini/BAINK\ copy\ 2/target/debug/baink-cli
```

## Validation

Rails validation:

```bash
bin/rails test
npm run build
```

Rust validation from the parent workspace:

```bash
cargo test --workspace
cargo build -p baink-cli
```

Static boundary check:

```bash
rg -n "\\bDigest\\b|\\bOpenSSL\\b|crypto\\.subtle\\.digest|SHA256|SHA-256" app db
```

That grep should return no matches. Direct cryptography belongs in `ink_receipts` and the Rust kernel, not Rails.

Country-rule boundary check:

```bash
rg -n "CA-FED|J-Credit|canada_federal|j_credit|brazil_car|eu_crcf" app/controllers app/views
```

That grep should return no matches. National methodology details belong in adapter-pack YAML, not controllers or templates.

## Current Environment Note

In the current workspace, Rust validation passes. Rails runtime validation requires Ruby 3.3.8 under rbenv and Node/npm on PATH.

## Production Gaps

- Replace demo projection receipts with released production receipt schemas.
- Replace lightweight `baink-agevidence` structural checks with JSON-schema-backed validation.
- Implement country adapter schema validation beyond the current Rails manifest guard.
- Implement model-service local and remote transports behind the fixture-first contract.
- Bind `ink_receipts` to the released Rust verifier, trust registry, public keys, and revocation snapshots.
- Add authentication, tenant isolation, and role-specific authorization.
- Move source evidence into governed object storage with retention and selective disclosure.
- Add HSM/KMS-backed signing and key rotation.
- Add immutable audit logging for production workflow events.
- Review agricultural, VVB, buyer, legal, security, and producer requirements before external reliance.
