"""Optional OpenTelemetry hooks for local SDK workflows."""

from __future__ import annotations

from typing import Any


def get_tracer(name: str = "agevidence") -> Any:
    """Return an OpenTelemetry tracer."""

    try:
        from opentelemetry import trace
    except ImportError as exc:
        raise ImportError("Install OpenTelemetry support with `pip install agevidence[otel]`.") from exc
    return trace.get_tracer(name)


def span_attributes(**attributes: Any) -> dict[str, Any]:
    """Return deterministic non-null attributes for SDK spans."""

    return {key: value for key, value in sorted(attributes.items()) if value is not None}
