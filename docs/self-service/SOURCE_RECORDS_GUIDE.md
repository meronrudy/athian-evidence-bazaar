# Source Records Guide

Use the source-record path when you have source material but do not yet have a
signed operational event stream.

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## What a Source Record Is

A source record is a controlled reference to evidence. It is not a large file
stored in Rails.

Core fields:

- `document_id`: stable identifier for the source document or export.
- `evidence_type`: stable evidence vocabulary code.
- `controlled_uri`: governed reference such as `evidence://trial-report-001`.
- `commitment`: external commitment such as `sha256:...`.
- `source_system`: system that owns or produced the source.
- `metadata`: optional context for display and review.

## Large-Document Boundary

Rails stores references and projections. Large source documents, access
controls, retention policy, and data-room permissions remain outside Rails.

Do not paste complete confidential source documents into API payloads or logs.

## Source-Record Flow

```text
developer project
  -> controlled source reference
  -> source-record projection
  -> source.manifest_available event
  -> EvidenceProjection
  -> ReceiptOutbox
```

Receipt requests are asynchronous. Rails does not issue or verify receipts in
the source-record intake controller.

## Evidence Types

Use stable global evidence vocabulary where possible:

- `evidence.feed_invoice`
- `evidence.ration_log`
- `evidence.lab_report`
- `evidence.measurement_export`
- `evidence.trial_report`
- `evidence.product_authorization`
- `evidence.remote_sensing`

Localized labels can change without changing the canonical evidence code.

## Review Boundary

A source record can support a model candidate or human decision, but it does
not automatically prove method compatibility or institutional reliance.

Model output remains candidate evidence only and every model-derived candidate
starts as `review_required`.

## Related Guides

- [Source Record API Flow](examples/source-record-api-flow.md)
- [Model and Review Guide](MODEL_REVIEW_GUIDE.md)
- [Local Verification Guide](LOCAL_VERIFICATION_GUIDE.md)
