# Agevidence Python SDK v1.0.0 Post-publish Checklist

Use this checklist immediately after `sdk-python-v1.0.0` publishes to PyPI.

## PyPI Install

- [ ] Create a fresh virtual environment.
- [ ] Run `python -m pip install --upgrade pip`.
- [ ] Run `python -m pip install agevidence==1.0.0`.
- [ ] Run:

```bash
python - <<'PY'
import agevidence
assert agevidence.__version__ == "1.0.0"
print(agevidence.__version__)
PY
```

## Local-first CLI

- [ ] Run `agevidence --help`.
- [ ] Run `agevidence demo`.
- [ ] Run `agevidence doctor`.
- [ ] Run `agevidence fixture write livestock-weight --out /tmp/agevidence-v1-fixture.json`.
- [ ] Run `agevidence ingest /tmp/agevidence-v1-fixture.json --format table`.
- [ ] Run `agevidence explain /tmp/agevidence-v1-fixture.json --format table`.

## Source Adapter Smoke

Create `/tmp/agevidence-v1-adapter.py`:

```python
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
```

Create `/tmp/agevidence-v1-fixtures/one.json`:

```json
{"eid":"A-1","ppm":18.7,"timestamp":"2026-08-12T15:10:00Z"}
```

- [ ] Run `agevidence adapter test /tmp/agevidence-v1-adapter.py /tmp/agevidence-v1-fixtures`.

## Public Pages

- [ ] Confirm the PyPI page renders the local-first README.
- [ ] Confirm GitHub release notes include the authority boundary.
- [ ] Confirm GitHub release notes include the Rust trust boundary.
- [ ] Confirm release artifacts are attached to the GitHub draft release.
- [ ] Confirm no obsolete `0.2.0a1` artifacts appear on the v1 release.

## Follow-up

- [ ] Open a post-release issue for non-blocking defects.
- [ ] If PyPI publish fails after files are uploaded, do not replace files; patch forward with a new version.
- [ ] If a bad release is published, yank `1.0.0`, leave the tag for auditability, and patch forward.

