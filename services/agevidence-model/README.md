# Athian AgEvidence Model Service

This service exposes the model-runtime side of the AgEvidence scaffold.

The default mode is `fixture`, which returns a deterministic normalized fixture response for the synthetic Northstar Methane Systems story. Production adapters can replace the fixture adapter without changing the response contract or receipt schemas.

## Run

```bash
cd services/agevidence-model
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e ".[test]"
uvicorn athian_agevidence.api:app --reload
```

## Runtime modes

- `AGEVIDENCE_MODE=fixture`: CI-safe default. No model download.
- `AGEVIDENCE_MODE=local`: call an OpenAI-compatible local endpoint via `AGEVIDENCE_LOCAL_BASE_URL`.
- `AGEVIDENCE_MODE=remote`: disabled unless `AGEVIDENCE_REMOTE_DATA_HANDLING=explicit`.

The service extracts candidate evidence and gaps only. It never signs receipts, certifies reductions, approves protocols, or writes to the Rails database.
