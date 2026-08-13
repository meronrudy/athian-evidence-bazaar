"""Lightweight provenance lineage graph models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


LineageRelation = Literal[
    "derived_from",
    "generated_by",
    "observed_by",
    "applied_by",
    "references",
    "supersedes",
    "interprets",
    "allocates",
    "relies_on",
]


class EvidenceReference(BaseModel):
    """Portable reference to a committed evidence object."""

    model_config = ConfigDict(extra="forbid")

    commitment: str
    schema_id: str | None = None
    primitive_type: str | None = None
    uri: str | None = None


class LineageEdge(BaseModel):
    """Directed provenance relation between evidence objects."""

    model_config = ConfigDict(extra="forbid")

    relation: LineageRelation
    subject: EvidenceReference
    object: EvidenceReference
    metadata: dict[str, object] = Field(default_factory=dict)
