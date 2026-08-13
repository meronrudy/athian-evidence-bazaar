# Trust Boundary

The Python SDK is a developer-plane tool for local primitives, ingest,
provenance checks, fixture tests, source adapters, and hosted API clients.

It does not implement receipt signing, receipt commitments, dCBOR, or bundle
verification internally.

## Python SDK May

- build local primitives;
- infer primitives from native JSON;
- check local provenance completeness;
- test source adapters;
- call hosted APIs when configured;
- delegate verification to an external Rust verifier.

## Python SDK Must Not Claim

- regulatory eligibility;
- scientific validity;
- carbon-credit issuance;
- third-party verification;
- claim ownership;
- institutional reliance.

## Rust Trust Boundary

Bundle verification is delegated:

```bash
agevidence verify bundle.json
```

Configure the verifier with `AGEVIDENCE_VERIFIER_COMMAND` or:

```bash
agevidence login --verifier-command "target/debug/baink-cli"
```

If no verifier is configured, local primitive and provenance flows still work.

