# Model Service Orientation

## Purpose

The Python model service extracts and normalizes candidate evidence. It does not
approve evidence, issue receipts, certify reductions, determine legal rights, or
write directly to Rails.

The model-service boundary is:

```text
source references
  -> model request
  -> candidate assertions
  -> source links
  -> evidence gaps
  -> limitations
  -> Rails human review
```

All model output remains review-required until a human or policy workflow acts
on it.

## Runtime Modes

Implemented scaffold modes:

- `AGEVIDENCE_MODE=fixture`: default mode for tests and seeded demos; no model
  download.
- `AGEVIDENCE_MODE=local`: intended for a local OpenAI-compatible endpoint such
  as vLLM or SGLang; configured by environment variables.
- `AGEVIDENCE_MODE=remote`: reserved for controlled private endpoints and must
  not send source evidence without explicit data-handling configuration.

Fixture mode is the safe default.

## Qwen Reference Adapter

The Qwen3.5 adapter is a reference adapter entry. It should not be described as
an Athian approval authority, protocol authority, VVB, registry, or scientific
determination engine.

Its role is to demonstrate how an interchangeable model adapter can:

- extract candidate facts;
- classify evidence;
- preserve source references;
- identify gaps;
- normalize output into the contract Rails expects.

## Normalized Output

The service response should preserve:

- model run metadata;
- adapter identity;
- prompt and retrieval commitments;
- source-document references;
- candidates;
- gaps;
- limitations.

Candidates should include source references. Gaps should describe missing or
contradictory support. Model confidence is an extraction signal only, not
scientific validity.

## Forbidden Model Authority Claims

Model output must not include or imply:

- government eligibility;
- credit approval;
- verified emission reduction;
- legal validity;
- claim ownership;
- asset issuance;
- VVB determination;
- buyer reliance.

If model output attempts to assert those states, downstream ingestion should
reject, strip, or flag it for review depending on the production policy.

## Implemented Scaffold

- FastAPI service under `services/agevidence-model`.
- Pydantic contracts for request/response validation.
- Fixture adapter and adapter registry.
- Tests for contract validation, fixture parity, source-reference preservation,
  adapter substitution, and absence of receipt signing.
- Rails `Agevidence::ModelRunIngestion` consumes fixture output and creates
  `Agevidence::ModelRun`, `EvidenceCandidate`, and `EvidenceGap` records.

## Demo-Only Behavior

- Fixture outputs are deterministic examples, not real inference.
- Local and remote transports are not production-ready.
- Model outputs are not evaluated as final method compatibility.
- Receipts for model execution still go through the Rails-to-`ink_receipts`
  scaffold path.

## Production-Hardening Backlog

- implement local OpenAI-compatible transport;
- implement remote transport only with explicit data-handling policy;
- add malformed output rejection for authority claims;
- add model-run retention and artifact traceability policy;
- add evaluation fixtures by domain and country adapter;
- document prompt versioning and prompt commitment strategy;
- add operational monitoring for abstention and gap rates.

## Non-Goals

- no receipt signing;
- no Rails database writes;
- no VVB replacement;
- no protocol approval;
- no legal-right determination;
- no country-specific model runtime.

## Read Next

- [Developer GTM Spec](../implementation/AGEVIDENCE_DEVELOPER_GTM.md)
- [Model Authority Boundary](../implementation/MODEL_AUTHORITY_BOUNDARY.md)
- [Rails Developer OS Orientation](RAILS_DEVELOPER_OS_ORIENTATION.md)
