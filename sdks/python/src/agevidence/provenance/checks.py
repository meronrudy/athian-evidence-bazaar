"""Local provenance completion checks."""

from __future__ import annotations

from typing import Any

from agevidence.primitives import EvidencePrimitive

from .findings import Finding
from .report import ProvenanceReport


REQUIRED_FIELDS: dict[str, list[str]] = {
    "SourceRecord": ["source_system", "record_id", "observed_at"],
    "Observation": ["subject", "observable", "value", "unit", "observed_at"],
    "SpatialObservation": ["geometry", "observable", "value", "unit", "observed_at", "crs"],
    "InterventionEvent": ["target", "intervention", "quantity", "unit", "occurred_at"],
    "OperationalEvent": ["machine", "operation", "started_at", "completed_at"],
    "ModelRun": ["model_id", "model_version", "implementation_digest", "input_commitments", "parameters", "execution_environment", "started_at", "completed_at", "outputs", "verification"],
    "ModelExecution": ["base_model_id", "model_version", "inputs", "outputs"],
}


def check(value: EvidencePrimitive | dict[str, Any]) -> ProvenanceReport:
    """Check structural validity and provenance completeness locally."""

    payload = value.to_payload() if isinstance(value, EvidencePrimitive) else value
    primitive_type = _primitive_type(value, payload)
    findings: list[Finding] = []
    findings.extend(_required_field_findings(payload, primitive_type))
    findings.extend(_provenance_findings(payload, primitive_type))
    structural_validity = "fail" if any(item.severity == "fail" and item.code.startswith("MISSING_") for item in findings) else "pass"
    provenance_completeness = _provenance_status(findings)
    return ProvenanceReport(
        primitive_type=primitive_type,
        structural_validity=structural_validity,
        provenance_completeness=provenance_completeness,
        score=_score(findings),
        findings=findings,
    )


def _primitive_type(value: EvidencePrimitive | dict[str, Any], payload: dict[str, Any]) -> str:
    if isinstance(value, EvidencePrimitive):
        return getattr(value, "primitive_type", value.__class__.__name__)
    if isinstance(payload.get("primitive_type"), str):
        return str(payload["primitive_type"])
    if payload.get("schema_id") == "athian.agevidence.model_run.v1" or payload.get("primitive_type") == "ModelRun" or "model_id" in payload:
        return "ModelRun"
    if "base_model_id" in payload:
        return "ModelExecution"
    if "geometry" in payload:
        return "SpatialObservation"
    if "machine" in payload and "operation" in payload:
        return "OperationalEvent"
    if "intervention" in payload or "occurred_at" in payload:
        return "InterventionEvent"
    if "observable" in payload or "observed_at" in payload:
        return "Observation"
    if "source_system" in payload and "record_id" in payload:
        return "SourceRecord"
    return "Unknown"


def _required_field_findings(payload: dict[str, Any], primitive_type: str) -> list[Finding]:
    findings: list[Finding] = []
    for field in REQUIRED_FIELDS.get(primitive_type, []):
        if _present(payload.get(field)):
            findings.append(Finding(code=f"{field.upper()}_PRESENT", severity="pass", field=field, message=f"{field} is present."))
        else:
            findings.append(
                Finding(
                    code=f"MISSING_{field.upper()}",
                    severity="fail",
                    field=field,
                    message=f"{field} is required for {primitive_type}.",
                    remediation={field: "<add value>"},
                )
            )
    if primitive_type == "Unknown":
        findings.append(Finding(code="UNKNOWN_PRIMITIVE", severity="fail", message="The payload does not match a known primitive shape."))
    return findings


def _provenance_findings(payload: dict[str, Any], primitive_type: str) -> list[Finding]:
    findings: list[Finding] = []
    if primitive_type in {"Observation", "SpatialObservation", "InterventionEvent", "OperationalEvent"}:
        if payload.get("source_records"):
            findings.append(Finding(code="SOURCE_RECORD_PRESENT", severity="pass", field="source_records", message="At least one source record is linked."))
        else:
            findings.append(
                Finding(
                    code="SOURCE_RECORD_MISSING",
                    severity="warn",
                    field="source_records",
                    message="No source record is linked to this primitive.",
                    remediation={"source_records": [{"source_system": "...", "record_id": "...", "observed_at": "..."}]},
                )
            )
    if primitive_type in {"Observation", "SpatialObservation"}:
        instrument = payload.get("instrument")
        if isinstance(instrument, dict) and instrument.get("id"):
            findings.append(Finding(code="INSTRUMENT_ID_PRESENT", severity="pass", field="instrument.id", message="Instrument identity is present."))
            if instrument.get("calibration_reference"):
                findings.append(
                    Finding(
                        code="CALIBRATION_REFERENCE_PRESENT",
                        severity="pass",
                        field="instrument.calibration_reference",
                        message="Instrument calibration reference is present.",
                    )
                )
            else:
                findings.append(
                    Finding(
                        code="CALIBRATION_REFERENCE_MISSING",
                        severity="fail",
                        field="instrument.calibration_reference",
                        message="Instrument identity is present but no calibration reference covers the observation.",
                        remediation={"instrument": {"calibration_reference": "<controlled URI or digest>"}},
                    )
                )
        else:
            findings.append(
                Finding(
                    code="INSTRUMENT_ID_MISSING",
                    severity="warn",
                    field="instrument.id",
                    message="No instrument identity is attached.",
                    remediation={"instrument": {"id": "<instrument identifier>"}},
                )
            )
    if primitive_type == "InterventionEvent" and not payload.get("batch"):
        findings.append(
            Finding(
                code="BATCH_REFERENCE_MISSING",
                severity="warn",
                field="batch",
                message="No product or material batch reference is attached.",
                remediation={"batch": "<batch or lot identifier>"},
            )
        )
    if primitive_type == "ModelRun":
        for field in ["implementation_digest", "input_commitments", "execution_environment", "verification"]:
            if _present(payload.get(field)):
                findings.append(Finding(code=f"{field.upper()}_PRESENT", severity="pass", field=field, message=f"{field} is present."))
            else:
                findings.append(
                    Finding(
                        code=f"{field.upper()}_MISSING",
                        severity="fail",
                        field=field,
                        message=f"{field} is required for model provenance completeness.",
                        remediation={field: "<add value>"},
                    )
                )
    if primitive_type == "ModelExecution":
        for field in ["weights_digest", "adapter_id", "adapter_digest", "source_document_commitments", "normalized_output_digest"]:
            if _present(payload.get(field)):
                findings.append(Finding(code=f"{field.upper()}_PRESENT", severity="pass", field=field, message=f"{field} is present."))
            else:
                findings.append(
                    Finding(
                        code=f"{field.upper()}_MISSING",
                        severity="fail",
                        field=field,
                        message=f"{field} is required for model provenance completeness.",
                        remediation={field: "<add value>"},
                    )
                )
    return findings


def _present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value)
    if isinstance(value, (list, dict)):
        return bool(value)
    return True


def _provenance_status(findings: list[Finding]) -> str:
    relevant = [item for item in findings if item.severity in {"warn", "fail"}]
    if any(item.severity == "fail" for item in relevant):
        return "incomplete"
    if relevant:
        return "partial"
    return "complete"


def _score(findings: list[Finding]) -> int:
    scored = [item for item in findings if item.severity in {"pass", "warn", "fail"}]
    if not scored:
        return 0
    points = sum(1 for item in scored if item.severity == "pass")
    points += sum(0.5 for item in scored if item.severity == "warn")
    return int(round((points / len(scored)) * 100))
