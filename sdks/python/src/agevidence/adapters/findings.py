"""Standard country adapter findings."""

from __future__ import annotations

from typing import Literal

from agevidence.findings import Finding


FindingCode = Literal[
    "normalized",
    "valid_format",
    "invalid_format",
    "source_found",
    "source_not_found",
    "external_check_unavailable",
    "review_required",
    "conflict",
    "superseded",
]


def finding(code: FindingCode, message: str, **kwargs: object) -> Finding:
    """Build a standard finding."""

    return Finding(code=code, message=message, **kwargs)
