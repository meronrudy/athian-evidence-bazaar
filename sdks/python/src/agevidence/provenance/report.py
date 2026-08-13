"""Provenance report models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from .findings import Finding


class ProvenanceReport(BaseModel):
    """Local evidence-readiness report.

    This report intentionally separates local data quality from program,
    verification, and institutional states.
    """

    model_config = ConfigDict(extra="forbid")

    primitive_type: str
    structural_validity: Literal["pass", "fail", "indeterminate"]
    provenance_completeness: Literal["complete", "partial", "incomplete", "indeterminate"]
    program_eligibility: Literal["not_evaluated"] = "not_evaluated"
    verification_status: Literal["not_issued"] = "not_issued"
    institutional_reliance: Literal["not_asserted"] = "not_asserted"
    score: int
    findings: list[Finding] = Field(default_factory=list)
    authority_boundary: str = (
        "Local provenance checks do not establish program eligibility, external verification, "
        "carbon-credit eligibility, measurement accuracy, or institutional reliance."
    )

    @property
    def complete(self) -> bool:
        return self.structural_validity == "pass" and self.provenance_completeness == "complete"
