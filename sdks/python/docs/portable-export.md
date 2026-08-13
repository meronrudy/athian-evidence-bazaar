# Portable Evidence Export

`agevidence export RECORD.json` emits a local envelope with:

- `contract_version`: `athian.agevidence.export.v1`
- `schema_id` and `primitive_type`
- canonical primitive `payload`
- deterministic local `local_digest`
- local provenance report
- lineage edges, when supplied by future callers
- `requires_hosted_agevidence: false`

The export is intentionally not a program determination, certification, claim allocation, or institutional reliance artifact. Those are versioned interpretations above the evidence waist.

The envelope can be generated from a native source record through local ingest, or from an already-normalized primitive payload. It must not require `api.agevidence.com`, Rails, a database, or an Agevidence API key.
