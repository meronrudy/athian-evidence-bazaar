"""Operational event primitive."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import Field

from .base import EvidencePrimitive
from .source_record import SourceRecord


class OperationalEvent(EvidencePrimitive):
    """Machine operation, trajectory segment, or equipment state change."""

    schema_id: Literal["athian.agevidence.operational_event.v1"] = "athian.agevidence.operational_event.v1"
    primitive_type: Literal["OperationalEvent"] = "OperationalEvent"
    machine: str
    operation: str
    started_at: str
    completed_at: str
    location: dict[str, Any] | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)
