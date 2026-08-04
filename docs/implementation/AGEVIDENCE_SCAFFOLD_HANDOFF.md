# AgEvidence Scaffold Handoff

## What exists

The scaffold adds a fixture-backed AgEvidence path across the monorepo:

- `crates/baink-agevidence`: domain payload validation scaffold.
- `services/agevidence-model`: FastAPI service with fixture-first adapter contract.
- `specs/agevidence`: versioned receipt payload schemas and policy/profile placeholders.
- `specs/agevidence/vocabulary`: stable global agricultural identifiers used by receipts and country packs.
- `specs/agevidence/country_adapters`: declarative country adapter packs for method scope, claim policy, verification profile, data policy, and artifact profiles.
- `examples/funded_startup`: synthetic Northstar source material and expected fixture outputs.
- `athian_ink_rails_bootstrap/app/models/agevidence`: Rails projection models.
- `athian_ink_rails_bootstrap/app/services/agevidence`: Rails orchestration services.
- `athian_ink_rails_bootstrap/config/agevidence`: premium product and revenue scenario config.

The existing AVSA Evidence Bazaar demo remains the carbon-domain anchor. AgEvidence extends it with developer projects, model runs, candidate review, country determinations, premium artifacts, reliance events, and revenue scenarios.

## Global thin-waist scaffold

Read `docs/implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md` before adding a country. The implementation invariant is:

```text
one global evidence graph
many versioned country determinations
many institution-specific reliance artifacts
```

Country-specific method rules belong only in versioned YAML adapter packs under `specs/agevidence/country_adapters`. Rails controllers, ERB templates, Python prompts, JavaScript, and generic Rust crates must not contain national methodology branches.

## Fractional developer ownership

Suggested work packages:

- Rust developer: replace lightweight field checks in `baink-agevidence` with schema-backed validation and parent-policy tests.
- Python developer: implement `local` and `remote` adapters behind the existing `BaseAdapter#run` contract.
- Rails backend developer: harden model-run ingestion, review decision append-only guarantees, country determination supersession, and artifact assembly persistence.
- Rails frontend developer: refine AgEvidence and country-program pages while preserving the evidence-first operating model and shared partials.
- Country policy developer: maintain adapter manifests, method versions, and artifact profiles as data packs.
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
rg -n "\bDigest\b|\bOpenSSL\b|crypto\.subtle\.digest|SHA256|SHA-256" athian_ink_rails_bootstrap/app athian_ink_rails_bootstrap/db
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
- Global PR 1 is complete when the receipt envelope, vocabulary, country-determination, adapter-commitment, artifact-profile, and verifier-result contracts exist.
- Global PR 2 is complete when country policy projections and append-only determinations pass model tests.
- Global PR 3 is complete when the country adapter catalog loads Australia and Canada from YAML and placeholder countries validate.
- Global PR 4 is complete when one evidence graph can be evaluated through Canada and Australia without mutating the original receipts.
- Global PR 5 is complete when model-run requests accept country context while all model-derived facts remain `review_required`.
- Global PR 6 is complete when country-program pages render from shared partials and no country-specific Rails templates are introduced.
