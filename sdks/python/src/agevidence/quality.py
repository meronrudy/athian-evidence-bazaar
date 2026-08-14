"""Deterministic evidence quality dimensions."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict

from agevidence.provenance import check


class EvidenceQuality(BaseModel):
    """Actionable local evidence quality dimensions."""

    model_config = ConfigDict(extra="forbid")

    completeness: float
    provenance: float
    identity_binding: float
    temporal_continuity: float
    calibration: float
    lineage: float


def quality(value: Any) -> EvidenceQuality:
    """Compute deterministic quality dimensions for local evidence."""

    payloads = _payloads(value)
    if not payloads:
        return EvidenceQuality(completeness=0, provenance=0, identity_binding=0, temporal_continuity=0, calibration=0, lineage=0)
    reports = [check(payload) for payload in payloads]
    completeness = sum(1 for report in reports if report.structural_validity == "pass") / len(reports)
    provenance = sum(report.score for report in reports) / (100 * len(reports))
    identity = sum(1 for payload in payloads if _identity_present(payload)) / len(payloads)
    temporal = sum(1 for payload in payloads if _timestamp_present(payload)) / len(payloads)
    calibration = sum(1 for payload in payloads if _calibration_present(payload)) / len(payloads)
    lineage = sum(1 for payload in payloads if payload.get("source_records") or payload.get("inputs") or payload.get("input_commitments")) / len(payloads)
    return EvidenceQuality(
        completeness=round(completeness, 4),
        provenance=round(provenance, 4),
        identity_binding=round(identity, 4),
        temporal_continuity=round(temporal, 4),
        calibration=round(calibration, 4),
        lineage=round(lineage, 4),
    )


def _payloads(value: Any) -> list[dict[str, Any]]:
    from agevidence.primitives import EvidencePrimitive

    if hasattr(value, "to_primitives"):
        return list(value.to_primitives())
    if hasattr(value, "primitive"):
        return [dict(value.primitive)]
    if isinstance(value, EvidencePrimitive):
        return [value.to_payload()]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, list):
        return [item.to_payload() if isinstance(item, EvidencePrimitive) else dict(item) for item in value]
    return []


def _identity_present(payload: dict[str, Any]) -> bool:
    return bool(payload.get("subject") or payload.get("target") or payload.get("machine") or payload.get("asset"))


def _timestamp_present(payload: dict[str, Any]) -> bool:
    return any(payload.get(key) for key in ["observed_at", "occurred_at", "effective_at", "recorded_at", "received_at", "started_at"])


def _calibration_present(payload: dict[str, Any]) -> bool:
    instrument = payload.get("instrument")
    if isinstance(instrument, dict):
        return bool(instrument.get("calibration_reference"))
    return payload.get("primitive_type") not in {"Observation", "SpatialObservation"}
