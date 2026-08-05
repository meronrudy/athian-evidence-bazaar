# Trust Boundary Orientation

## Purpose

The trust boundary is the line between human-readable workflow projections and
independently verifiable evidence artifacts.

Rails may orchestrate and display. It must not become the cryptographic
authority. The boundary is:

```text
Rails
  -> ink_receipts Ruby facade
  -> Rust BAINK trust kernel and CLI
```

## Implemented Scaffold

`ink_receipts` exposes the receipt-like API used by Rails:

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

The facade also contains integration event canonicalization and HMAC helpers so
Rails app code does not implement ad hoc event signing logic.

## Receipt Signatures vs Event Signatures

Do not collapse these concepts:

- Integration event signature: proves a normalized event came from an authorized
  integration source.
- INK receipt signature: proves a canonical evidence or decision payload was
  issued under the receipt trust contract.

An integration event can be validly submitted but still produce an
indeterminate evidence projection. A receipt can be cryptographically valid
while method compatibility or institutional reliance remains unresolved.

## What Rails Must Never Do

Rails app and db code must not:

- compute receipt hashes;
- sign receipts;
- verify receipt cryptography;
- evaluate trust policy directly;
- assemble canonical bundle manifests directly;
- treat database rows as proof;
- turn model confidence into method eligibility;
- turn payment or funding share into claim authority.

The boundary grep is:

```bash
rg -n "\bDigest\b|\bOpenSSL\b|crypto\.subtle\.digest|SHA256|SHA-256" \
  athian_ink_rails_bootstrap/app \
  athian_ink_rails_bootstrap/db
```

It should return no matches.

## Rust Responsibilities

The Rust workspace is responsible for:

- canonicalization;
- receipt payload validation;
- signing substrate;
- signature verification;
- parent validation;
- bundle integrity;
- local verifier output;
- domain payload validation through `baink-agevidence`.

The generic Rust kernel must not import country adapters, Rails code, Python
model logic, or customer-specific workflow.

## Demo-Only Behavior

- If the Rust CLI is not configured, `ink_receipts` emits deterministic demo
  projections from inside the gem.
- Some receipt schemas are scaffold placeholders.
- Lightweight AVSA anchors exist to support demo artifact assembly.
- HMAC integration signing is implemented in the facade; Ed25519 integration
  verification is still a hardening item.

## Production-Hardening Backlog

- bind Rails to the released verifier binary and trust material;
- finalize receipt schemas and schema commitments;
- implement key management, revocation snapshots, and verifier policy handling;
- add tamper tests for every artifact profile;
- implement Ed25519 integration verification through the approved boundary;
- ensure offline verification works without trusting Rails UI state.

## Non-Goals

- no Rails cryptography;
- no Python receipt signing;
- no country-specific receipt envelopes;
- no silent recomputation of historical receipt state;
- no verifier dependency on live registry access for core bundle validity.

## Read Next

- [Model Authority Boundary](../implementation/MODEL_AUTHORITY_BOUNDARY.md)
- [Global Thin Waist Architecture](../implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md)
- [Engineering Architecture Orientation](ENGINEERING_ARCHITECTURE_ORIENTATION.md)
