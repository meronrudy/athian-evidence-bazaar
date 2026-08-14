"""Local evidence replay helpers."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from agevidence.diff import SemanticDiff, diff
from agevidence.ingest import ingest


class ReplayResult(BaseModel):
    """Result of replaying native evidence through current mappings."""

    model_config = ConfigDict(extra="forbid")

    source_evidence: str = "unchanged"
    results: list[dict[str, Any]] = Field(default_factory=list)
    differences: list[SemanticDiff] = Field(default_factory=list)


def replay(value: Any, *, primitive: str = "auto") -> ReplayResult:
    """Replay ingest results or primitive payloads from preserved native records."""

    originals = _results(value)
    new_results = []
    differences = []
    for original in originals:
        native = original.get("native") or original.get("metadata", {}).get("native")
        if not isinstance(native, dict):
            continue
        replayed = ingest(native, primitive=primitive if primitive != "auto" else original.get("primitive_type", "auto"))
        new_results.append(replayed.primitive)
        differences.append(diff(original, replayed.primitive))
    return ReplayResult(results=new_results, differences=differences)


def _results(value: Any) -> list[dict[str, Any]]:
    if hasattr(value, "results"):
        return [{"native": result.native, **result.primitive} for result in value.results]
    if hasattr(value, "to_primitives"):
        return list(value.to_primitives())
    if hasattr(value, "primitive"):
        return [{"native": getattr(value, "native", None), **value.primitive}]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, list):
        return [item.primitive if hasattr(item, "primitive") else dict(item) for item in value]
    return []
