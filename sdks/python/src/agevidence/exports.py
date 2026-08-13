"""Portable local evidence export helpers."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.ingest import ingest
from agevidence.primitives import EvidencePrimitive, local_digest
from agevidence.provenance import LineageEdge, ProvenanceReport, check


ARTIFACT_EXPORT_NOTICE = "Artifact exports should include verification commands and declared limitations."


class PortableEvidenceExport(BaseModel):
    """Hosted-service-independent export envelope."""

    model_config = ConfigDict(extra="forbid")

    contract_version: Literal["athian.agevidence.export.v1"] = "athian.agevidence.export.v1"
    schema_id: str | None
    primitive_type: str
    payload: dict[str, Any]
    local_digest: str
    provenance: ProvenanceReport
    lineage: list[LineageEdge] = Field(default_factory=list)
    requires_hosted_agevidence: Literal[False] = False
    authority_boundary: str = (
        "This export preserves local evidence structure and provenance. It does not establish "
        "program eligibility, external verification, claim ownership, or institutional reliance."
    )


def export_evidence(value: EvidencePrimitive | dict[str, Any] | str | Path, *, primitive: str = "auto") -> PortableEvidenceExport:
    """Create a portable export envelope without hosted Agevidence services."""

    payload = _payload(value, primitive=primitive)
    report = check(payload)
    return PortableEvidenceExport(
        schema_id=payload.get("schema_id"),
        primitive_type=report.primitive_type,
        payload=payload,
        local_digest=local_digest(payload),
        provenance=report,
    )


def _payload(value: EvidencePrimitive | dict[str, Any] | str | Path, *, primitive: str) -> dict[str, Any]:
    if isinstance(value, EvidencePrimitive):
        return value.to_payload()
    if isinstance(value, dict):
        if value.get("primitive_type") or value.get("schema_id"):
            return value
        return ingest(value, primitive=primitive).primitive
    path = Path(value)
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, dict) and (raw.get("primitive_type") or raw.get("schema_id")):
        return raw
    return ingest(raw, primitive=primitive).primitive
