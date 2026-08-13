from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

from agevidence.provenance import check


GOLDEN = Path(__file__).resolve().parent / "fixtures" / "golden"


def rust_validate(schema: str, payload: dict) -> bool:
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
        json.dump(payload, file)
        path = Path(file.name)
    try:
        completed = subprocess.run(
            ["cargo", "run", "--quiet", "-p", "baink-cli", "--", "agevidence", "validate", "--schema", schema, str(path)],
            cwd=Path(__file__).resolve().parents[3],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        path.unlink(missing_ok=True)
    return completed.returncode == 0


def load_fixture(name: str) -> dict:
    return json.loads((GOLDEN / name).read_text(encoding="utf-8"))


def test_valid_golden_fixtures_pass_python_and_rust():
    for name in [
        "observation_liveweight_v1.json",
        "observation_methane_v1.json",
        "intervention_feed_additive_v1.json",
        "model_run_spatial_v1.json",
        "model_run_neutral_v1.json",
        "operational_event_spot_spray_v1.json",
    ]:
        fixture = load_fixture(name)
        report = check(fixture["payload"])

        assert fixture["valid"] is True
        assert report.structural_validity == "pass"
        assert rust_validate(fixture["schema"], fixture["payload"])


def test_malformed_golden_fixtures_fail_python_and_rust():
    for name in [
        "observation_missing_unit.json",
        "observation_missing_timestamp.json",
        "model_run_missing_version.json",
        "model_run_neutral_missing_version.json",
        "intervention_missing_target.json",
    ]:
        fixture = load_fixture(name)
        report = check(fixture["payload"])

        assert fixture["valid"] is False
        assert report.structural_validity == "fail"
        assert not rust_validate(fixture["schema"], fixture["payload"])
