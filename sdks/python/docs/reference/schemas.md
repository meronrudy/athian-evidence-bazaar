# Schemas

The Python package includes local primitive schemas under
`agevidence.schemas`. Repository schema sources live under
`specs/agevidence/schemas`.

Current local primitive schemas:

- `athian.agevidence.source_record.v1`
- `athian.agevidence.observation.v1`
- `athian.agevidence.spatial_observation.v1`
- `athian.agevidence.intervention_event.v1`
- `athian.agevidence.operational_event.v1`
- `athian.agevidence.model_run.v1`

The SDK also keeps compatibility projection support for older
`athian.agevidence.model_execution.v1` receipt payloads.

## Primitive Contract

Primitive schemas define evidence shape. They do not encode program eligibility,
scientific validity, carbon-credit issuance, third-party verification, claim
ownership, or institutional reliance.

## Source Adapters and Schemas

Source adapters should map native records into existing canonical primitives.
If `agevidence adapter test` reports that canonical schema extensions are
required, treat that as a protocol-design issue, not a routine mapper success.
