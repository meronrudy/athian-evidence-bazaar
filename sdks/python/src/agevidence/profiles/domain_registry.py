"""Registry for reusable domain evidence profiles."""

from __future__ import annotations

import inspect
from importlib import metadata
from typing import Any

from .domain import (
    BioactiveProductLot,
    DomainProfile,
    EntericMethaneMeasurement,
    FeedAdditiveDelivery,
    ObjectiveCarcassMeasurement,
    PrecisionChemicalApplication,
    SpatialBiomassObservation,
    SpatialDigitalTwinManifest,
    WaterDosingIntervention,
)


def default_domain_registry(*, load_entry_points: bool = True) -> "DomainProfileRegistry":
    """Return the built-in reusable domain profile registry."""

    registry = DomainProfileRegistry()
    for profile in [
        WaterDosingIntervention(),
        FeedAdditiveDelivery(),
        BioactiveProductLot(),
        PrecisionChemicalApplication(),
        ObjectiveCarcassMeasurement(),
        EntericMethaneMeasurement(),
        SpatialBiomassObservation(),
        SpatialDigitalTwinManifest(),
    ]:
        registry.register(profile)
    if load_entry_points:
        registry.load_entry_points()
    return registry


class DomainProfileRegistry:
    """In-memory registry for reusable domain profiles."""

    def __init__(self) -> None:
        self._profiles: dict[str, DomainProfile] = {}
        self._aliases: dict[str, list[str]] = {}

    def register(self, profile: DomainProfile) -> None:
        profile_id = profile.metadata.profile_id
        if profile_id in self._profiles:
            raise ValueError(f"Duplicate domain profile id: {profile_id}")
        self._profiles[profile_id] = profile
        for alias in profile.metadata.aliases:
            self._aliases.setdefault(alias, []).append(profile_id)

    def all(self) -> list[DomainProfile]:
        return sorted(self._profiles.values(), key=lambda profile: profile.metadata.profile_id)

    def load_entry_points(self, group: str = "agevidence.profiles") -> list[DomainProfile]:
        """Load installed domain profiles from Python entry points."""

        loaded: list[DomainProfile] = []
        for entry_point in metadata.entry_points().select(group=group):
            profile = _instantiate_domain_profile(entry_point.load())
            self.register(profile)
            loaded.append(profile)
        return loaded

    def resolve(self, value: str) -> DomainProfile:
        if value in self._profiles:
            return self._profiles[value]
        matches = self._aliases.get(value, [])
        if len(matches) == 1:
            return self._profiles[matches[0]]
        if len(matches) > 1:
            raise ValueError(f"Ambiguous domain profile alias: {value}")
        raise KeyError(f"Unknown domain profile: {value}")


def list_domain_profiles(*, load_entry_points: bool = True) -> list[DomainProfile]:
    """Return all built-in domain profiles."""

    return default_domain_registry(load_entry_points=load_entry_points).all()


def get_domain_profile(value: str) -> DomainProfile:
    """Resolve a domain profile by id or unambiguous alias."""

    return default_domain_registry().resolve(value)


def _instantiate_domain_profile(target: Any) -> DomainProfile:
    profile = target() if inspect.isclass(target) else target() if callable(target) and not isinstance(target, DomainProfile) else target
    if not isinstance(profile, DomainProfile):
        raise TypeError("Profile entry point must return an agevidence.profiles.DomainProfile.")
    return profile
