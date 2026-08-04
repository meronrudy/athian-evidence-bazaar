"""Pydantic contracts for AgEvidence model runs."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class ProjectRef(BaseModel):
    """Project context supplied by Rails."""

    id: str
    claim: str


class ProtocolRef(BaseModel):
    """Protocol context supplied by Rails."""

    code: str
    version: str


class DocumentRef(BaseModel):
    """Source document commitment supplied by Rails."""

    document_id: str
    commitment: str
    controlled_uri: str


class GenerationConfig(BaseModel):
    """Model generation configuration."""

    temperature: float = 0
    seed: int | None = None


class EvidenceRunRequest(BaseModel):
    """Request body for POST /v1/evidence-runs."""

    adapter_id: str
    task: str
    project: ProjectRef
    protocol: ProtocolRef
    documents: list[DocumentRef] = Field(default_factory=list)
    generation: GenerationConfig = Field(default_factory=GenerationConfig)


class SourceReference(BaseModel):
    """A source-linked locator for a candidate claim."""

    document_id: str
    locator: str


class Candidate(BaseModel):
    """Candidate evidence extracted by the model adapter."""

    candidate_id: str
    candidate_type: str
    claim_text: str
    source_references: list[SourceReference]
    confidence: float = Field(ge=0, le=1)
    status: Literal["review_required"] = "review_required"


class Gap(BaseModel):
    """Evidence gap identified by the model adapter."""

    gap_type: str
    requirement: str
    severity: str
    description: str
    source_context: dict[str, Any] | None = None


class ModelRunMetadata(BaseModel):
    """Normalized model-run metadata."""

    adapter_id: str
    base_model_id: str
    weights_digest: str
    adapter_digest: str
    prompt_digest: str
    retrieval_digest: str
    normalized_output_digest: str
    runtime: str
    started_at: datetime | str
    completed_at: datetime | str


class EvidenceRunResponse(BaseModel):
    """Normalized response body returned by model adapters."""

    model_config = ConfigDict(extra="allow")

    model_run: ModelRunMetadata
    candidates: list[Candidate]
    gaps: list[Gap]
    limitations: list[str]
