# Local Verification Guide

Local verification is the reason AgEvidence artifacts are portable. A reviewer
should be able to inspect an artifact without trusting the Rails browser view.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## What Local Verification Answers

Cryptographic verification answers:

- Is the receipt well formed?
- Does the canonical commitment match?
- Is the signature valid?
- Are required parents present?
- Is the bundle internally consistent?
- Is declared trust material available?

It returns states such as:

- `valid`
- `invalid`
- `indeterminate`

## What Local Verification Does Not Answer

Local cryptographic verification does not automatically answer:

- whether a national method applies
- whether a regulator approved the project
- whether a VVB relied on the artifact
- whether a buyer accepted a Scope 3 claim
- whether payment was collected

Those are method compatibility, institutional reliance, and payment states.

## Verification Command

Artifact metadata includes a local command such as:

```bash
agevidence verify bundle.zip
```

or a scaffold equivalent exposed by the Rails artifact page.

Use the command shown on the artifact page because profile names, bundle paths,
and verifier aliases may change during scaffold hardening.

## Trust Boundary

Rails does not compute receipt hashes, sign receipts, or verify bundles
directly. Receipt-like behavior goes through `ink_receipts` and the Rust trust
boundary.

Integration signatures and receipt signatures are different:

- integration signature: proves an authorized source submitted an event
- receipt signature: proves a canonical evidence or decision payload was issued
  under the receipt contract

## Related Guides

- [Pricing, Orders, and Artifacts](PRICING_ORDERS_ARTIFACTS_GUIDE.md)
- [Trust Boundary Orientation](../internal/TRUST_BOUNDARY_ORIENTATION.md)
- [Glossary](GLOSSARY.md)
