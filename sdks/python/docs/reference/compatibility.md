# Compatibility

Agevidence is currently alpha. Treat API surfaces by their boundary.

## Stable Contract Candidates

- `agevidence.primitives.SourceRecord`
- `agevidence.primitives.Observation`
- `agevidence.primitives.SpatialObservation`
- `agevidence.primitives.InterventionEvent`
- `agevidence.primitives.OperationalEvent`
- `agevidence.primitives.ModelRun`
- `agevidence.provenance.check`
- local primitive JSON schemas

These are the center of the SDK.

## Experimental

- `agevidence.adapters.Adapter`
- `agevidence adapter test`
- deterministic ingest inference rules in `agevidence.ingest`

These APIs are intended for source-system mapping and developer self-service.
They may evolve as more adapters are built.

## Profile-specific

- `agevidence.adapters.CountryAdapter`
- `agevidence.countries.*`
- country source normalization;
- country/profile evaluation;
- profile-specific identifiers and source checks.

These interpret evidence under profile or country context. They should not
mutate the original evidence.

## Hosted-only

- `agevidence.Client`
- `agevidence.AsyncClient`
- project/source/model/review/order/artifact hosted workflows.

Hosted clients are optional. Local primitives, ingest, provenance checks, source
adapter tests, fixtures, and demos do not require hosted services.

## Authority Boundary

Compatibility does not mean approval. Local checks do not establish regulatory
eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.

