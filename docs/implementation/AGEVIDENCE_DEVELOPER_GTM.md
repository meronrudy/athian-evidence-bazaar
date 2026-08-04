# AgEvidence Developer GTM Implementation Specification

## 1. Objective

Extend `meronrudy/athian-evidence-bazaar` to demonstrate **Athian AgEvidence**:

> An open, model-neutral agricultural evidence SDK that funded agriculture startups can integrate into their products, with Qwen3.5 as the first reference adapter and premium evidence artifacts as the commercial layer.

The completed repository must demonstrate this sequence:

```text
Funded agriculture startup
        ↓
Open AgEvidence SDK
        ↓
Qwen3.5 or interchangeable model adapter
        ↓
Source-linked evidence candidates
        ↓
Model Execution Receipt
        ↓
Human scientific / protocol review
        ↓
INK-signed evidence graph
        ↓
Premium evidence artifact
        ↓
Protocol, VVB, buyer, auditor, sponsor, or insurer reliance
```

The model must never be represented as an approving authority. It extracts, classifies, maps, and identifies evidence gaps. Athian protocol governance, scientific reviewers, VVBs, buyers, and other relying institutions retain their existing authority.

---

## 2. Preserve the Existing Architecture

Do not replace or duplicate these existing layers:

```text
athian_ink_rails_bootstrap/
    Rails workflow, user experience, review, commercial surfaces

athian_ink_rails_bootstrap/gems/ink_receipts/
    Ruby facade for receipt issuance, verification, bundles,
    attestations, graph export, and migrations

crates/
    Rust receipt, canonicalization, crypto, schema,
    bundle, verifier, and CLI implementation
```

The current Rails app already exposes dashboard, evidence explorer, AVSA, receipt, verifier, producer-payment, methodology-migration, marketplace, and bundle-export routes. Extend those surfaces rather than rebuilding them.

The existing seed already models:

* `Protocol`
* `Avsa`
* `Receipt`
* `EvidenceItem`
* `VerificationRun`
* `VerificationException`
* `EvidenceBundle`
* `MethodologyMigration`
* `ClaimGroup`
* `ClaimShare`
* `ProducerPayment`

It also includes a `model_execution_receipt` in the canonical AVSA chain. Reuse those objects wherever they remain semantically correct.

---

## 3. Target Repository Structure

Add the following structure without moving the current Rails app or Rust workspace:

```text
athian-evidence-bazaar/
├── Cargo.toml
├── crates/
│   ├── baink-core/
│   ├── baink-schema/
│   ├── baink-canonical/
│   ├── baink-crypto/
│   ├── baink-bundle/
│   ├── baink-verify/
│   ├── baink-cli/
│   └── baink-agevidence/                 # new domain adapter crate
│
├── services/
│   └── agevidence-model/                 # new model runtime
│       ├── pyproject.toml
│       ├── README.md
│       ├── src/athian_agevidence/
│       │   ├── __init__.py
│       │   ├── api.py
│       │   ├── contracts.py
│       │   ├── normalization.py
│       │   ├── source_references.py
│       │   ├── gap_detection.py
│       │   ├── adapters/
│       │   │   ├── base.py
│       │   │   ├── fixture.py
│       │   │   ├── openai_compatible.py
│       │   │   └── qwen35.py
│       │   └── prompts/
│       │       ├── evidence_extraction.txt
│       │       ├── protocol_mapping.txt
│       │       └── gap_assessment.txt
│       └── tests/
│
├── specs/
│   └── agevidence/
│       ├── schemas/
│       ├── bundle_profiles/
│       ├── trust_policies/
│       ├── examples/
│       └── evaluations/
│
├── examples/
│   └── funded_startup/
│       ├── source_documents/
│       ├── expected_candidates.json
│       ├── expected_gaps.json
│       └── README.md
│
├── docs/
│   ├── strategy/
│   │   └── ATHIAN_AGEVIDENCE_CSUITE_PROPOSAL.md
│   └── implementation/
│       ├── AGEVIDENCE_DEVELOPER_GTM.md
│       ├── MODEL_AUTHORITY_BOUNDARY.md
│       └── PREMIUM_ARTIFACT_CATALOG.md
│
└── athian_ink_rails_bootstrap/
    ├── app/
    ├── config/
    ├── db/
    ├── gems/ink_receipts/
    └── test/
```

Add `crates/baink-agevidence` to the existing Cargo workspace. Do not place Qwen, Python, HTTP, or inference dependencies inside the Rust trust kernel. The current workspace already separates core, schema, canonicalization, crypto, bundle, verification, and CLI responsibilities.

---

## 4. Architectural Responsibilities

### Rails

Rails may:

* Register developer organizations and projects.
* Upload or reference source records.
* Start a model run.
* Display evidence candidates and gaps.
* Record human review decisions.
* Present premium product and pricing hypotheses.
* Request receipt issuance through `InkReceipts`.
* Assemble commercial workflows around evidence bundles.
* Record external reliance events.
* Display revenue scenarios.

Rails must not:

* Calculate receipt hashes.
* Sign receipts.
* treat model output as approved evidence.
* silently convert confidence into scientific validity.
* overwrite historical model runs or review decisions.
* generate canonical receipt bytes.
* perform cryptographic bundle verification.

### Python model service

The model service may:

* Run Qwen3.5 or another configured model.
* Extract candidate assertions.
* link assertions to source locations.
* classify observations, calculations, assumptions, and judgments.
* identify missing or contradictory evidence.
* map content into proposed receipt fields.
* produce a normalized JSON response.

It must not:

* Sign receipts.
* approve protocols.
* issue AVSAs.
* make final VVB determinations.
* determine legal rights.
* certify emissions reductions.
* write directly to the Rails database.

### Rust and `ink_receipts`

The trust layer must:

* Validate normalized AgEvidence payloads.
* Commit to the exact model, adapter, prompt, inputs, output, and policy.
* Issue Model Execution Receipts.
* issue human-review and acceptance receipts.
* validate parent relationships.
* build portable artifact bundles.
* produce `valid`, `invalid`, or `indeterminate` results.

The existing Rust schema already supports a generic `ModelRef`; extend domain payload validation without turning the generic kernel into a Qwen-specific system.

---

## 5. Rails Domain Model

Create namespaced models under:

```text
athian_ink_rails_bootstrap/app/models/agevidence/
```

### `Agevidence::DeveloperAccount`

Represents a funded agriculture startup.

Fields:

```text
name
website
funding_stage
capital_raised_cents
primary_segment
headquarters
status
```

### `Agevidence::DeveloperProject`

Represents an intervention, measurement product, or data product.

Fields and associations:

```text
belongs_to :developer_account
belongs_to :protocol, optional: true
belongs_to :avsa, optional: true

name
project_type
commercialization_stage
target_claim
protocol_status
integration_status
```

### `Agevidence::ModelAdapter`

A registry entry, not model weights.

```text
adapter_id
base_model_id
provider
license
runtime
weights_digest
adapter_digest
context_limit
multimodal
status
```

Seed:

```text
adapter_id: qwen3.5-4b-reference
base_model_id: Qwen/Qwen3.5-4B
status: reference
```

Do not imply sponsorship or endorsement.

### `Agevidence::ModelRun`

```text
belongs_to :developer_project
belongs_to :model_adapter
belongs_to :receipt, optional: true

task
status
prompt_digest
retrieval_digest
input_manifest
normalized_output
output_digest
runtime_metadata
started_at
completed_at
failure_reason
```

Statuses:

```text
queued
running
completed
failed
receipt_issued
superseded
```

### `Agevidence::EvidenceCandidate`

```text
belongs_to :model_run
belongs_to :evidence_item, optional: true

candidate_type
claim_text
source_references
model_confidence
review_status
review_notes
reviewed_by
reviewed_at
```

Review statuses:

```text
review_required
accepted
rejected
needs_more_evidence
superseded
```

### `Agevidence::EvidenceGap`

```text
belongs_to :model_run

gap_type
requirement
description
severity
source_context
resolution_status
```

### `Agevidence::ReviewDecision`

Append-only human decision record:

```text
belongs_to :evidence_candidate
belongs_to :receipt, optional: true

reviewer_role
decision
reason
policy_version
decided_at
```

Never update a previous decision in place. Supersede it with another decision.

### `Agevidence::ArtifactEngagement`

Commercial engagement surrounding an artifact:

```text
belongs_to :developer_project
belongs_to :evidence_bundle, optional: true

product_code
pipeline_stage
billing_type
list_price_cents
quoted_price_cents
currency
commercial_status
started_on
completed_on
```

### `Agevidence::RelianceEvent`

The north-star commercial object:

```text
belongs_to :artifact_engagement
belongs_to :evidence_bundle

relying_party_name
relying_party_role
decision_type
outcome
evidence_bundle_digest
occurred_at
notes
```

A generated bundle is not proof of commercial value. A recorded external reliance event is.

---

## 6. Reuse Existing Models

Do not create replacements for:

* `Protocol`
* `Avsa`
* `Receipt`
* `EvidenceItem`
* `EvidenceBundle`
* `VerificationRun`
* `VerificationException`
* `MethodologyMigration`

Extend `EvidenceBundle` with:

```text
commercial_product_code
artifact_version
reliance_status
relying_party_count
list_price_cents
quoted_price_cents
acceptance_receipt_id
accepted_at
```

Extend the existing marketplace and bundle definitions rather than creating a disconnected second catalog. The local gem already contains buyer, registry, insurer, Scope 3, producer, auditor, financing, due-diligence, and dispute bundle concepts.

---

## 7. Model-Service Contract

Expose an internal endpoint:

```text
POST /v1/evidence-runs
```

Request:

```json
{
  "adapter_id": "qwen3.5-4b-reference",
  "task": "protocol_evidence_extraction",
  "project": {
    "id": "project-001",
    "claim": "The intervention reduces enteric methane."
  },
  "protocol": {
    "code": "ATH-LI-CH4",
    "version": "v1"
  },
  "documents": [
    {
      "document_id": "trial-report-001",
      "commitment": "sha256:...",
      "controlled_uri": "evidence://trial-report-001"
    }
  ],
  "generation": {
    "temperature": 0,
    "seed": 42
  }
}
```

Response:

```json
{
  "model_run": {
    "adapter_id": "qwen3.5-4b-reference",
    "base_model_id": "Qwen/Qwen3.5-4B",
    "weights_digest": "sha256:...",
    "adapter_digest": "sha256:...",
    "prompt_digest": "sha256:...",
    "retrieval_digest": "sha256:...",
    "runtime": "vllm",
    "started_at": "...",
    "completed_at": "..."
  },
  "candidates": [
    {
      "candidate_id": "candidate-001",
      "candidate_type": "observation",
      "claim_text": "The product was delivered on the stated date.",
      "source_references": [
        {
          "document_id": "invoice-001",
          "locator": "page:1"
        }
      ],
      "confidence": 0.94,
      "status": "review_required"
    }
  ],
  "gaps": [
    {
      "gap_type": "missing_independent_support",
      "requirement": "Dosage confirmation",
      "severity": "material",
      "description": "Dosage appears in the trial narrative but lacks telemetry or ration-log support."
    }
  ],
  "limitations": [
    "Model output is an evidence candidate and not a scientific or verification determination."
  ]
}
```

Record the normalized response exactly before issuing its receipt.

Do not claim model execution itself is deterministic. The deterministic property is:

> Identical normalized model-run records produce identical canonical receipt commitments.

---

## 8. Receipt Schemas

Add versioned schemas under:

```text
specs/agevidence/schemas/
```

Required initial schemas:

```text
athian.agevidence.model_execution.v1.json
athian.agevidence.evidence_candidate.v1.json
athian.agevidence.evidence_gap.v1.json
athian.agevidence.human_review.v1.json
athian.agevidence.artifact_assembly.v1.json
athian.agevidence.reliance_event.v1.json
```

### Model Execution Receipt

Commit to:

* Base-model identifier
* Weight digest
* Adapter identifier and digest
* Model license declaration
* Runtime
* generation configuration
* system-prompt digest
* retrieval-corpus digest
* source-document commitments
* normalized-output digest
* policy version
* parent receipts
* limitations
* execution timestamp
* issuer and signer

### Human Review Receipt

Commit to:

* Candidate receipt
* Reviewer role
* decision
* reason
* protocol and policy version
* unresolved gaps
* timestamp
* signer

### Reliance Event Receipt

Commit to:

* Artifact digest
* relying institution
* decision type
* outcome
* declared scope
* limitations
* timestamp

---

## 9. Extend `ink_receipts`

Split the current large facade into focused files:

```text
gems/ink_receipts/lib/ink_receipts/
├── client.rb
├── catalog.rb
├── model_execution.rb
├── evidence_candidates.rb
├── review_decisions.rb
├── reliance_artifacts.rb
├── bundle_profiles.rb
└── revenue_catalog.rb
```

Expose:

```ruby
InkReceipts.issue_model_execution(...)
InkReceipts.issue_evidence_candidate(...)
InkReceipts.issue_review_decision(...)
InkReceipts.build_reliance_artifact(...)
InkReceipts.issue_reliance_event(...)
```

Continue supporting the current public methods:

```ruby
InkReceipts.issue
InkReceipts.verify
InkReceipts.bundle
InkReceipts.attest
InkReceipts.export
InkReceipts.migrate
InkReceipts.graph
InkReceipts.verify_bundle
```

Do not break the existing AVSA demonstration.

---

## 10. Rails Routes and Product Surfaces

Add:

```ruby
namespace :agevidence do
  root "overview#show"

  resources :developer_accounts
  resources :developer_projects do
    resources :model_runs, only: %i[new create]
    resources :artifact_engagements, only: %i[index new create show]
  end

  resources :model_runs, only: :show do
    member do
      post :issue_receipt
    end
  end

  resources :evidence_candidates, only: %i[show update]
  resources :evidence_gaps, only: %i[show update]
  resources :review_decisions, only: :create
  resources :reliance_events, only: :create

  resource :revenue_model, only: :show
end
```

Build these pages:

| Page                           | Purpose                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| **Developer Launchpad**        | Funded-startup accounts, integrations and evidence-readiness stage                    |
| **Project Evidence Map**       | Claim → source → model run → candidate → review → receipt → artifact                  |
| **Model Run Detail**           | Adapter identity, source commitments, output digest, candidates, gaps and limitations |
| **Candidate Review Workbench** | Accept, reject or request more evidence                                               |
| **Premium Artifact Builder**   | Select commercial product, included receipts, relying party and artifact scope        |
| **Reliance Event Record**      | Record actual protocol, VVB, buyer, auditor or insurer use                            |
| **C-Suite Revenue Model**      | Conservative, base and upside projections with visible assumptions                    |

Keep the existing `/marketplace` as the public evidence-product catalog. Link its products into `ArtifactEngagement`; do not create an unrelated second marketplace.

---

## 11. Premium Product Catalog

Create:

```text
athian_ink_rails_bootstrap/config/agevidence/products.yml
```

Include:

| Code                                  | Base planning price |
| ------------------------------------- | ------------------: |
| `evidence_architecture_sprint`        |             $25,000 |
| `protocol_evidence_implementation`    |            $100,000 |
| `verification_readiness_cycle`        |             $60,000 |
| `enterprise_reliance_artifact`        |             $30,000 |
| `managed_evidence_plane`              |       $150,000/year |
| `private_deployment_model_registry`   |       $300,000/year |
| `sponsor_portfolio_program`           |       $200,000/year |
| `methodology_migration_dispute_event` |            $250,000 |

Every page must label these:

```text
Illustrative management hypotheses—not quotes, commitments, or recognized revenue.
```

Price the product by:

* Protocol complexity
* evidence classes
* source systems
* review burden
* relying-party count
* transaction materiality
* selective-disclosure requirements
* response time
* migration or dispute exposure

Do not price according to tokens, API calls, signatures, receipt count, or bytes stored.

---

## 12. Revenue Projection Engine

Create:

```text
config/agevidence/revenue_scenarios.yml
app/services/agevidence/revenue_projection.rb
```

The Ruby service must be a pure calculation object with no database dependency.

Base case:

| Revenue stream          |    Price | Y1 units | Y2 units | Y3 units |
| ----------------------- | -------: | -------: | -------: | -------: |
| Architecture Sprint     |  $25,000 |       10 |       22 |       36 |
| Protocol Implementation | $100,000 |        5 |       10 |       18 |
| Verification Readiness  |  $60,000 |        4 |       10 |       22 |
| Enterprise Artifact     |  $30,000 |        6 |       18 |       45 |
| Managed Evidence Plane  | $150,000 |        4 |       12 |       26 |
| Private Deployment      | $300,000 |        2 |        5 |        9 |
| Sponsor Program         | $200,000 |        3 |        6 |       10 |
| Migration or Dispute    | $250,000 |        1 |        2 |        4 |

Required base outputs:

```text
Year 1: $3.220M
Year 2: $7.690M
Year 3: $14.970M
```

Recurring component:

```text
Year 1: $1.800M
Year 2: $4.500M
Year 3: $8.600M
```

Also seed:

```text
Conservative: $1.005M / $2.520M / $5.840M
Base:         $3.220M / $7.690M / $14.970M
Upside:       $5.765M / $14.375M / $28.600M
```

The dashboard must distinguish:

* projected pipeline
* illustrative contracted value
* annual recurring revenue
* episodic artifact revenue
* realized external reliance events

Never display projected revenue as booked or recognized revenue.

---

## 13. Canonical Seed Story

Add one fictional funded startup:

```text
Company: Northstar Methane Systems
Stage: Series A
Capital raised: $18 million
Product: livestock methane-reduction intervention
Commercial milestone: enterprise dairy pilot
```

Seed the following story:

1. The startup creates a developer project.
2. It registers the Qwen3.5 reference adapter.
3. It submits a trial report, invoice, ration log and measurement export.
4. The model identifies seven evidence candidates.
5. It identifies:

   * one missing dosage record;
   * one methodology-version mismatch;
   * one unsupported causal statement.
6. A human reviewer:

   * accepts four candidates;
   * rejects one;
   * requests more evidence for two.
7. `InkReceipts` issues:

   * Model Execution Receipt;
   * candidate receipts;
   * review-decision receipts.
8. The system generates an Evidence Architecture Sprint artifact.
9. Additional evidence resolves the dosage gap.
10. A Verification Readiness Artifact is assembled.
11. A simulated VVB reliance event is recorded.
12. The project converts into a Managed Evidence Plane engagement.

Clearly label the company, reviewer and VVB as synthetic demonstration entities.

---

## 14. Runtime Modes

Support three modes:

```text
AGEVIDENCE_MODE=fixture
AGEVIDENCE_MODE=local
AGEVIDENCE_MODE=remote
```

### Fixture mode

* Default for tests and seeded demonstrations.
* No model download.
* Loads normalized responses from fixtures.
* Must run in CI.

### Local mode

* Calls a local OpenAI-compatible endpoint.
* Supports Qwen through vLLM or SGLang.
* Configured by environment variables.
* No hard-coded model path.

### Remote mode

* Reserved for a controlled private endpoint.
* Disabled unless explicitly configured.
* Must not send source evidence without an explicit data-handling configuration.

---

## 15. Testing Requirements

### Rails

Test:

* Developer project creation.
* Model-run ingestion.
* Candidate review state transitions.
* Append-only review decisions.
* Artifact engagement creation.
* Reliance-event recording.
* Revenue projection totals.
* Existing AVSA, marketplace, verifier and bundle flows.

### Model service

Test:

* Contract validation.
* Source-reference preservation.
* Gap extraction.
* malformed model-output rejection.
* fixture parity.
* adapter substitution.
* absence of receipt signing.

### Rust

Test:

* AgEvidence schema validation.
* canonical commitment generation.
* parent-link validation.
* model-adapter substitution without schema changes.
* receipt tampering.
* missing model or prompt digest.
* review receipt without candidate parent.
* reliance receipt without artifact parent.

### Boundary test

Keep the existing Rails boundary grep:

```bash
rg -n "\bDigest\b|\bOpenSSL\b|crypto\.subtle\.digest|SHA256|SHA-256" \
  athian_ink_rails_bootstrap/app \
  athian_ink_rails_bootstrap/db
```

It must return no matches.

---

## 16. Definition of Done

The implementation is complete only when a reviewer can:

1. Open the Developer Launchpad.
2. Select a funded-startup project.
3. Inspect its source-document commitments.
4. run a fixture-backed Qwen3.5 evidence extraction.
5. inspect every candidate’s source references.
6. see material evidence gaps.
7. approve or reject candidates through append-only decisions.
8. issue and locally verify a Model Execution Receipt.
9. assemble a premium evidence artifact.
10. download a self-contained bundle.
11. verify that bundle without trusting the Rails interface.
12. record an external reliance event.
13. inspect the commercial engagement tied to the artifact.
14. view the revenue scenario without confusing projections with actual revenue.
15. replace Qwen3.5 with a fixture for another model without changing receipt or artifact schemas.

---

## 17. Pull-Request Sequence

Implement as bounded pull requests:

```text
PR 1 — AgEvidence contracts, schemas and architecture documentation
PR 2 — Rails developer-project and model-run domain models
PR 3 — Fixture-backed model service and adapter contract
PR 4 — Model Execution, review and reliance receipt support
PR 5 — Developer Launchpad and candidate-review workbench
PR 6 — Premium artifact catalog and engagement workflow
PR 7 — Revenue projection dashboard and scenario tests
PR 8 — Canonical seed story, bundle export and end-to-end acceptance tests
```

Do not begin with production Qwen deployment, GPU orchestration, authentication, billing, multitenancy or confidential customer data. First prove the complete evidence and commercial chain with synthetic data, fixture inference and independently verifiable artifacts.
