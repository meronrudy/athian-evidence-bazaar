"""Local first-run demo."""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict

from .fixtures import load_fixture
from .ingest import ingest


class DemoResult(BaseModel):
    """Machine-readable local demo result."""

    model_config = ConfigDict(extra="forbid")

    fixture: str
    primitive_type: str
    provenance_score: int
    structural_validity: str
    provenance_completeness: str
    rust_validation: str
    rust_stdout: str = ""
    no_account_used: bool = True
    no_api_key_used: bool = True
    no_network_request_used: bool = True


def run_demo(name: str = "livestock-weight") -> DemoResult:
    """Run a deterministic local demo without Rails, credentials, or network."""

    fixture = load_fixture(name)
    result = ingest(fixture.payload, primitive=fixture.primitive_type)
    rust_status, rust_stdout = _run_rust_validation(result.primitive_type, result.primitive)
    return DemoResult(
        fixture=name,
        primitive_type=result.primitive_type,
        provenance_score=result.provenance.score,
        structural_validity=result.provenance.structural_validity,
        provenance_completeness=result.provenance.provenance_completeness,
        rust_validation=rust_status,
        rust_stdout=rust_stdout,
    )


def _run_rust_validation(primitive_type: str, payload: dict[str, Any]) -> tuple[str, str]:
    command = _rust_command()
    if command is None:
        return ("not_configured", "")
    schema = _schema_name(primitive_type)
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
        json.dump(payload, file)
        path = Path(file.name)
    try:
        completed = subprocess.run(
            command + ["agevidence", "validate", "--schema", schema, str(path)],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        path.unlink(missing_ok=True)
    if completed.returncode == 0:
        return ("pass", completed.stdout)
    return ("fail", completed.stderr or completed.stdout)


def _rust_command() -> list[str] | None:
    configured = os.environ.get("AGEVIDENCE_VERIFIER_COMMAND")
    if configured:
        return shlex.split(configured)
    cwd_candidate = Path.cwd() / "target" / "debug" / "baink-cli"
    if cwd_candidate.exists():
        return [str(cwd_candidate)]
    package_candidate = Path(__file__).resolve().parents[4] / "target" / "debug" / "baink-cli"
    if package_candidate.exists():
        return [str(package_candidate)]
    return None


def _schema_name(primitive_type: str) -> str:
    return {
        "SourceRecord": "source_record",
        "Observation": "observation",
        "SpatialObservation": "spatial_observation",
        "InterventionEvent": "intervention_event",
        "OperationalEvent": "operational_event",
        "ModelRun": "model_run",
        "ModelExecution": "model_execution",
        "CalibrationRecord": "calibration_record",
        "ProductLot": "product_lot",
        "AssetState": "asset_state",
        "DerivedObservation": "derived_observation",
        "Transformation": "transformation",
        "Attachment": "attachment",
        "ExternalObject": "external_object",
    }.get(primitive_type, primitive_type)
