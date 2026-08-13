"""Provenance finding models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict


Severity = Literal["pass", "warn", "fail", "info"]


class Finding(BaseModel):
    """A structural or provenance observation from local validation."""

    model_config = ConfigDict(extra="forbid")

    code: str
    severity: Severity
    message: str
    field: str | None = None
    remediation: dict[str, object] | None = None
