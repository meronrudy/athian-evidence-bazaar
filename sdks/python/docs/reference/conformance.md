# Agevidence-compatible Conformance

A system is Agevidence-compatible if it can:

1. emit a valid canonical object;
2. pass the published schema;
3. produce deterministic canonical representation;
4. preserve required provenance relationships;
5. pass golden conformance fixtures;
6. be independently verified where a verifier is configured.

## Source Adapter Conformance

```bash
agevidence adapter test my_adapter.py fixtures/
```

Conforming source adapters should map source-system quirks into existing
Agevidence primitives without requiring canonical schema extensions.

## Golden Fixtures

The SDK test suite includes golden examples for observations, interventions,
model runs, operational events, malformed records, and bundle verification.

## What Conformance Does Not Mean

Agevidence-compatible evidence is not automatically:

- regulator-approved;
- scientifically valid;
- a carbon credit;
- externally verified;
- owned by a claimant;
- relied upon by an institution.

Those are interpretation, verification, claim, or reliance states that must be
issued separately.

