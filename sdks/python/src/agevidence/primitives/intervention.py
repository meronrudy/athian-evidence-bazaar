"""Intervention event primitive."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import Field

from .base import EvidencePrimitive
from .source_record import SourceRecord


class InterventionEvent(EvidencePrimitive):
    """Physical action applied to a target subject or asset."""

    schema_id: Literal["athian.agevidence.intervention_event.v1"] = "athian.agevidence.intervention_event.v1"
    primitive_type: Literal["InterventionEvent"] = "InterventionEvent"
    target: str
    intervention: str
    quantity: Any
    unit: str
    occurred_at: str
    batch: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)
