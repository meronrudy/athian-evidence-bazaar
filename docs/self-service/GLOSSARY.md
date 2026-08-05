# Glossary

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## AgEvidence

The evidence-first developer operating system for agricultural claims,
source records, model candidates, human review, receipts, and reliance
artifacts.

## Artifact

A packaged evidence product intended for a buyer, verifier, auditor, registry,
insurer, or other relying party. Artifact metadata includes verification
commands and limitations.

## Candidate

A model-derived or proposed evidence assertion that requires review. A
candidate is not approved evidence by default.

## Compatibility

A versioned policy assessment that compares an evidence graph to a country,
method, claim, verification, or artifact profile. Compatibility is not the
same as cryptographic validity or institutional reliance.

## Cryptographic Validity

The trust-layer result for receipt or bundle integrity. Typical states are
`valid`, `invalid`, and `indeterminate`.

## Evidence Event Inbox

The append-only `/v1/integrations/events` bridge for signed operational events
from an existing system of record.

## Evidence Graph

The linked history of source records, receipts, parent references, model runs,
review decisions, determinations, and artifact assembly.

## Evidence Projection

Rails workflow state derived from source records or integration events. A
projection is useful for display and orchestration, but it is not the
cryptographic source of truth.

## Gap

Missing, contradictory, or insufficient evidence identified by the model
service or review process.

## Local Verification

Verification performed outside the Rails browser interface against a receipt or
bundle.

## Model Output

Candidate evidence and gap analysis. Model output cannot approve methods,
certify reductions, determine claim ownership, or create institutional
reliance.

## Receipt

A signed, canonical commitment to an evidence or decision payload. Rails calls
through `ink_receipts`; Rails does not sign receipts directly.

## ReceiptOutbox

The transactional queue of receipt issuance requests created after projections
are persisted.

## Reliance

A bounded decision by a buyer, VVB, auditor, registry, lender, sponsor, or
other institution. Reliance is recorded separately from artifact assembly.

## Source Record

A controlled reference to source evidence, including document ID, evidence
type, controlled URI, commitment, and source system.

## Trust Boundary

The `ink_receipts` Ruby facade and Rust receipt/verifier workspace. Trust
operations belong there, not in Rails controllers, models, or views.
