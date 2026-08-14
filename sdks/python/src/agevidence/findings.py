"""Shared structured findings for local SDK diagnostics."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


Severity = Literal["info", "warning", "error", "blocking"]

_SEVERITY_ORDER: dict[str, int] = {
    "info": 0,
    "warning": 1,
    "error": 2,
    "blocking": 3,
}

_LEGACY_SEVERITIES = {
    "pass": "info",
    "warn": "warning",
    "fail": "error",
}


class Finding(BaseModel):
    """A machine-readable local SDK finding.

    This model is intentionally generic enough for ingest, mapping, adapter,
    profile, lineage, queue, and bundle diagnostics. Older modules may still
    expose their legacy finding classes; use this model for new public result
    objects.
    """

    model_config = ConfigDict(extra="forbid")

    code: str
    severity: Severity = "info"
    path: str | None = None
    message: str
    remediation: dict[str, Any] | None = None
    details: dict[str, Any] = Field(default_factory=dict)
    source: str | None = None
    field: str | None = None

    @model_validator(mode="after")
    def _sync_path_and_field(self) -> "Finding":
        if self.path is None and self.field is not None:
            self.path = self.field
        if self.field is None and self.path is not None:
            self.field = self.path
        return self

    def explain(self) -> str:
        """Return a concise human-readable explanation."""

        location = f" at {self.path}" if self.path else ""
        return f"{self.severity.upper()} {self.code}{location}: {self.message}"


def normalize_severity(value: str) -> Severity:
    """Normalize legacy and current severities into the shared severity set."""

    normalized = _LEGACY_SEVERITIES.get(value, value)
    if normalized not in _SEVERITY_ORDER:
        return "info"
    return normalized  # type: ignore[return-value]


def severity_at_least(value: str, threshold: str) -> bool:
    """Return whether `value` is at least as severe as `threshold`."""

    return _SEVERITY_ORDER[normalize_severity(value)] >= _SEVERITY_ORDER[normalize_severity(threshold)]


def from_provenance_finding(value: Any) -> Finding:
    """Convert a provenance finding into the shared structured model."""

    remediation = getattr(value, "remediation", None)
    return Finding(
        code=str(getattr(value, "code", "finding")),
        severity=normalize_severity(str(getattr(value, "severity", "info"))),
        path=getattr(value, "field", None),
        message=str(getattr(value, "message", "")),
        remediation=remediation if isinstance(remediation, dict) else None,
        source="provenance",
    )


def finding(code: str, message: str, **kwargs: Any) -> Finding:
    """Build a shared structured finding."""

    return Finding(code=code, message=message, **kwargs)
