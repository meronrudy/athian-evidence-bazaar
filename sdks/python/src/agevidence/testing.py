"""Test helpers for projects adopting AgEvidence primitives."""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from .primitives import EvidencePrimitive
from .provenance import check


def assert_evidence_valid(value: EvidencePrimitive | dict[str, Any]) -> None:
    """Assert that a primitive is structurally valid."""

    report = check(value)
    assert report.structural_validity == "pass", report.model_dump(mode="json")


def assert_provenance_complete(value: EvidencePrimitive | dict[str, Any]) -> None:
    """Assert that a primitive has complete local provenance."""

    report = check(value)
    assert report.complete, report.model_dump(mode="json")


def assert_rust_conformant(value: EvidencePrimitive | dict[str, Any], *, schema: str | None = None, command: str | None = None) -> None:
    """Assert that Rust `baink-agevidence` accepts the normalized payload."""

    payload = value.to_payload() if isinstance(value, EvidencePrimitive) else value
    schema_name = schema or _schema_name(str(payload.get("primitive_type") or value.__class__.__name__))
    executable = command or os.environ.get("AGEVIDENCE_VERIFIER_COMMAND") or str(Path("target/debug/baink-cli"))
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as file:
        json.dump(payload, file)
        path = Path(file.name)
    try:
        completed = subprocess.run(
            shlex.split(executable) + ["agevidence", "validate", "--schema", schema_name, str(path)],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        path.unlink(missing_ok=True)
    assert completed.returncode == 0, completed.stderr or completed.stdout


def _schema_name(primitive_type: str) -> str:
    return {
        "SourceRecord": "source_record",
        "Observation": "observation",
        "SpatialObservation": "spatial_observation",
        "InterventionEvent": "intervention_event",
        "OperationalEvent": "operational_event",
        "ModelRun": "model_run",
        "ModelExecution": "model_execution",
    }.get(primitive_type, primitive_type)
