# Agevidence Python SDK v1.0.0 Release Notes

## Summary

`agevidence==1.0.0` is the first stable PyPI release of the Agevidence Python
SDK. It provides local-first evidence primitives, deterministic ingest,
provenance explanation, source-adapter testing, CI helpers, packaged schemas and
fixtures, delegated verifier integration, and optional hosted API clients.

## Stable v1 Surface

- `agevidence.primitives.SourceRecord`
- `agevidence.primitives.Observation`
- `agevidence.primitives.SpatialObservation`
- `agevidence.primitives.InterventionEvent`
- `agevidence.primitives.OperationalEvent`
- `agevidence.primitives.ModelRun`
- `agevidence.provenance.check`
- local primitive schemas packaged under `agevidence.schemas`
- local fixtures packaged under `agevidence.fixtures`
- CLI local developer path: `demo`, `doctor`, `fixture`, `ingest`, `explain`
- CI helpers in `agevidence.testing`

## Experimental v1 Surface

- `agevidence.ingest` deterministic inference rules
- `agevidence.adapters.Adapter`
- `agevidence adapter test`

These APIs are included for source-system mapping self-service. They may evolve
as additional source adapters are built.

## Profile-specific Surface

- `agevidence.adapters.CountryAdapter`
- built-in country/profile adapter commands
- identifier and source normalization commands

Country/profile adapter output is compatibility assessment only. It does not
mutate source evidence and does not establish approval, issuance, verification,
claim ownership, or institutional reliance.

## Hosted-only Surface

- `agevidence.Client`
- `agevidence.AsyncClient`
- hosted project, source, model, review, pricing, order, artifact, event,
  country/profile, and campaign workflow clients

Hosted clients are optional. Local primitives, ingest, provenance checks,
fixtures, adapter tests, and demos do not require hosted services.

## Trust Boundary

The Python SDK does not sign receipts, compute receipt commitments, implement
dCBOR, or verify bundles internally. Bundle verification is delegated to the
configured Rust verifier through `agevidence verify`.

## Authority Boundary

Local SDK `PASS` means structure, provenance, lineage, deterministic
representation, or contract compatibility. It does not establish regulatory
eligibility, scientific validity, carbon-credit issuance, third-party
verification, claim ownership, or institutional reliance.

## Known Limitations

- Hosted `Client` and `AsyncClient` require a compatible `/v1` Rails service.
- `agevidence verify` requires a configured Rust verifier command.
- Source adapter loading executes local Python code and should be used only with
  trusted adapter modules.
- Local checks are evidence-readiness checks only; they do not replace program,
  verifier, registry, buyer, insurer, or regulator decisions.

## Release Validation

Required validation before publishing:

```bash
python3 -m pytest sdks/python
cargo test --workspace
bash scripts/agevidence_check_all.sh
python3 scripts/check_sdk_release_readiness.py
```

Required package validation:

```bash
cd sdks/python
rm -rf dist build
python -m build
python -m twine check dist/*
```

Smoke-test both wheel and sdist from clean virtual environments before pushing
`sdk-python-v1.0.0`.

## Artifact Checksums

Clean local artifact rehearsal captured on 2026-08-13:

```text
SHA-256  agevidence-1.0.0-py3-none-any.whl  da55f643309f5262531b63c488ba8ebf5fbc2e813907b6e15e943c23786ee62b
SHA-256  agevidence-1.0.0.tar.gz           84c9d86e5dfd9a0c804ef166b493ac6ac07c70b4514475a9321d0faaf604b36b
```

Local validation captured on 2026-08-13:

- `python3 -m pytest sdks/python`: passed.
- `cargo test --workspace`: passed.
- `bash scripts/agevidence_check_all.sh`: passed.
- `python3 scripts/check_sdk_release_readiness.py`: passed.
- `python3 -m twine check sdks/python/dist/*`: passed.
- Clean wheel smoke install from `agevidence-1.0.0-py3-none-any.whl`: passed.
- Clean sdist smoke install from `agevidence-1.0.0.tar.gz`: passed.
