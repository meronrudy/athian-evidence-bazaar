"""Normalized output validation helpers."""

from __future__ import annotations

from typing import Any

from .contracts import EvidenceRunResponse
from .source_references import validate_source_references


def normalize_response(payload: dict[str, Any]) -> EvidenceRunResponse:
    """Validate a model adapter response and return a typed contract."""

    response = EvidenceRunResponse.model_validate(payload)
    validate_source_references(response)
    if not response.limitations:
        raise ValueError("model responses must include authority limitations")
    return response
