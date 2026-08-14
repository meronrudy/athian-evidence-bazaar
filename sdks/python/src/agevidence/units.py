"""Deterministic local unit helpers."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict


UNIT_ALIASES = {
    "kilogram": "kg",
    "kilograms": "kg",
    "gram": "g",
    "grams": "g",
    "liter": "L",
    "litre": "L",
    "liters": "L",
    "litres": "L",
    "milliliter": "mL",
    "millilitre": "mL",
    "milliliters": "mL",
    "millilitres": "mL",
    "pound": "lb",
    "pounds": "lb",
}

UNIT_GROUPS = {
    "mass": {"kg", "g", "lb"},
    "volume": {"L", "mL"},
    "concentration": {"ppm", "g_ch4_min"},
    "rate": {"kg/head/day", "kg_ch4/head/day", "kg_dm_ha"},
}

CONVERSIONS = {
    ("kg", "g"): 1000.0,
    ("g", "kg"): 0.001,
    ("kg", "lb"): 2.2046226218,
    ("lb", "kg"): 0.45359237,
    ("L", "mL"): 1000.0,
    ("mL", "L"): 0.001,
}


class Quantity(BaseModel):
    """A value with original and normalized unit metadata."""

    model_config = ConfigDict(extra="forbid")

    original_value: float
    original_unit: str
    normalized_value: float
    normalized_unit: str

    def __init__(self, value: float | None = None, unit: str | None = None, **kwargs: Any) -> None:
        if value is not None and unit is not None:
            normalized = normalize_unit(unit)
            kwargs.setdefault("original_value", value)
            kwargs.setdefault("original_unit", unit)
            kwargs.setdefault("normalized_value", float(value))
            kwargs.setdefault("normalized_unit", normalized)
        super().__init__(**kwargs)

    def to(self, unit: str) -> "Quantity":
        """Convert to a compatible unit while preserving original evidence."""

        target = normalize_unit(unit)
        source = self.normalized_unit
        if source == target:
            converted = self.normalized_value
        else:
            try:
                converted = self.normalized_value * CONVERSIONS[(source, target)]
            except KeyError as exc:
                raise ValueError(f"Cannot convert {source} to {target}.") from exc
        result = Quantity(self.original_value, self.original_unit)
        result.normalized_value = converted
        result.normalized_unit = target
        return result


def normalize_unit(unit: str) -> str:
    """Normalize common unit aliases."""

    value = unit.strip()
    return UNIT_ALIASES.get(value.lower(), value)


def validate_unit(unit: str) -> bool:
    """Return whether a unit is recognized by the local registry."""

    normalized = normalize_unit(unit)
    return any(normalized in units for units in UNIT_GROUPS.values())


def compatible_units(unit: str) -> list[str]:
    """Return units compatible with the supplied unit."""

    normalized = normalize_unit(unit)
    for units in UNIT_GROUPS.values():
        if normalized in units:
            return sorted(units)
    return [normalized]
