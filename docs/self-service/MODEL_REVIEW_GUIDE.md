# Model and Review Guide

AgEvidence model runs extract candidate evidence and gaps from source records
or inbox projections. They do not approve evidence.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Runtime Modes

The scaffold supports a fixture-first model boundary:

- `fixture`: default for demos and tests.
- `local`: future OpenAI-compatible local endpoint mode.
- `remote`: reserved for explicitly configured private endpoints.

Fixture mode is enough to demonstrate the workflow without downloading model
weights or sending source evidence to a remote service.

## What the Model May Do

The model service may:

- extract candidate assertions
- classify evidence
- link claims to source references
- identify missing evidence
- normalize terminology
- abstain when source support is insufficient

## What the Model Must Not Do

Model output cannot:

- approve methods
- certify emissions reductions
- determine legal ownership
- issue assets
- complete verification
- create institutional reliance

Every model-derived candidate remains `review_required` until a human appends a
review decision.

## Candidate Review

Review statuses:

- `review_required`
- `accepted`
- `rejected`
- `needs_more_evidence`
- `superseded`

Review decisions are append-only. A corrected or changed decision is another
decision record, not an update to the original decision.

## Gaps

Evidence gaps show what the model or reviewer could not establish from the
available sources. A gap can be material even when the source records and
receipts are cryptographically valid.

## State Separation

Keep these states separate in every artifact and review discussion:

- cryptographic validity
- method compatibility
- review status
- artifact status
- reliance status
- payment status

A candidate accepted by a reviewer is not automatically method-compatible,
institutionally relied upon, or commercially paid.

## Related Guides

- [Source Records Guide](SOURCE_RECORDS_GUIDE.md)
- [API User Guide](API_USER_GUIDE.md)
- [Local Verification Guide](LOCAL_VERIFICATION_GUIDE.md)
