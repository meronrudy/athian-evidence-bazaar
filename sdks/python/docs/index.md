# Agevidence Python SDK

Portable evidence primitives for agricultural software.

Agevidence helps developers turn native operational records into structured,
provenance-bearing evidence that can be inspected, verified locally, replayed,
and interpreted by downstream systems.

```bash
pip install agevidence
agevidence demo
```

No account required for local use.

## Start Here

1. [Quickstart](quickstart.md)
2. [Evidence vs. Interpretation](concepts/evidence-vs-interpretation.md)
3. [Primitives](concepts/primitives.md)
4. [Provenance](concepts/provenance.md)
5. [Local-first and Portable](concepts/local-first-portable.md)
6. [Trust Boundary](concepts/trust-boundary.md)
7. [Design Principles](concepts/design-principles.md)

## Developer Path

Local evidence:

- [Ingest native JSON](guides/ingest-native-json.md)
- [Build an observation](guides/build-observation.md)
- [Build an intervention event](guides/build-intervention-event.md)
- [Record a model run](guides/record-model-run.md)
- [Build a source adapter](guides/build-source-adapter.md)

Provenance and verification:

- [Check provenance](guides/check-provenance.md)
- [Verify locally](guides/verify-locally.md)
- [Use in CI](guides/use-in-ci.md)

Reference:

- [Python API](reference/python-api.md)
- [CLI](reference/cli.md)
- [Schemas](reference/schemas.md)
- [Compatibility](reference/compatibility.md)
- [Conformance](reference/conformance.md)

Optional hosted services:

- [Hosted overview](hosted/overview.md)
- [Hosted client](hosted/client.md)
- [Projects](hosted/projects.md)
- [Institutional services](hosted/institutional-services.md)

## What Agevidence Does Not Assert

Local SDK validation does not establish regulatory eligibility, scientific
validity, carbon-credit issuance, third-party verification, claim ownership, or
institutional reliance.

It checks the structure, provenance, lineage, deterministic representation, and
Agevidence contract compatibility of evidence.

