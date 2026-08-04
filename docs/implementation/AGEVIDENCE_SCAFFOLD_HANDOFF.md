# AgEvidence Scaffold Handoff

## What exists

The scaffold adds a fixture-backed AgEvidence path across the monorepo:

- `crates/baink-agevidence`: domain payload validation scaffold.
- `services/agevidence-model`: FastAPI service with fixture-first adapter contract.
- `specs/agevidence`: versioned receipt payload schemas and policy/profile placeholders.
- `examples/funded_startup`: synthetic Northstar source material and expected fixture outputs.
- `athian_ink_rails_bootstrap/app/models/agevidence`: Rails projection models.
- `athian_ink_rails_bootstrap/app/services/agevidence`: Rails orchestration services.
- `athian_ink_rails_bootstrap/config/agevidence`: premium product and revenue scenario config.

The existing AVSA Evidence Bazaar demo remains the carbon-domain anchor. AgEvidence extends it with developer projects, model runs, candidate review, premium artifacts, reliance events, and revenue scenarios.

## Fractional developer ownership

Suggested work packages:

- Rust developer: replace lightweight field checks in `baink-agevidence` with schema-backed validation and parent-policy tests.
- Python developer: implement `local` and `remote` adapters behind the existing `BaseAdapter#run` contract.
- Rails backend developer: harden model-run ingestion, review decision append-only guarantees, and artifact assembly persistence.
- Rails frontend developer: refine AgEvidence pages while preserving the evidence-first operating model.
- GTM analyst: maintain `products.yml` and `revenue_scenarios.yml` without representing projections as recognized revenue.

## TODO marker policy

Use `AGEVIDENCE_TODO:` comments for production gaps. Each marker should name the owner role and the blocked decision.

Example:

```text
AGEVIDENCE_TODO: Python owner - replace fixture adapter transport with configured local endpoint call.
```

## Validation commands

```bash
cargo test --workspace
cd services/agevidence-model && python3 -m pytest
cd athian_ink_rails_bootstrap && bin/rails db:migrate db:seed test
cd athian_ink_rails_bootstrap && npm run build
```

The current local workstation must activate Ruby 3.3.8 and install Node before the Rails and frontend validation commands can complete.

## Pull-request completion notes

- PR 1 is complete when schemas, examples, docs, and `baink-agevidence` validation compile.
- PR 2 is complete when Rails migrations and namespaced models pass model tests.
- PR 3 is complete when fixture mode returns the normalized Northstar response through `POST /v1/evidence-runs`.
- PR 4 is complete when model execution, candidate, review, artifact, and reliance receipt APIs exist in `InkReceipts`.
- PR 5 is complete when the Developer Launchpad, Project Evidence Map, Model Run Detail, and Candidate Review Workbench render.
- PR 6 is complete when premium artifact engagement creates an `EvidenceBundle`.
- PR 7 is complete when revenue projection tests match the configured base totals.
- PR 8 is complete when seeds create the full Northstar story and existing Evidence Bazaar flows still pass.
