# Global Thin-Waist Architecture

Athian AgEvidence uses one global evidence graph and many local policy interpretations.

```text
Country and institutional applications
Country policy and adapter layer
GLOBAL THIN WAIST
Generic INK trust implementation
```

The dependency direction is always downward:

```text
Country application
depends on
Country adapter
depends on
Global AgEvidence contracts
depends on
Generic INK receipt kernel
```

The generic receipt kernel must never depend on a country adapter.

## Thin Waist

The thin waist is the smallest stable contract used by country methods, models, verifiers, producers, buyers, and relying institutions:

- canonical receipt envelope;
- stable agricultural event schemas;
- source commitments;
- parent links;
- authority declarations;
- policy references;
- limitations;
- signatures;
- verification result vocabulary;
- bundle manifest.

Country-specific fields must not be added to the top-level receipt envelope. Country-specific information belongs in payloads, policy references, country determinations, and artifact manifests.

## Stable Receipt Types

Global receipt types describe what happened, not which national program recognized it:

- `authority_receipt`
- `intervention_receipt`
- `observation_receipt`
- `measurement_receipt`
- `model_execution_receipt`
- `evidence_candidate_receipt`
- `evidence_gap_receipt`
- `human_review_receipt`
- `verification_determination_receipt`
- `asset_issuance_receipt`
- `contribution_receipt`
- `claim_receipt`
- `retirement_receipt`
- `payment_receipt`
- `methodology_delta_receipt`
- `artifact_assembly_receipt`
- `country_adapter_commitment_receipt`
- `country_compatibility_determination_receipt`
- `reliance_event_receipt`

Do not introduce receipt names such as `canada_feedlot_measurement_receipt` or `j_credit_verifier_receipt`.

## Three Validity States

Cryptographic validity is produced by the trust layer:

- `valid`
- `invalid`
- `indeterminate`

Method compatibility is produced by a country-policy evaluator:

- `eligible`
- `eligible_with_conditions`
- `outside_current_method`
- `method_extension_required`
- `insufficient_evidence`
- `unassigned`

Institutional reliance is recorded from relying workflows:

- `accepted`
- `relied_on`
- `rejected`
- `needs_more_evidence`

Never display one state as a substitute for another.

## Evidence And Interpretation

Evidence receipts capture what happened. Country determinations interpret that evidence through immutable policy versions.

One intervention, measurement, model execution, and human-review chain may produce Canada, Australia, Japan, New Zealand, Ireland/EU, and Brazil compatibility determinations. The evidence receipt digests stay fixed; adapter commitments, determinations, artifact manifests, and reliance events differ.

Model adapters remain separate from country adapters. A model adapter declares which model, runtime, prompts, source commitments, and normalized output were used. A country adapter declares method scope, excluded contexts, evidence requirements, claim policy, verification profile, data policy, artifact profiles, and limitations.

When a method changes:

```text
Existing evidence receipts remain unchanged
New adapter version is published
Existing evidence graph is reevaluated
Methodology Delta Receipt is issued
New compatibility determination is appended
Affected artifacts are regenerated
```

Do not replace historical determinations silently.

## Rights And Claims

Rights are evidence objects, not free text. Producer authority, property authority, data-use authority, contractual claim rights, identity bindings, and consent or permission receipts should be represented explicitly and then required by country adapters where relevant.

Co-claiming uses the global `ClaimShare` structure. Country claim policies interpret it; do not introduce country-specific claim-share models.

## Artifacts

Reliance artifacts are built from profiles. A profile declares required receipts, required documents, local verification requirements, limitations, and relying-party audience. The artifact builder consumes this data and should not contain country-specific branches.
