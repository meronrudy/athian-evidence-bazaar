# Python SDK Flow

This walkthrough uses the minimal Python example client:

```text
examples/sdk/python/agevidence_client.py
```

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Run the Example

Start Rails, then run:

```bash
python3 examples/sdk/python/agevidence_client.py
```

The example creates a sandbox project against:

```text
http://localhost:3000
```

## Client Methods

The example mirrors the OpenAPI contract and includes:

- `create_project`
- `add_source_record`
- `create_model_run`
- `review_candidate`
- `create_quote`
- `create_order`
- `checkout_order`
- `request_artifact`
- `retrieve_operation`
- `create_event`

Production SDKs should be generated from:

```text
docs/openapi/agevidence.v1.yaml
```

Do not maintain independent request types by hand in multiple SDKs.

## Model Boundary

Any model run created by the SDK returns candidate evidence only. Model output
cannot approve methods, certify reductions, determine claim ownership, or
create institutional reliance.

## Trust Boundary

Receipt issuance and verification stay behind `ink_receipts` and Rust. The SDK
does not sign receipts or verify bundles directly.
