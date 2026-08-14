"""Optional visualization helpers for local evidence collections."""

from __future__ import annotations

from typing import Any


def timeline_points(value: Any) -> list[tuple[str, str]]:
    """Return `(timestamp, primitive_type)` points from frame-like values."""

    items = value.to_primitives() if hasattr(value, "to_primitives") else value
    if not isinstance(items, list):
        items = [items]
    points = []
    for item in items:
        payload = item.to_payload() if hasattr(item, "to_payload") else dict(item)
        timestamp = _timestamp(payload)
        if timestamp:
            points.append((timestamp, str(payload.get("primitive_type") or "Unknown")))
    return sorted(points)


def plot_timeline(value: Any, *, ax: Any | None = None) -> Any:
    """Plot primitive timestamps with Matplotlib and return the axes."""

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise ImportError("Install visualization support with `pip install agevidence[viz]`.") from exc
    axis = ax or plt.subplots()[1]
    points = timeline_points(value)
    axis.scatter([point[0] for point in points], [point[1] for point in points])
    axis.set_xlabel("timestamp")
    axis.set_ylabel("primitive_type")
    return axis


def _timestamp(payload: dict[str, Any]) -> str | None:
    for key in ["observed_at", "occurred_at", "effective_at", "recorded_at", "received_at", "started_at", "completed_at"]:
        if payload.get(key):
            return str(payload[key])
    return None
