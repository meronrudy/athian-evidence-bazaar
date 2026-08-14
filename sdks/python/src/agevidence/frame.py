"""Evidence collection abstraction for local analytics."""

from __future__ import annotations

from numbers import Number
from typing import Any, Callable, Literal

from pydantic import BaseModel, ConfigDict, Field


class EvidenceFrame(BaseModel):
    """A small provenance-aware collection object."""

    model_config = ConfigDict(extra="forbid")

    items: list[dict[str, Any]] = Field(default_factory=list)
    result_findings: list[Any] = Field(default_factory=list)

    def filter(self, predicate: Callable[[dict[str, Any]], bool] | None = None, **criteria: Any) -> "EvidenceFrame":
        def matches(item: dict[str, Any]) -> bool:
            if predicate and not predicate(item):
                return False
            return all(item.get(key) == value for key, value in criteria.items())

        return EvidenceFrame(items=[item for item in self.items if matches(item)], result_findings=self.result_findings)

    def group_by_subject(self) -> dict[str, "EvidenceFrame"]:
        groups: dict[str, list[dict[str, Any]]] = {}
        for item in self.items:
            groups.setdefault(str(_subject(item) or "unknown"), []).append(item)
        return {subject: EvidenceFrame(items=items) for subject, items in sorted(groups.items())}

    def subject(self, subject: str) -> "EvidenceFrame":
        return self.filter(lambda item: _subject(item) == subject)

    @property
    def period(self) -> dict[str, str | None]:
        timestamps = sorted(value for item in self.items for value in [_timestamp_text(item)] if value)
        return {"start": timestamps[0] if timestamps else None, "end": timestamps[-1] if timestamps else None}

    @property
    def observations(self) -> list[dict[str, Any]]:
        return [item for item in self.items if item.get("primitive_type") in {"Observation", "SpatialObservation", "DerivedObservation"}]

    @property
    def interventions(self) -> list[dict[str, Any]]:
        return [item for item in self.items if item.get("primitive_type") == "InterventionEvent"]

    @property
    def sources(self) -> list[dict[str, Any]]:
        return [item for item in self.items if item.get("primitive_type") == "SourceRecord"]

    def coverage(self, expected_records: int | None = None) -> dict[str, Any]:
        from agevidence.series import series

        return series(self.items).coverage(expected_records)

    def aggregate(
        self,
        value: str | None = None,
        *,
        by: str | None = None,
        reducer: Literal["count", "sum", "min", "max", "mean"] = "count",
    ) -> dict[str, Any]:
        """Aggregate records by an optional field path."""

        groups: dict[str, list[dict[str, Any]]] = {}
        for item in self.items:
            key = str(_path_value(item, by) if by else "all")
            groups.setdefault(key, []).append(item)
        return {key: _reduce(items, value, reducer) for key, items in sorted(groups.items())}

    def lineage(self):
        from agevidence.provenance import lineage

        graph = lineage()
        for item in self.items:
            graph.add(item)
            for source in item.get("source_records", []) if isinstance(item.get("source_records"), list) else []:
                graph.derive(item, from_=source)
            if item.get("primitive_type") == "DerivedObservation":
                inputs = item.get("inputs")
                if isinstance(inputs, list) and inputs:
                    graph.derive(item, from_=inputs)
                transformation = item.get("transformation")
                if isinstance(transformation, dict) and transformation:
                    graph.derive(item, from_=transformation, relation="generated_by")
        return graph

    def findings(self) -> list[Any]:
        return list(self.result_findings)

    def to_pandas(self):
        import pandas as pd

        return pd.DataFrame(self.items)

    def to_parquet(self, path: str) -> str:
        self.to_pandas().to_parquet(path)
        return path

    def to_primitives(self) -> list[dict[str, Any]]:
        return list(self.items)

    def bundle(self):
        from agevidence.bundle import Bundle

        bundle = Bundle()
        bundle.add(self.items)
        return bundle

    def assess(self, profile: str):
        from agevidence.assessment import assess

        return assess(self, profile)

    def quality(self):
        from agevidence.quality import quality

        return quality(self)


def frame(values: Any) -> EvidenceFrame:
    """Build an EvidenceFrame from results or primitive payloads."""

    items: list[dict[str, Any]] = []
    findings: list[Any] = []
    if hasattr(values, "results"):
        for result in values.results:
            items.append(result.primitive)
            findings.extend(getattr(result, "findings", []))
        return EvidenceFrame(items=items, result_findings=findings)
    if not isinstance(values, list):
        values = [values]
    for value in values:
        if hasattr(value, "primitive"):
            items.append(dict(value.primitive))
            findings.extend(getattr(value, "findings", []))
        elif hasattr(value, "to_payload"):
            items.append(value.to_payload())
        else:
            items.append(dict(value))
    return EvidenceFrame(items=items, result_findings=findings)


def _subject(item: dict[str, Any]) -> Any:
    return item.get("subject") or item.get("target") or item.get("machine") or item.get("asset")


def _timestamp_text(item: dict[str, Any]) -> str | None:
    for key in ["observed_at", "occurred_at", "effective_at", "recorded_at", "received_at", "started_at", "completed_at"]:
        if item.get(key):
            return str(item[key])
    return None


def _path_value(item: dict[str, Any], path: str | None) -> Any:
    if not path:
        return None
    current: Any = item
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def _reduce(items: list[dict[str, Any]], value: str | None, reducer: str) -> Any:
    if reducer == "count":
        if value is None:
            return len(items)
        return sum(1 for item in items if _path_value(item, value) not in (None, "", [], {}))
    values = [_path_value(item, value) for item in items]
    numbers = [item for item in values if isinstance(item, Number) and not isinstance(item, bool)]
    if reducer == "sum":
        return sum(numbers)
    if not numbers:
        return None
    if reducer == "min":
        return min(numbers)
    if reducer == "max":
        return max(numbers)
    if reducer == "mean":
        return sum(numbers) / len(numbers)
    raise ValueError(f"Unsupported aggregate reducer: {reducer}")
