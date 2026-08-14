"""Shared local evidence primitive helpers."""

from __future__ import annotations

import hashlib
import json
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


def canonical_json(value: Any) -> str:
    """Return the SDK's deterministic JSON rendering for local developer checks."""

    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def local_digest(value: Any) -> str:
    """Return a local SHA-256 digest for deterministic fixtures and tests.

    This is not a receipt commitment. Receipt commitments stay delegated to the
    Rust trust boundary.
    """

    digest = hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()
    return f"sha256:{digest}"


class EvidencePrimitive(BaseModel):
    """Base class for local developer-plane primitives."""

    model_config = ConfigDict(extra="forbid")

    effective_at: str | None = None
    recorded_at: str | None = None
    received_at: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)

    def to_payload(self) -> dict[str, Any]:
        """Return the normalized JSON payload used by local validation."""

        return self.model_dump(mode="json", exclude_none=True)

    def normalized_json(self) -> str:
        """Return deterministic JSON for local fixtures and regression tests."""

        return canonical_json(self.to_payload())

    def local_digest(self) -> str:
        """Return a deterministic local digest of the normalized payload."""

        return local_digest(self.to_payload())
