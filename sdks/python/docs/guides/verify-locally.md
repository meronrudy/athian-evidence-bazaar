# Verify Locally

Bundle verification is delegated to the configured Rust verifier.

```bash
agevidence verify bundle.json
```

Configure the verifier:

```bash
export AGEVIDENCE_VERIFIER_COMMAND="target/debug/baink-cli"
```

or:

```bash
agevidence login --verifier-command "target/debug/baink-cli"
```

The Python SDK does not sign receipts, compute receipt commitments, implement
dCBOR, or verify bundles internally.

## What Verification Can Answer

- Is the bundle well formed?
- Does the canonical commitment match?
- Are required parents present?
- Is the bundle internally consistent?
- Is declared trust material available?

## What It Does Not Answer

Local verification does not establish regulatory eligibility, scientific
validity, carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance unless those states are separately issued by the relevant
authority and included in the artifact.

