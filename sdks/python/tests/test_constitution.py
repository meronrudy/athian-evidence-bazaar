from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from typer.testing import CliRunner

from agevidence.cli import app
from agevidence.exports import export_evidence
from agevidence.ingest import ingest


REPO_ROOT = Path(__file__).resolve().parents[3]
SDK_ROOT = REPO_ROOT / "sdks" / "python"
CORE_SCHEMA_STEMS = [
    "asset_state",
    "attachment",
    "calibration_record",
    "derived_observation",
    "external_object",
    "source_record",
    "observation",
    "intervention_event",
    "operational_event",
    "spatial_observation",
    "model_run",
    "product_lot",
    "transformation",
]


def test_import_agevidence_does_not_eagerly_import_hosted_layers():
    code = """
import sys
import agevidence
forbidden = ['httpx', 'agevidence.client', 'agevidence.async_client', 'agevidence.campaign']
loaded = [name for name in forbidden if name in sys.modules]
raise SystemExit(1 if loaded else 0)
"""
    result = subprocess.run(
        [sys.executable, "-c", code],
        cwd=REPO_ROOT,
        env={"PYTHONPATH": str(SDK_ROOT / "src")},
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr or result.stdout


def test_packaged_core_schemas_mirror_spec_authority():
    for stem in CORE_SCHEMA_STEMS:
        spec = REPO_ROOT / "specs" / "agevidence" / "schemas" / f"athian.agevidence.{stem}.v1.json"
        packaged = SDK_ROOT / "src" / "agevidence" / "schemas" / spec.name

        assert packaged.read_text(encoding="utf-8") == spec.read_text(encoding="utf-8")


def test_portable_export_requires_no_hosted_agevidence():
    fixture = json.loads((SDK_ROOT / "src" / "agevidence" / "fixtures" / "data" / "livestock-weight.json").read_text(encoding="utf-8"))
    exported = export_evidence(fixture["payload"], primitive=fixture["primitive_type"])

    assert exported.requires_hosted_agevidence is False
    assert exported.contract_version == "athian.agevidence.export.v1"
    assert exported.primitive_type == "Observation"
    assert exported.local_digest.startswith("sha256:")
    assert exported.provenance.program_eligibility == "not_evaluated"
    assert exported.model_dump(mode="json")["requires_hosted_agevidence"] is False


def test_cli_export_emits_portable_envelope(tmp_path):
    runner = CliRunner()
    fixture_path = tmp_path / "weight.json"
    fixture = json.loads((SDK_ROOT / "src" / "agevidence" / "fixtures" / "data" / "livestock-weight.json").read_text(encoding="utf-8"))
    fixture_path.write_text(json.dumps(fixture["payload"]), encoding="utf-8")

    result = runner.invoke(app, ["export", str(fixture_path)])

    assert result.exit_code == 0
    assert '"requires_hosted_agevidence": false' in result.stdout
    assert '"contract_version": "athian.agevidence.export.v1"' in result.stdout


def test_wave_adversary_fixtures_reuse_core_primitives():
    cases = json.loads((Path(__file__).resolve().parent / "fixtures" / "wave_adversaries" / "cases.json").read_text(encoding="utf-8"))
    allowed_by_type = {
        "Observation": {"schema_id", "primitive_type", "subject", "observable", "value", "unit", "observed_at", "instrument", "method", "source_records", "metadata", "limitations"},
        "SpatialObservation": {"schema_id", "primitive_type", "geometry", "observable", "value", "unit", "observed_at", "crs", "subject", "source_records", "metadata", "limitations"},
        "InterventionEvent": {"schema_id", "primitive_type", "target", "intervention", "quantity", "unit", "occurred_at", "batch", "source_records", "metadata", "limitations"},
        "OperationalEvent": {"schema_id", "primitive_type", "machine", "operation", "started_at", "completed_at", "location", "source_records", "metadata", "limitations"},
        "ModelRun": {"schema_id", "primitive_type", "model_id", "model_version", "implementation_digest", "input_commitments", "parameters", "execution_environment", "started_at", "completed_at", "outputs", "limitations", "verification", "metadata"},
        "SourceRecord": {"schema_id", "primitive_type", "source_system", "record_id", "observed_at", "controlled_uri", "commitment", "metadata", "limitations"},
    }

    assert {case["company"] for case in cases} == {
        "DIT AgTech",
        "MEQ Solutions",
        "Agscent",
        "Cibo Labs",
        "Agronomeye",
        "Rumin8",
        "Sea Forest",
        "SwarmFarm Robotics",
    }
    for case in cases:
        result = ingest(case["payload"], primitive=case["primitive_type"])
        primitive_keys = set(result.primitive)

        assert result.primitive_type == case["primitive_type"]
        assert primitive_keys <= allowed_by_type[result.primitive_type]
