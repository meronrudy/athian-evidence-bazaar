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


def assert_mapping_complete(result: Any) -> None:
    """Assert that all required canonical fields were mapped."""

    mapping = getattr(result, "mapping", None)
    assert mapping is not None, "Expected an ingest result with a mapping report."
    missing = [item.canonical_field for item in mapping.field_mappings if item.required and not item.matched]
    assert not missing, {"missing": missing, "mapping": mapping.model_dump(mode="json")}


def assert_no_silent_field_loss(report_or_result: Any) -> None:
    """Assert that source fields were mapped, preserved, or explicitly ignored."""

    if hasattr(report_or_result, "silently_lost_count"):
        assert report_or_result.silently_lost_count == 0, report_or_result.model_dump(mode="json")
        return
    mapping = getattr(report_or_result, "mapping", None)
    assert mapping is not None, "Expected an adapter coverage report or ingest result."
    if hasattr(mapping, "silently_lost_fields"):
        assert not mapping.silently_lost_fields, mapping.model_dump(mode="json")
        return
    assert not mapping.unmapped_fields or mapping.extension_preserved_fields, mapping.model_dump(mode="json")


def assert_deterministic(value: EvidencePrimitive | dict[str, Any]) -> None:
    """Assert deterministic normalized JSON and local digest stability."""

    payload = value.to_payload() if isinstance(value, EvidencePrimitive) else value
    first = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    second = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    assert first == second


def assert_lineage_complete(graph: Any) -> None:
    """Assert a local lineage graph has no missing node references."""

    errors = graph.validate()
    assert not errors, errors


def assert_sequence_contiguous(values: Any) -> None:
    """Assert no deterministic sequence gaps are present."""

    from agevidence.series import series

    evidence_series = series(values)
    assert not evidence_series.find_sequence_gaps(), evidence_series.find_sequence_gaps()


def assert_profile_compatible(value: Any, profile: str) -> None:
    """Assert local evidence is compatible with a profile."""

    from agevidence.assessment import assess

    result = assess(value, profile)
    assert result.complete, result.model_dump(mode="json")


def assert_bundle_verifies(bundle: Any, *, path: str | Path | None = None) -> None:
    """Assert a bundle verifies through the Rust verifier facade."""

    result = bundle.verify(path) if hasattr(bundle, "verify") else None
    assert result is not None
    assert getattr(result, "returncode", None) == 0, result.model_dump(mode="json")


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
