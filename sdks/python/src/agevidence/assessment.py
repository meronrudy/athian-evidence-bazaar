"""Local evidence suitability assessments."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from agevidence.findings import Finding


AUTHORITY_BOUNDARY = (
    "Local assessments report evidence suitability only. They do not establish "
    "regulatory eligibility, scientific validity, issuance, or institutional reliance."
)


class Assessment(BaseModel):
    """Profile assessment over one or more local evidence primitives."""

    model_config = ConfigDict(extra="forbid")

    profile: str
    complete: bool
    coverage: float
    required: list[str] = Field(default_factory=list)
    present: list[str] = Field(default_factory=list)
    missing: list[str] = Field(default_factory=list)
    findings: list[Finding] = Field(default_factory=list)
    primitive_count: int = 0
    authority_boundary: str = AUTHORITY_BOUNDARY

    def explain(self) -> str:
        status = "complete" if self.complete else "incomplete"
        return f"{self.profile}: {status}; {len(self.present)}/{len(self.required)} requirements present."


def assess(value: Any, profile: str) -> Assessment:
    """Assess primitive payloads against a local domain profile."""

    from agevidence.profiles import get_domain_profile

    profile_obj = get_domain_profile(profile)
    primitives = _payloads(value)
    required = list(dict.fromkeys([*profile_obj.metadata.input_requirements, *profile_obj.metadata.provenance_requirements]))
    present = sorted({path for primitive in primitives for path in required if _path_present(primitive, path)})
    missing = [path for path in required if path not in present]
    findings = [
        Finding(
            code="assessment.requirement_missing",
            severity="warning",
            path=path,
            message=f"Profile requirement is missing: {path}.",
            source="assessment",
            remediation={"action": "supply_evidence", "path": path},
        )
        for path in missing
    ]
    coverage = 1.0 if not required else round(len(present) / len(required), 4)
    return Assessment(
        profile=profile_obj.metadata.profile_id,
        complete=not missing,
        coverage=coverage,
        required=required,
        present=present,
        missing=missing,
        findings=findings,
        primitive_count=len(primitives),
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
    raise TypeError("Assessment expects a primitive, ingest result, frame, bundle, dataset, or list of primitives.")


def _path_present(payload: dict[str, Any], path: str) -> bool:
    current: Any = payload
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return False
        current = current[part]
    return current not in (None, "", [], {})
