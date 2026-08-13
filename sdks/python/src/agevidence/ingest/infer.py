"""Local ingest entry point."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict

from agevidence.primitives import EvidencePrimitive
from agevidence.provenance import ProvenanceReport, check

from .mappings import CandidateMapping, build_primitive, candidate_mappings


class IngestResult(BaseModel):
    """Result from deterministic local ingest."""

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    confidence: str
    primitive: dict[str, Any]
    provenance: ProvenanceReport
    candidates: list[CandidateMapping]
    local_digest: str
    committed: bool = False


def ingest(record: dict[str, Any] | str | Path, primitive: str = "auto") -> IngestResult:
    """Infer and normalize a native object into a local evidence primitive."""

    payload = _load(record)
    candidates = candidate_mappings(payload)
    if primitive == "auto":
        if not candidates:
            raise ValueError("No primitive mapping matched this payload.")
        selected = candidates[0]
        primitive_type = selected.primitive_type
        confidence = selected.confidence
    else:
        primitive_type = primitive
        confidence = "explicit"
    primitive_obj = build_primitive(payload, primitive_type)
    report = check(primitive_obj)
    return IngestResult(
        primitive_type=primitive_type,
        confidence=confidence,
        primitive=primitive_obj.to_payload(),
        provenance=report,
        candidates=candidates,
        local_digest=primitive_obj.local_digest() if isinstance(primitive_obj, EvidencePrimitive) else "",
        committed=False,
    )


def _load(record: dict[str, Any] | str | Path) -> dict[str, Any]:
    if isinstance(record, dict):
        return record
    path = Path(record)
    return json.loads(path.read_text(encoding="utf-8"))
