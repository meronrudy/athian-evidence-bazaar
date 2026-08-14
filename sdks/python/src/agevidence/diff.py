"""Semantic evidence diffs."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from agevidence.primitives import local_digest


class SemanticDiff(BaseModel):
    """Evidence-oriented diff summary."""

    model_config = ConfigDict(extra="forbid")

    source_evidence: str
    normalization: dict[str, dict[str, Any]] = Field(default_factory=dict)
    interpretation: str = "not_evaluated"
    provenance: str = "unchanged"
    model: dict[str, Any] = Field(default_factory=dict)


def diff(old: Any, new: Any) -> SemanticDiff:
    old_payload = _payload(old)
    new_payload = _payload(new)
    changes = {
        key: {"old": old_payload.get(key), "new": new_payload.get(key)}
        for key in sorted(set(old_payload) | set(new_payload))
        if old_payload.get(key) != new_payload.get(key)
    }
    source_evidence = "unchanged" if local_digest(_source_part(old_payload)) == local_digest(_source_part(new_payload)) else "changed"
    provenance = "unchanged" if old_payload.get("source_records") == new_payload.get("source_records") else "changed"
    model = {}
    if old_payload.get("primitive_type") == "ModelRun" or new_payload.get("primitive_type") == "ModelRun":
        model = {
            "model_id": {"old": old_payload.get("model_id"), "new": new_payload.get("model_id")},
            "model_version": {"old": old_payload.get("model_version"), "new": new_payload.get("model_version")},
            "outputs_changed": old_payload.get("outputs") != new_payload.get("outputs"),
        }
    return SemanticDiff(source_evidence=source_evidence, normalization=changes, provenance=provenance, model=model)


def _payload(value: Any) -> dict[str, Any]:
    if hasattr(value, "primitive"):
        return dict(value.primitive)
    if hasattr(value, "to_payload"):
        return value.to_payload()
    return dict(value)


def _source_part(payload: dict[str, Any]) -> dict[str, Any]:
    metadata = payload.get("metadata")
    if isinstance(metadata, dict) and isinstance(metadata.get("native"), dict):
        return metadata["native"]
    return {"source_records": payload.get("source_records")}
