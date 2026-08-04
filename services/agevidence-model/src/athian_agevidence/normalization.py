"""Normalized output validation helpers."""

from __future__ import annotations

from typing import Any

from .contracts import EvidenceRunResponse
from .source_references import validate_source_references

FORBIDDEN_AUTHORITY_TERMS = {
    "government_eligible",
    "credit_approved",
    "claim_owner",
    "verified_reduction",
    "legally_valid",
}


def normalize_response(payload: dict[str, Any]) -> EvidenceRunResponse:
    """Validate a model adapter response and return a typed contract."""

    validate_authority_neutral(payload)
    response = EvidenceRunResponse.model_validate(payload)
    validate_source_references(response)
    if not response.limitations:
        raise ValueError("model responses must include authority limitations")
    return response


def validate_authority_neutral(value: Any) -> None:
    """Reject model output that tries to claim final policy or institutional authority."""

    if isinstance(value, dict):
        for key, child in value.items():
            if key in FORBIDDEN_AUTHORITY_TERMS:
                raise ValueError(f"model output may not declare authority field {key}")
            validate_authority_neutral(child)
    elif isinstance(value, list):
        for child in value:
            validate_authority_neutral(child)
    elif isinstance(value, str) and value in FORBIDDEN_AUTHORITY_TERMS:
        raise ValueError(f"model output may not declare authority state {value}")
