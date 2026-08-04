# Verifier Adapter Contract

## Command

```text
ink verify <bundle-or-receipt.json> --json
```

## Success payload

```json
{
  "status": "valid | invalid | indeterminate",
  "message": "Human-readable result",
  "checks": [
    {
      "name": "signature",
      "status": "valid",
      "detail": "Ed25519 signature verified under key policy"
    }
  ]
}
```

## Rails handling

- `InkVerifier` calls `InkReceipts.verify(...)`; the facade may call the Rust verifier or return an indeterminate facade-level result.
- A nonzero process exit becomes `indeterminate` with the verifier error captured.
- Invalid JSON becomes `indeterminate`.
- Any unsupported status becomes `indeterminate`.
- The raw verifier command is split with `Shellwords`; no shell interpolation is used.
- Rails stores the result and check list as an audit record.

## Required production additions

- Pass a real receipt file or bundle path rather than a database projection reference.
- Bind the invocation to a released verifier version and record its binary digest.
- Include trust-policy and revocation snapshot identifiers in the result.
- Store the machine-readable verifier report in the exported bundle.
- Add execution timeouts, resource limits, and sandboxing.
