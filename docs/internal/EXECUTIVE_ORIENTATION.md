# Executive Orientation

## What This Repository Demonstrates

AgEvidence is positioned as a Developer OS for agricultural evidence, not as a
carbon marketplace and not as a bespoke enterprise implementation practice.

The central message is:

```text
Existing operational platform
  -> signed event or controlled source record
  -> append-only evidence projection
  -> review-required model candidates
  -> human review
  -> INK receipt request
  -> portable reliance artifact
```

Rails makes the workflow visible. Python extracts and normalizes candidate
evidence. `ink_receipts` and Rust remain the trust boundary. The product value
is institutional reliance on portable evidence, with carbon assets as one
possible commercial object.

## Implemented Scaffold

The current repository includes:

- a Rails Evidence Bazaar demo with dashboard, AVSA receipt chain, evidence
  explorer, verifier console, bundle builder, producer ledger, marketplace, and
  methodology migration;
- an AgEvidence Developer OS with source records, fixture model runs, candidate
  review, sandbox quotes, artifact orders, and artifact metadata;
- an append-only Evidence Event Inbox for existing Athian operational systems;
- an OpenAPI contract and minimal Python/TypeScript SDK examples;
- country adapter packs for global expansion without country-specific Rails
  forks;
- a Rust workspace and local `ink_receipts` facade for receipt and verifier
  responsibilities.

## Demo-Only Behavior

The scaffold should not be represented as production deployment. Specifically:

- fixture model output is not a live Qwen deployment;
- sandbox checkout is not collected, booked, or recognized revenue;
- artifact bundles are demonstration artifacts unless separately verified and
  accepted by a relying institution;
- lightweight AVSA anchors may be created for scaffold artifact assembly;
- HMAC integration authentication exists, while Ed25519 integration
  verification remains planned hardening;
- runtime JSON Schema validation is not yet the final enforcement layer.

## GTM Implications

The strongest near-term GTM motion is the Australian Livestock Evidence Event
Bridge described in the Australian backlog. The pitch is not “replace Athian’s
current platform.” It is:

```text
Keep the current operational system.
Publish a bounded set of signed evidence events.
Receive an independently inspectable evidence projection and artifact callback.
```

The first paid product should remain an Evidence Architecture Sprint. It maps a
startup or Athian operational workflow into the existing eight-event contract
before adding new event types.

## Revenue Path Framing

Commercial values in the repository are illustrative management hypotheses. They
help show pricing logic and customer segmentation, but they are not quotes,
commitments, booked value, cash collected, or recognized revenue.

The revenue signal to watch is:

```text
paid artifact engagement
  + external reliance event
  + reusable integration capability
```

Artifact generation alone is not proof of commercial value. External reliance
is the north-star signal.

## Key Risks

- confusing cryptographic validity with method compatibility or institutional
  reliance;
- implying model output has approval authority;
- allowing customer-specific implementations to create country forks;
- overbuilding Salesforce replication instead of preserving the one-way inbox;
- treating sandbox pricing as revenue;
- hardening infrastructure before proving the first paid integration mapping.

## Read Next

- [Australian GTM Backlog](../strategy/AUSTRALIAN_AGEVIDENCE_GTM_BACKLOG.md)
- [C-Suite Proposal](../strategy/ATHIAN_AGEVIDENCE_CSUITE_PROPOSAL.md)
- [Premium Artifact Catalog](../implementation/PREMIUM_ARTIFACT_CATALOG.md)
- [Internal Orientation Index](README.md)
