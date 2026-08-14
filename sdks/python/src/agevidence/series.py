"""Deterministic sequence and continuity analysis."""

from __future__ import annotations

from datetime import datetime, timezone
from statistics import median
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class EvidenceSeries(BaseModel):
    """Ordered local evidence sequence helpers."""

    model_config = ConfigDict(extra="forbid")

    items: list[dict[str, Any]] = Field(default_factory=list)

    def gaps(self, expected_interval_seconds: int | float | None = None) -> list[dict[str, Any]]:
        timestamps = sorted(_timestamp(item) for item in self.items if _timestamp(item))
        if len(timestamps) < 2:
            return []
        expected = expected_interval_seconds or _infer_interval(timestamps)
        return [
            {
                "start": previous.isoformat().replace("+00:00", "Z"),
                "end": current.isoformat().replace("+00:00", "Z"),
                "seconds": int((current - previous).total_seconds()),
            }
            for previous, current in zip(timestamps, timestamps[1:])
            if (current - previous).total_seconds() > expected * 1.5
        ]

    def duplicates(self) -> list[dict[str, Any]]:
        seen: dict[tuple[Any, Any, Any], int] = {}
        duplicates: list[dict[str, Any]] = []
        for item in self.items:
            key = (_subject(item), _timestamp_text(item), item.get("primitive_type"))
            seen[key] = seen.get(key, 0) + 1
            if seen[key] == 2:
                duplicates.append({"subject": key[0], "timestamp": key[1], "primitive_type": key[2]})
        return duplicates

    def out_of_order(self) -> list[dict[str, Any]]:
        values = [_timestamp(item) for item in self.items]
        issues = []
        previous = None
        for index, timestamp in enumerate(values):
            if timestamp and previous and timestamp < previous:
                issues.append({"index": index, "timestamp": timestamp.isoformat().replace("+00:00", "Z")})
            if timestamp:
                previous = timestamp
        return issues

    def coverage(self, expected_records: int | None = None) -> dict[str, Any]:
        observed = len(self.items)
        expected = expected_records or observed
        return {"expected": expected, "observed": observed, "coverage": 1.0 if expected == 0 else round(observed / expected, 4)}

    def clock_drift(self) -> list[dict[str, Any]]:
        drifts = []
        for index, item in enumerate(self.items):
            occurred = _parse_time(item.get("occurred_at") or item.get("observed_at"))
            received = _parse_time(item.get("received_at") or item.get("recorded_at"))
            if occurred and received:
                drifts.append({"index": index, "seconds": int((received - occurred).total_seconds())})
        return drifts

    def find_duplicates(self) -> list[dict[str, Any]]:
        return self.duplicates()

    def find_impossible_values(self) -> list[dict[str, Any]]:
        issues = []
        for index, item in enumerate(self.items):
            value = item.get("value", item.get("quantity"))
            if isinstance(value, (int, float)) and value < 0:
                issues.append({"index": index, "field": "value" if "value" in item else "quantity", "value": value})
        return issues

    def find_timestamp_regressions(self) -> list[dict[str, Any]]:
        return self.out_of_order()

    def find_unit_changes(self) -> list[dict[str, Any]]:
        units: dict[tuple[Any, Any], set[str]] = {}
        for item in self.items:
            key = (_subject(item), item.get("observable") or item.get("intervention"))
            unit = item.get("unit")
            if unit:
                units.setdefault(key, set()).add(str(unit))
        return [{"subject": key[0], "metric": key[1], "units": sorted(value)} for key, value in units.items() if len(value) > 1]

    def find_schema_changes(self) -> list[dict[str, Any]]:
        keysets = {tuple(sorted(item)): item.get("primitive_type") for item in self.items}
        return [{"keys": list(keys), "primitive_type": primitive_type} for keys, primitive_type in keysets.items()] if len(keysets) > 1 else []

    def find_sequence_gaps(self) -> list[dict[str, Any]]:
        sequences = sorted(
            int(value)
            for item in self.items
            for value in [item.get("local_sequence") or item.get("sequence")]
            if isinstance(value, int) or (isinstance(value, str) and value.isdigit())
        )
        return [{"after": previous, "before": current} for previous, current in zip(sequences, sequences[1:]) if current != previous + 1]


def series(results: Any) -> EvidenceSeries:
    """Build an evidence series from ingest results, frames, bundles, or payloads."""

    return EvidenceSeries(items=_payloads(results))


def _payloads(value: Any) -> list[dict[str, Any]]:
    from agevidence.primitives import EvidencePrimitive

    if hasattr(value, "to_primitives"):
        return list(value.to_primitives())
    if hasattr(value, "results"):
        return [result.primitive for result in value.results]
    if hasattr(value, "primitive"):
        return [dict(value.primitive)]
    if isinstance(value, EvidencePrimitive):
        return [value.to_payload()]
    if isinstance(value, dict):
        return [value]
    if isinstance(value, list):
        return [item.to_payload() if isinstance(item, EvidencePrimitive) else item.primitive if hasattr(item, "primitive") else dict(item) for item in value]
    return []


def _timestamp(item: dict[str, Any]) -> datetime | None:
    return _parse_time(_timestamp_text(item))


def _timestamp_text(item: dict[str, Any]) -> str | None:
    for key in ["observed_at", "occurred_at", "effective_at", "recorded_at", "received_at", "started_at", "completed_at"]:
        if item.get(key):
            return str(item[key])
    return None


def _parse_time(value: Any) -> datetime | None:
    if not value:
        return None
    text = str(value).replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _infer_interval(timestamps: list[datetime]) -> float:
    deltas = [(current - previous).total_seconds() for previous, current in zip(timestamps, timestamps[1:])]
    return median(deltas) if deltas else 0.0


def _subject(item: dict[str, Any]) -> Any:
    return item.get("subject") or item.get("target") or item.get("machine") or item.get("asset")
