"""Human-readable explanations for local evidence readiness."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from .ingest import ingest
from .provenance import ProvenanceReport, check


class ExplainReport(BaseModel):
    """Developer explanation derived from deterministic validation findings."""

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    summary: str
    provenance: ProvenanceReport
    missing: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    remediation: list[dict[str, object]] = Field(default_factory=list)
    does_not_establish: list[str] = Field(
        default_factory=lambda: [
            "measurement accuracy",
            "methodology eligibility",
            "carbon-credit eligibility",
            "external verification",
            "institutional reliance",
        ]
    )


def explain(value: dict[str, Any] | str | Path) -> ExplainReport:
    """Explain how a payload maps to a primitive and what provenance is missing."""

    if isinstance(value, dict) and value.get("primitive_type"):
        report = check(value)
        primitive_type = report.primitive_type
    else:
        ingested = ingest(value)
        report = ingested.provenance
        primitive_type = ingested.primitive_type
    missing = [finding.code for finding in report.findings if finding.severity == "fail"]
    warnings = [finding.code for finding in report.findings if finding.severity == "warn"]
    remediation = [finding.remediation for finding in report.findings if finding.remediation]
    return ExplainReport(
        primitive_type=primitive_type,
        summary=_summary(primitive_type, report),
        provenance=report,
        missing=missing,
        warnings=warnings,
        remediation=remediation,
    )


def _summary(primitive_type: str, report: ProvenanceReport) -> str:
    if report.complete:
        return f"This record can be represented as {primitive_type} with complete local provenance."
    return f"This record can be represented as {primitive_type}, but local provenance is {report.provenance_completeness}."
