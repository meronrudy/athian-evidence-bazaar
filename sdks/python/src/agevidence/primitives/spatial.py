"""Spatial observation primitive."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import Field

from .base import EvidencePrimitive
from .source_record import SourceRecord


class SpatialObservation(EvidencePrimitive):
    """Observation whose subject is a geometry or spatial boundary."""

    schema_id: Literal["athian.agevidence.spatial_observation.v1"] = "athian.agevidence.spatial_observation.v1"
    primitive_type: Literal["SpatialObservation"] = "SpatialObservation"
    geometry: dict[str, Any]
    observable: str
    value: Any
    unit: str
    observed_at: str
    crs: str = "EPSG:4326"
    subject: str | None = None
    source_records: list[SourceRecord] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)
