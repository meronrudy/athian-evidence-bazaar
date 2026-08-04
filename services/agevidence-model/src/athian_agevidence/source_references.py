"""Source-reference preservation checks."""

from __future__ import annotations

from .contracts import EvidenceRunResponse


def validate_source_references(response: EvidenceRunResponse) -> None:
    """Ensure every candidate keeps at least one source reference."""

    for candidate in response.candidates:
        if not candidate.source_references:
            raise ValueError(f"{candidate.candidate_id} has no source references")
