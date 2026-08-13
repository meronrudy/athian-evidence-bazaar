# Releasing Agevidence Python SDK

## Product Identity

Product name: Agevidence  
PyPI distribution: `agevidence`  
Python namespace: `agevidence`  
CLI: `agevidence`  
Repository: `meronrudy/athian-evidence-bazaar`  
SDK location: `sdks/python`

## Versioning

The Python SDK version is defined in `sdks/python/pyproject.toml` and must match
`agevidence.__version__`. It is intentionally independent from Rust crate,
Rails, schema, and country-adapter versions.

Release tags use:

```text
sdk-python-v1.0.0
```

Pre-release tags may append the Python version suffix, for example
`sdk-python-v1.0.1rc1`.

## Build

From the repository root:

```bash
cd sdks/python
python -m pip install --upgrade build twine
python -m build
python -m twine check dist/*
```

The build must produce only:

```text
agevidence-<version>-py3-none-any.whl
agevidence-<version>.tar.gz
```

## Test

From the repository root:

```bash
python3 -m pytest sdks/python
cargo test --workspace
bash scripts/agevidence_check_all.sh
python3 scripts/check_sdk_release_readiness.py
```

## Wheel Smoke Test

```bash
rm -rf /tmp/agevidence-wheel-smoke
python -m venv /tmp/agevidence-wheel-smoke/venv
. /tmp/agevidence-wheel-smoke/venv/bin/activate
python -m pip install --upgrade pip
python -m pip install sdks/python/dist/*.whl
python - <<'PY'
import agevidence
print(agevidence.__version__)
PY
agevidence --help
agevidence demo
agevidence doctor
```

## Sdist Smoke Test

```bash
rm -rf /tmp/agevidence-sdist-smoke
python -m venv /tmp/agevidence-sdist-smoke/venv
. /tmp/agevidence-sdist-smoke/venv/bin/activate
python -m pip install --upgrade pip
python -m pip install sdks/python/dist/*.tar.gz
agevidence demo
agevidence doctor
```

## Adapter Smoke Test

Run this against an installed wheel before publishing:

```bash
tmpdir="$(mktemp -d)"
cat > "$tmpdir/my_adapter.py" <<'PY'
from agevidence.adapters import Adapter
from agevidence.primitives import Observation

class MyAdapter(Adapter):
    def map(self, record):
        return Observation(
            subject=f"animal:{record['eid']}",
            observable="methane",
            value=record["ppm"],
            unit="ppm",
            observed_at=record["timestamp"],
        )
PY
mkdir -p "$tmpdir/fixtures"
printf '{"eid":"A-1","ppm":18.7,"timestamp":"2026-08-12T15:10:00Z"}\n' > "$tmpdir/fixtures/one.json"
agevidence adapter test "$tmpdir/my_adapter.py" "$tmpdir/fixtures"
```

## TestPyPI Rehearsal

Use TestPyPI for release-process rehearsal when changing the release workflow:

1. Create a temporary pre-release version, for example `1.0.1rc1`.
2. Build wheel and sdist from `sdks/python`.
3. Publish to TestPyPI using trusted publishing or a short-lived manual token.
4. Install with:

```bash
python -m pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple agevidence==1.0.1rc1
```

5. Run the wheel smoke and adapter smoke checks.
6. Do not reuse the rehearsal version for production PyPI.

## Trusted Publisher

Publishing uses GitHub OIDC through the PyPI trusted-publisher flow. Do not add
or store a long-lived PyPI API token.

The PyPI project must trust:

```text
owner: meronrudy
repository: athian-evidence-bazaar
workflow: sdk-python-release.yml
environment: pypi
```

## Release Workflow

1. Update `sdks/python/pyproject.toml` and `agevidence.__version__`.
2. Run all tests and release-readiness checks locally.
3. Build wheel and sdist from `sdks/python`.
4. Run wheel and sdist smoke tests.
5. Push a tag named `sdk-python-v<version>`.
6. Confirm the GitHub Actions release workflow creates a draft release and
   publishes to PyPI from the `pypi` environment.

## Post-publish Verification

After PyPI publish, follow
`../../docs/releases/v1.0.0/POST_PUBLISH_CHECKLIST.md` from a fresh environment.

## Rollback

PyPI files cannot be replaced. If a bad release is published:

1. Yank the affected version on PyPI.
2. Leave the Git tag in place for auditability.
3. Patch forward with a new version.
4. Document the reason in the GitHub release notes.
