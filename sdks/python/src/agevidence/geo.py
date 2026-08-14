"""Optional geospatial helpers for local primitive payloads."""

from __future__ import annotations

from typing import Any


def to_shape(geometry: dict[str, Any]) -> Any:
    """Return a Shapely geometry from a GeoJSON geometry object."""

    try:
        from shapely.geometry import shape
    except ImportError as exc:
        raise ImportError("Install geospatial support with `pip install agevidence[geo]`.") from exc
    return shape(geometry)


def geometry_bounds(geometry: dict[str, Any]) -> tuple[float, float, float, float]:
    """Return GeoJSON geometry bounds as `(minx, miny, maxx, maxy)`."""

    return tuple(float(value) for value in to_shape(geometry).bounds)


def validate_geometry(geometry: dict[str, Any]) -> bool:
    """Return whether a GeoJSON geometry can be parsed by Shapely."""

    return bool(to_shape(geometry).is_valid)
