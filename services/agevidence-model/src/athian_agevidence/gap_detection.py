"""Evidence-gap checks for normalized fixture output."""

from __future__ import annotations

from .contracts import EvidenceRunResponse


def material_gap_count(response: EvidenceRunResponse) -> int:
    """Count material gaps in a normalized response."""

    return sum(1 for gap in response.gaps if gap.severity == "material")
