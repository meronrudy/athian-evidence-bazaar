"""Deterministic primitive inference rules."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict

from agevidence.primitives import (
    InterventionEvent,
    ModelRun,
    Observation,
    OperationalEvent,
    SourceRecord,
    SpatialObservation,
)


class CandidateMapping(BaseModel):
    """A candidate primitive mapping produced by deterministic rules."""

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    confidence: str
    score: int
    matched_fields: list[str]


def candidate_mappings(payload: dict[str, Any]) -> list[CandidateMapping]:
    """Return possible primitive mappings ordered by confidence."""

    candidates = [
        _candidate(payload, "SpatialObservation", ["geometry", "observable", "value", "unit", "observed_at"], anchors=[["geometry"]]),
        _candidate(payload, "ModelRun", ["model_id", "model_version", "inputs", "outputs"], anchors=[["model_id", "base_model_id"]]),
        _candidate(payload, "InterventionEvent", ["target", "intervention", "quantity", "unit", "occurred_at"], anchors=[["intervention", "product", "intervention_type"]]),
        _candidate(payload, "OperationalEvent", ["machine", "operation", "started_at", "completed_at"], anchors=[["machine", "machine_id", "vehicle"]]),
        _candidate(
            payload,
            "Observation",
            ["subject", "observable", "value", "unit", "observed_at"],
            aliases={"subject": ["subject", "subject_id", "animal_id", "target"], "observed_at": ["observed_at", "measured_at", "timestamp"]},
        ),
        _candidate(payload, "SourceRecord", ["source_system", "record_id", "observed_at"], aliases={"record_id": ["record_id", "document_id", "id"]}),
    ]
    filtered = [candidate for candidate in candidates if candidate.score > 0]
    return sorted(filtered, key=lambda item: item.score, reverse=True)


def build_primitive(payload: dict[str, Any], primitive_type: str):
    """Build a primitive from a native JSON payload using known aliases."""

    if primitive_type == "SourceRecord":
        return SourceRecord(
            source_system=_first(payload, "source_system", "system", default="unknown"),
            record_id=_first(payload, "record_id", "document_id", "id"),
            observed_at=_first(payload, "observed_at", "recorded_at", "timestamp", "measured_at"),
            controlled_uri=payload.get("controlled_uri"),
            commitment=payload.get("commitment"),
            metadata=_metadata(payload),
        )
    if primitive_type == "Observation":
        return Observation(
            subject=_first(payload, "subject", "subject_id", "animal_id", "target"),
            observable=_first(payload, "observable", "measurement", "metric", "type", default="measurement"),
            value=_first(payload, "value", "measurement_value"),
            unit=_first(payload, "unit", "uom"),
            observed_at=_first(payload, "observed_at", "measured_at", "timestamp", "occurred_at"),
            instrument=payload.get("instrument"),
            method=payload.get("method"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "SpatialObservation":
        return SpatialObservation(
            geometry=payload["geometry"],
            observable=_first(payload, "observable", "measurement", "metric", default="spatial_measurement"),
            value=_first(payload, "value", "measurement_value"),
            unit=_first(payload, "unit", "uom"),
            observed_at=_first(payload, "observed_at", "measured_at", "timestamp"),
            crs=_first(payload, "crs", "coordinate_reference_system", default="EPSG:4326"),
            subject=payload.get("subject"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "InterventionEvent":
        return InterventionEvent(
            target=_first(payload, "target", "subject", "herd", "asset"),
            intervention=_first(payload, "intervention", "product", "intervention_type"),
            quantity=_first(payload, "quantity", "dose", "amount"),
            unit=_first(payload, "unit", "uom"),
            occurred_at=_first(payload, "occurred_at", "timestamp", "applied_at"),
            batch=_first(payload, "batch", "lot", "product_batch", default=None),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "OperationalEvent":
        return OperationalEvent(
            machine=_first(payload, "machine", "machine_id", "vehicle", "asset"),
            operation=_first(payload, "operation", "operation_type", "activity"),
            started_at=_first(payload, "started_at", "start_time", "timestamp"),
            completed_at=_first(payload, "completed_at", "end_time", "finished_at"),
            location=payload.get("location"),
            source_records=_source_records(payload),
            metadata=_metadata(payload),
        )
    if primitive_type == "ModelRun":
        return ModelRun(
            model_id=_first(payload, "model_id", "base_model_id"),
            model_version=_first(payload, "model_version", "version", default="unknown"),
            implementation_digest=_first(payload, "implementation_digest", "weights_digest", default=None),
            input_commitments=list(payload.get("input_commitments") or payload.get("source_document_commitments") or []),
            parameters=dict(payload.get("parameters") or payload.get("generation_config") or {}),
            execution_environment=dict(payload.get("execution_environment") or ({"runtime": payload["runtime"]} if payload.get("runtime") else {})),
            started_at=_first(payload, "started_at", "executed_at", "execution_timestamp", "timestamp", default=None),
            completed_at=_first(payload, "completed_at", "executed_at", "execution_timestamp", "timestamp", default=None),
            inputs=list(payload.get("inputs", [])),
            outputs=list(payload.get("outputs", [])),
            executed_at=_first(payload, "executed_at", "execution_timestamp", "timestamp", default=None),
            weights_digest=payload.get("weights_digest"),
            adapter_id=payload.get("adapter_id"),
            adapter_digest=payload.get("adapter_digest"),
            model_license=payload.get("model_license"),
            runtime=payload.get("runtime"),
            generation_config=dict(payload.get("generation_config", {})),
            system_prompt_digest=payload.get("system_prompt_digest"),
            retrieval_corpus_digest=payload.get("retrieval_corpus_digest"),
            source_document_commitments=list(payload.get("source_document_commitments", [])),
            normalized_output_digest=payload.get("normalized_output_digest"),
            policy_version=payload.get("policy_version"),
            issuer=payload.get("issuer"),
            signer=payload.get("signer"),
            verification=dict(payload.get("verification") or {}),
            limitations=list(payload.get("limitations", [])),
            metadata=_metadata(payload),
        )
    raise ValueError(f"Unknown primitive type: {primitive_type}")


def _candidate(
    payload: dict[str, Any],
    primitive_type: str,
    fields: list[str],
    *,
    anchors: list[list[str]] | None = None,
    aliases: dict[str, list[str]] | None = None,
) -> CandidateMapping:
    for anchor_group in anchors or []:
        if not any(_present(payload.get(field)) for field in anchor_group):
            return CandidateMapping(primitive_type=primitive_type, confidence="low", score=0, matched_fields=[])
    matched = [field for field in fields if _field_present(payload, field, aliases or {})]
    score = int((len(matched) / len(fields)) * 100)
    confidence = "high" if score >= 80 else "medium" if score >= 50 else "low"
    return CandidateMapping(primitive_type=primitive_type, confidence=confidence, score=score, matched_fields=matched)


def _field_present(payload: dict[str, Any], field: str, aliases: dict[str, list[str]]) -> bool:
    keys = aliases.get(field, [field])
    return any(_present(payload.get(key)) for key in keys)


def _source_records(payload: dict[str, Any]) -> list[SourceRecord]:
    records = payload.get("source_records") or []
    return [record if isinstance(record, SourceRecord) else SourceRecord.model_validate(record) for record in records]


def _metadata(payload: dict[str, Any]) -> dict[str, Any]:
    metadata = dict(payload.get("metadata") or {})
    metadata.setdefault("native", payload)
    return metadata


def _first(payload: dict[str, Any], *keys: str, default: Any = ...):
    for key in keys:
        value = payload.get(key)
        if _present(value):
            return value
    if default is not ...:
        return default
    return None


def _present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value)
    if isinstance(value, (list, dict)):
        return bool(value)
    return True
