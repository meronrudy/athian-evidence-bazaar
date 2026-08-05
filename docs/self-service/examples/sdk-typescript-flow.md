# TypeScript SDK Flow

This walkthrough uses the minimal TypeScript example client:

```text
examples/sdk/typescript/agevidenceClient.ts
```

Sandbox pricing and orders are illustrative planning records, not booked,
collected, or recognized revenue.

## Client Methods

The example mirrors the OpenAPI contract and includes:

- `createProject`
- `addSourceRecord`
- `createModelRun`
- `reviewCandidate`
- `createQuote`
- `createOrder`
- `checkoutOrder`
- `requestArtifact`
- `retrieveOperation`
- `createEvent`

Use the client with a local Rails base URL:

```ts
const client = new AgEvidenceClient("http://localhost:3000");
```

## Recommended Flow

```text
createProject
  -> addSourceRecord
  -> createModelRun
  -> reviewCandidate
  -> createQuote
  -> createOrder
  -> checkoutOrder
  -> requestArtifact
```

## OpenAPI Source

Production TypeScript SDKs should be generated from:

```text
docs/openapi/agevidence.v1.yaml
```

The example exists to make the current scaffold easy to read, not to define a
separate API contract.

## Authority Boundary

Model output is candidate evidence only. Rails is not the receipt trust
boundary. Receipt-like behavior goes through `ink_receipts` and Rust.
