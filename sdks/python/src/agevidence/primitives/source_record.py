"""Source record primitive."""

from __future__ import annotations

from typing import Literal

from pydantic import Field

from .base import EvidencePrimitive


class SourceRecord(EvidencePrimitive):
    """Original record being relied upon before transformation."""

    schema_id: Literal["athian.agevidence.source_record.v1"] = "athian.agevidence.source_record.v1"
    primitive_type: Literal["SourceRecord"] = "SourceRecord"
    source_system: str
    record_id: str
    observed_at: str
    controlled_uri: str | None = None
    commitment: str | None = None
    metadata: dict[str, object] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)

    def to_reference(self) -> dict[str, str]:
        """Return a compact source reference for embedding in another primitive."""

        reference = {
            "source_system": self.source_system,
            "record_id": self.record_id,
            "observed_at": self.observed_at,
        }
        if self.controlled_uri:
            reference["controlled_uri"] = self.controlled_uri
        if self.commitment:
            reference["commitment"] = self.commitment
        return reference
