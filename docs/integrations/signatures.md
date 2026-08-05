# Signatures

Signing input:

```text
timestamp + "\n" + canonical_payload
```

The timestamp is supplied in `X-Athian-Timestamp`. The signature is supplied in
`X-Athian-Signature`.

The local `ink_receipts` facade owns canonical payload serialization,
commitments, and signature helpers for this scaffold. Rails app code delegates
to that boundary and does not implement receipt cryptography.

Integration signatures are separate from receipt signatures. A valid
integration event can still produce an invalid or indeterminate receipt result.
