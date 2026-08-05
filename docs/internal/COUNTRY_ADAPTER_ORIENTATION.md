# Country Adapter Orientation

## Purpose

Country adapters let one global evidence graph be interpreted through many
country and institutional policies without changing Rails workflow, model
runtime, receipt envelope, or cryptographic code.

The invariant is:

```text
capture evidence once
canonicalize and sign once
interpret through versioned policies many times
```

Country adapter data belongs in declarative packs, not application branches.

## Thin Waist

The global thin waist includes:

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

Country-specific information belongs in payloads, policy references,
determinations, and artifact manifests. Do not add country-specific top-level
receipt envelope fields.

## Implemented Scaffold

The repo includes:

- global vocabulary YAML under `specs/agevidence/vocabulary`;
- country adapter packs under `specs/agevidence/country_adapters`;
- starter Australia and Canada adapter manifests;
- placeholder packs for Japan, New Zealand, Ireland/EU, and Brazil;
- Rails country policy projection models;
- shared country program UI;
- append-only country determinations;
- `InkReceipts.issue_country_adapter_commitment`;
- `InkReceipts.issue_country_determination`.

## Validity Separation

Never display one trust state as a substitute for another:

- Cryptographic validity: receipt or bundle integrity.
- Method compatibility: policy evaluator result under a versioned country
  adapter.
- Institutional reliance: external institution decision or recorded workflow.

A cryptographically valid bundle can still be outside a current method. A
method-compatible bundle can still be rejected by a verifier.

## Adapter Pack Responsibilities

Country adapter packs define:

- country program;
- method and method version;
- applicability;
- required evidence;
- claim policy;
- verification profile;
- data policy;
- artifact profile;
- limitations.

Country adapters map local terminology to stable global identifiers. Local
labels and translations must not replace canonical semantic identifiers.

## Rails Responsibilities

Rails may:

- display country programs;
- load adapter data;
- run compatibility evaluation;
- append determinations;
- display missing evidence and limitations;
- assemble profile-driven artifacts.

Rails must not:

- define country rules in controllers or templates;
- overwrite determinations in place;
- present Athian compatibility as government approval;
- infer rights from payments;
- fork views by country.

## Demo-Only Behavior

- Australia and Canada are starter scaffold packs, not final policy products.
- Placeholder countries validate structure but are not launch-ready.
- Compatibility determinations are Athian compatibility assessments only.
- Artifact profiles are scaffolded and need domain/legal/VVB review before
  external reliance.

## Production-Hardening Backlog

- formal adapter schema validation;
- policy version governance;
- method supersession and delta receipts;
- local terminology and translation evidence policy;
- rights and identity-binding receipt requirements;
- portability tests across Australia, Canada, Japan, New Zealand, Ireland/EU,
  and Brazil;
- external legal, protocol, VVB, and country-policy review.

## Non-Goals

- no country-specific Rust crates;
- no Canada or Japan controllers;
- no country-specific receipt envelope;
- no automatic government eligibility;
- no translated-label commitments as primary semantics.

## Read Next

- [Global Thin Waist Architecture](../implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md)
- [Engineering Architecture Orientation](ENGINEERING_ARCHITECTURE_ORIENTATION.md)
- [Product and GTM Orientation](PRODUCT_GTM_ORIENTATION.md)
