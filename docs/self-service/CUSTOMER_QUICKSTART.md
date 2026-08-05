# Customer Quickstart

This quickstart is for a customer operator who wants to test the AgEvidence
Developer OS without writing a full integration first.

## Outcome

You will create a sandbox project, add source-record references, run
fixture-backed evidence extraction, review candidates, request a sandbox quote,
create a sandbox artifact order, and inspect verification metadata.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Before You Start

Use the Rails app locally after setup:

```bash
cd athian_ink_rails_bootstrap
bin/rails db:migrate db:seed
bin/dev
```

If Ruby 3.3.8 or Node/npm are not installed, local Rails validation may not
run on this workstation. The documentation still describes the implemented
routes and workflow.

## Start in the Browser

Open:

```text
http://localhost:3000/agevidence/developer-os
```

Choose the Source Records path when you have documents or controlled references.
Choose the Event Inbox path when an existing operational system can publish
signed events.

## Source-Record Path

1. Create or select a developer project.
2. Open the source-record console.
3. Add a controlled reference with:
   - `document_id`
   - `evidence_type`
   - `controlled_uri`
   - `commitment`
   - `source_system`
4. Confirm that Rails creates an evidence projection.
5. Run fixture-backed model extraction.
6. Review candidates and gaps.
7. Append human review decisions.
8. Create a sandbox quote.
9. Create a sandbox artifact order.
10. Inspect artifact metadata and the local verification command.

Large documents remain outside Rails. Rails stores references, commitments,
projections, and workflow state.

## What Model Output Means

Model output is candidate evidence only. It can extract, classify, link sources,
and identify evidence gaps. It cannot approve methods, certify reductions,
determine claim ownership, or create institutional reliance.

Every model-derived candidate starts as `review_required`.

## What the Artifact Shows

Artifact metadata separates:

- cryptographic validity
- method compatibility
- review status
- artifact status
- reliance status
- payment status

A cryptographically valid artifact is not automatically scientifically
accepted, method-compatible, paid, or institutionally relied upon.

## Next Guides

- [Source Records Guide](SOURCE_RECORDS_GUIDE.md)
- [Model and Review Guide](MODEL_REVIEW_GUIDE.md)
- [Pricing, Orders, and Artifacts](PRICING_ORDERS_ARTIFACTS_GUIDE.md)
- [Local Verification Guide](LOCAL_VERIFICATION_GUIDE.md)
