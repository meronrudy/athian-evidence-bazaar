"""Observation primitive."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import Field

from .base import EvidencePrimitive
from .source_record import SourceRecord


class Observation(EvidencePrimitive):
    """Point-in-time measurement or physical assertion about a subject."""

    schema_id: Literal["athian.agevidence.observation.v1"] = "athian.agevidence.observation.v1"
    primitive_type: Literal["Observation"] = "Observation"
    subject: str
    observable: str
    value: Any
    unit: str
    observed_at: str
    instrument: dict[str, Any] | None = None
    method: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)
