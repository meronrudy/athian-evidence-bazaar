# Python SDK Flow

This walkthrough uses the canonical Python SDK and the thin example client:

```text
sdks/python
examples/sdk/python/agevidence_client.py
```

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Run the Example

Start Rails, then run:

```bash
python3 -m pip install -e "sdks/python[test]"
python3 examples/sdk/python/agevidence_client.py
```

The example creates a sandbox project against:

```text
http://localhost:3000
```

## Client Methods

The canonical SDK mirrors the OpenAPI contract and includes:

- `create_project`
- `submit_source_record`
- `run_model`
- `review_candidate`
- `create_quote`
- `create_order`
- `checkout_order`
- `build_artifact`
- `get_artifact`
- `download_artifact_metadata`
- `get_operation`
- `wait_for_operation`
- `submit_event`
- `get_event`
- `replay_event`

The package also provides the `agevidence` CLI:

```bash
agevidence --help
agevidence replay project-4030 --help
```

The OpenAPI source remains:

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
